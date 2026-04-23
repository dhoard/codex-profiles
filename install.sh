#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BACKUP=true
YES=false
DRY_RUN=false
FORCE=false

usage() {
  cat <<'USAGE'
usage: ./install.sh [--yes] [--no-backup] [--dry-run] [--force]

Deletes and recreates ~/.codex, backing it up first by default.
USAGE
}

log() {
  echo "$*"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      YES=true
      shift
      ;;
    --no-backup)
      BACKUP=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
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

if ! "$ROOT_DIR/scripts/validate.sh"; then
  if [[ "$FORCE" == true ]]; then
    echo "warning: validation failed but --force was supplied" >&2
  else
    echo "error: validation failed; fix it or rerun with --force" >&2
    exit 1
  fi
fi

log "This will delete and recreate: $CODEX_HOME"

if [[ "$YES" != true ]]; then
  printf 'Type DELETE to continue: '
  read -r answer
  [[ "$answer" == "DELETE" ]] || { echo "aborted"; exit 1; }
fi

backup_path=""
if [[ -e "$CODEX_HOME" && "$BACKUP" == true ]]; then
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup_path="$HOME/.codex.backup.$timestamp"
  suffix=1
  while [[ -e "$backup_path" ]]; do
    backup_path="$HOME/.codex.backup.$timestamp.$suffix"
    suffix=$((suffix + 1))
  done
  run mv "$CODEX_HOME" "$backup_path"
elif [[ -e "$CODEX_HOME" ]]; then
  run rm -rf "$CODEX_HOME"
fi

run mkdir -p "$CODEX_HOME"

copy_paths=(
  "README.md"
  "config.toml"
  "model-catalog.json"
  "docs"
  "models"
  "scripts"
)

for path in "${copy_paths[@]}"; do
  run cp -a "$ROOT_DIR/$path" "$CODEX_HOME/"
done

for optional_path in rules skills; do
  if [[ -e "$ROOT_DIR/$optional_path" ]]; then
    run cp -a "$ROOT_DIR/$optional_path" "$CODEX_HOME/"
  fi
done

runtime_dirs=(
  "log"
  "sessions"
  "shell_snapshots"
  "cache"
  "tmp"
  "rules"
)

for path in "${runtime_dirs[@]}"; do
  run mkdir -p "$CODEX_HOME/$path"
done

run chmod 700 "$CODEX_HOME"
run chmod 600 "$CODEX_HOME/config.toml"
run chmod +x "$CODEX_HOME/scripts/build-model-catalog.sh" "$CODEX_HOME/scripts/validate.sh"

if [[ "$DRY_RUN" == true ]]; then
  log "dry-run complete; no files changed"
else
  log "installed Codex configuration to $CODEX_HOME"
  if [[ -n "$backup_path" ]]; then
    log "backup created at $backup_path"
  fi
fi

cat <<'POSTINSTALL'

Authentication:
  codex login
  export OLLAMA_API_KEY="..."

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

POSTINSTALL
