#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIR="$ROOT_DIR/models"
OUTPUT="$ROOT_DIR/model-catalog.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

if [[ ! -d "$MODELS_DIR" ]]; then
  echo "error: missing models directory: $MODELS_DIR" >&2
  exit 1
fi

shopt -s nullglob
model_files=("$MODELS_DIR"/*.json)
shopt -u nullglob

if (( ${#model_files[@]} == 0 )); then
  echo "error: no model JSON files found in $MODELS_DIR" >&2
  exit 1
fi

for file in "${model_files[@]}"; do
  jq -e 'type == "object"' "$file" >/dev/null
done

jq -s '{models: sort_by(.priority, .slug)}' "${model_files[@]}" > "$OUTPUT"
echo "wrote $OUTPUT"
