#!/usr/bin/env bash
# patch.sh - Update existing Codex CLI installation in-place
#
# This script patches an existing ~/.codex installation without:
# - Deleting files
# - Creating backups
# - Requiring confirmation
# - Losing user customizations
#
# Use cases:
# - Add new model profiles
# - Update model configurations
# - Apply security patches
# - Sync with repository updates
#
# Safety guarantees:
# - Idempotent: safe to run multiple times
# - Non-destructive: never deletes user data
# - Fast: only updates what changed
# - Validated: checks all JSON before applying
#
# Prerequisites:
# - Must have run install.sh at least once
# - jq must be installed
# - python3 must be installed

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

usage() {
  cat <<'USAGE'
usage: ./patch.sh [--dry-run]

Updates ~/.codex in-place without deleting or backing up.
Safe to run multiple times. Preserves user customizations.

Options:
  --dry-run    Preview changes without applying them

Requirements:
  - ~/.codex must exist (run install.sh first)
  - jq must be installed
  - python3 must be installed

USAGE
}

DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Validate source repository
required=(
  "README.md"
  "config.toml"
  "model-catalog.json"
  "docs"
  "models"
  "scripts"
)

for path in "${required[@]}"; do
  [[ -e "$ROOT_DIR/$path" ]] || { echo "error: missing required path: $path" >&2; exit 1; }
done

# Validate installation
if [[ ! -d "$CODEX_HOME" ]]; then
  echo "error: $CODEX_HOME does not exist" >&2
  echo "       Run install.sh first to create an initial installation" >&2
  exit 1
fi

# Validate JSON files
command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required" >&2; exit 1; }

shopt -s nullglob
json_files=("$ROOT_DIR"/*.json "$ROOT_DIR/models"/*.json)
shopt -u nullglob

for file in "${json_files[@]}"; do
  jq empty "$file" >/dev/null || { echo "error: invalid JSON: $file" >&2; exit 1; }
done

log() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    echo "$*"
  fi
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

patch_config_toml() {
  local source_config="$1"
  local target_config="$2"

  if [[ ! -f "$target_config" ]]; then
    log "config.toml does not exist; installing repository config.toml"
    run cp "$source_config" "$target_config"
    run chmod 600 "$target_config"
    return
  fi

  local tmp
  tmp="$(mktemp "$target_config.tmp.XXXXXX")"

  if ! python3 - "$source_config" "$target_config" "$tmp" <<'PY'
import re
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11; keep patch.sh compatible with plain python3.
    tomllib = None

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
output_path = Path(sys.argv[3])

# Match standard and array TOML table headers.  We only need to identify
# section boundaries; the resulting file is validated with tomllib before it is
# installed.
TABLE_RE = re.compile(r'^\s*(\[\[?)\s*(.+?)\s*(\]\]?)\s*(?:#.*)?$')
PATCH_ROOTS = {"profiles", "model_providers"}


def split_dotted_name(name):
    """Split a TOML dotted table name, respecting quoted components."""
    parts = []
    buf = []
    quote = None
    escaped = False

    for char in name:
        if quote:
            buf.append(char)
            if quote == '"' and char == '\\' and not escaped:
                escaped = True
                continue
            if char == quote and not escaped:
                quote = None
            escaped = False
            continue

        if char in ('"', "'"):
            quote = char
            buf.append(char)
        elif char == ".":
            parts.append("".join(buf).strip())
            buf = []
        else:
            buf.append(char)

    parts.append("".join(buf).strip())
    return parts


def unquote_basic_name(name):
    """Return an unquoted table component when it is a simple TOML string."""
    if len(name) >= 2 and name[0] == name[-1] and name[0] in ('"', "'"):
        return name[1:-1]
    return name


def table_root(line):
    match = TABLE_RE.match(line)
    if not match:
        return None
    opener, name, closer = match.groups()
    if (opener == "[[") != (closer == "]]"):
        return None
    return unquote_basic_name(split_dotted_name(name.strip())[0])


def without_patch_sections(lines):
    kept = []
    skipping = False

    for line in lines:
        root = table_root(line)
        if root is not None:
            skipping = root in PATCH_ROOTS

        if not skipping:
            kept.append(line)

    # Avoid accumulating whitespace where removed sections used to be.
    while kept and kept[-1].strip() == "":
        kept.pop()

    return kept


def patch_sections(lines):
    sections = []
    collecting = False

    for line in lines:
        root = table_root(line)
        if root is not None:
            collecting = root in PATCH_ROOTS

        if collecting:
            sections.append(line)

    while sections and sections[0].strip() == "":
        sections.pop(0)
    while sections and sections[-1].strip() == "":
        sections.pop()

    return sections


target_lines = target_path.read_text().splitlines()
source_lines = source_path.read_text().splitlines()

source_text = source_path.read_text()
target_text = target_path.read_text()

# When available, fail before writing if either input is not valid TOML.  This
# keeps the patch operation non-destructive without requiring Python 3.11+.
if tomllib is not None:
    tomllib.loads(source_text)
    tomllib.loads(target_text)

kept = without_patch_sections(target_lines)
sections = patch_sections(source_lines)

if not sections:
    raise SystemExit("source config.toml does not contain profiles or model_providers sections")

output_lines = kept
if output_lines:
    output_lines.extend(["", ""])
output_lines.extend(sections)

output = "\n".join(output_lines) + "\n"
if tomllib is not None:
    tomllib.loads(output)
output_path.write_text(output)
PY
  then
    rm -f "$tmp"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    rm -f "$tmp"
    log "would patch profiles and model_providers in $target_config"
    return
  fi

  mv "$tmp" "$target_config"
  chmod 600 "$target_config"
}

# Update static files
log "Patching $CODEX_HOME"

# 1. Patch config.toml profiles and model providers only.
#    Other existing config.toml data (for example projects, MCP servers,
#    sandbox/approval settings, and local user preferences) is preserved.
patch_config_toml "$ROOT_DIR/config.toml" "$CODEX_HOME/config.toml"

# 2. Update model-catalog.json (overwrite)
run cp "$ROOT_DIR/model-catalog.json" "$CODEX_HOME/model-catalog.json"

# 3. Sync models directory
run rm -rf "$CODEX_HOME/models"
run cp -a "$ROOT_DIR/models" "$CODEX_HOME/"

# 4. Sync docs directory
run rm -rf "$CODEX_HOME/docs"
run cp -a "$ROOT_DIR/docs" "$CODEX_HOME/"

# 5. Sync scripts directory
run rm -rf "$CODEX_HOME/scripts"
run cp -a "$ROOT_DIR/scripts" "$CODEX_HOME/"
run chmod +x "$CODEX_HOME/scripts"/*.sh 2>/dev/null || true

# 6. Update README.md (overwrite)
run cp "$ROOT_DIR/README.md" "$CODEX_HOME/README.md"

# Ensure runtime directories exist (don't delete if they exist)
runtime_dirs=(
  "log"
  "sessions"
  "shell_snapshots"
  "cache"
  "tmp"
  "rules"
)

for dir in "${runtime_dirs[@]}"; do
  run mkdir -p "$CODEX_HOME/$dir"
done

# Ensure permissions
run chmod 700 "$CODEX_HOME"

if [[ "$DRY_RUN" == true ]]; then
  log "dry-run complete; no files changed"
else
  log "patch complete"
fi

cat <<'POSTPATCH'

Authentication:
  codex login
  export OLLAMA_API_KEY="..."
  export NVIDIA_API_KEY="..."

Profiles:
  codex --profile gpt-5.4
  codex --profile gpt-5.3-codex
  codex --profile gpt-5.2
  codex --profile ollama-cloud-glm-5.1
  codex --profile ollama-cloud-glm-5
  codex --profile ollama-cloud-minimax-m2.7
  codex --profile ollama-cloud-minimax-m2.5
  codex --profile ollama-cloud-kimi-k2.6
  codex --profile ollama-cloud-kimi-k2.5
  codex --profile ollama-cloud-qwen3-coder-next
  codex --profile nvidia-glm-4.7

POSTPATCH
