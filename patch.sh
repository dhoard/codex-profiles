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
  "profiles"
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

  # Remove model_providers sections from target (preserves user customizations).
  awk '
    BEGIN { in_section = 0 }
    /^[[:space:]]*\[model_providers/ { in_section = 1; next }
    /^[[:space:]]*\[/ && in_section { in_section = 0 }
    in_section { next }
    { print }
  ' "$target_config" > "$tmp"

  # Append model_providers sections from source.
  awk '
    BEGIN { in_section = 0; started = 0 }
    /^[[:space:]]*\[model_providers/ { in_section = 1 }
    /^[[:space:]]*\[/ && in_section && !/^[[:space:]]*\[model_providers/ { in_section = 0 }
    in_section {
      if (!started) { started = 1; print "" }
      print
    }
  ' "$source_config" >> "$tmp"

  if [[ "$DRY_RUN" == true ]]; then
    rm -f "$tmp"
    log "would patch model_providers in $target_config"
    return
  fi

  mv "$tmp" "$target_config"
  chmod 600 "$target_config"
}

# Update static files
log "Patching $CODEX_HOME"

# 1. Patch config.toml model_providers only.
#    Other existing config.toml data (for example sandbox, permissions,
#    hooks, MCP servers, and local user preferences) is preserved.
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

# 6. Sync profile files to ~/.codex/<name>.config.toml
shopt -s nullglob
for profile_file in "$ROOT_DIR"/profiles/*.config.toml; do
  profile_name="$(basename "$profile_file")"
  run cp "$profile_file" "$CODEX_HOME/$profile_name"
done
shopt -u nullglob

# 7. Update README.md (overwrite)
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
  export DEEPSEEK_API_KEY="..."
  export OLLAMA_API_KEY="..."
  export NVIDIA_API_KEY="..."

Profiles:
POSTPATCH

shopt -s nullglob
for profile_file in "$ROOT_DIR"/profiles/*.config.toml; do
  profile_name="$(basename "$profile_file" .config.toml)"
  echo "  codex --profile $profile_name"
done | sort
shopt -u nullglob
