#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIR="$ROOT_DIR/models"
CATALOG="$ROOT_DIR/model-catalog.json"
CONFIG="$ROOT_DIR/config.toml"
CAPABILITIES="$ROOT_DIR/docs/model-capabilities.md"
BUILDER="$ROOT_DIR/scripts/build-model-catalog.sh"

fail() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

command -v jq >/dev/null 2>&1 || fail "jq is required"

require_file "$CONFIG"
require_file "$CAPABILITIES"
require_file "$BUILDER"
require_file "$CATALOG"

shopt -s nullglob
json_files=("$ROOT_DIR"/*.json "$MODELS_DIR"/*.json)
model_files=("$MODELS_DIR"/*.json)
script_files=("$ROOT_DIR"/*.sh "$ROOT_DIR"/scripts/*.sh)
shopt -u nullglob

(( ${#model_files[@]} > 0 )) || fail "no model files found"

for file in "${json_files[@]}"; do
  jq empty "$file" >/dev/null || fail "invalid JSON: $file"
done

for file in "${model_files[@]}"; do
  jq -e 'type == "object"' "$file" >/dev/null || fail "model file must contain one object: $file"
  jq -e '
    has("slug") and
    has("display_name") and
    has("description") and
    has("default_reasoning_level") and
    has("supported_reasoning_levels") and
    has("shell_type") and
    has("visibility") and
    has("supported_in_api") and
    has("priority") and
    has("base_instructions") and
    has("model_messages") and
    has("supports_reasoning_summaries") and
    has("default_reasoning_summary") and
    has("support_verbosity") and
    has("default_verbosity") and
    has("apply_patch_tool_type") and
    has("web_search_tool_type") and
    has("truncation_policy") and
    has("supports_parallel_tool_calls") and
    has("supports_image_detail_original") and
    has("context_window") and
    has("input_modalities") and
    has("supports_search_tool") and
    has("experimental_supported_tools") and
    has("additional_speed_tiers")
  ' "$file" >/dev/null || fail "model file is missing required keys: $file"
done

duplicate_slugs="$(jq -r '.slug' "${model_files[@]}" | sort | uniq -d)"
[[ -z "$duplicate_slugs" ]] || fail "duplicate model slugs: $duplicate_slugs"

tmp_catalog="$(mktemp)"
trap 'rm -f "$tmp_catalog"' EXIT
jq -s '{models: sort_by(.priority, .slug)}' "${model_files[@]}" > "$tmp_catalog"
cmp -s "$tmp_catalog" "$CATALOG" || fail "model-catalog.json is stale; run scripts/build-model-catalog.sh"

jq -e '.models | type == "array" and length > 0' "$CATALOG" >/dev/null || fail "catalog must contain a non-empty models array"

profile_models="$(
  awk -F= '
    /^[[:space:]]*model[[:space:]]*=/ {
      value=$2
      sub(/^[[:space:]]*"/, "", value)
      sub(/"[[:space:]]*$/, "", value)
      print value
    }
  ' "$CONFIG" | sort -u
)"

catalog_slugs="$(jq -r '.models[].slug' "$CATALOG" | sort -u)"
while IFS= read -r model; do
  [[ -n "$model" ]] || continue
  grep -Fxq "$model" <<<"$catalog_slugs" || fail "config references model not in catalog: $model"
done <<<"$profile_models"

grep -Fq 'model_catalog_json = "/home/dhoard/.codex/model-catalog.json"' "$CONFIG" || fail "config.toml must point at installed model-catalog.json"
grep -Fq 'base_url = "https://ollama.com/v1"' "$CONFIG" || fail "config.toml must use direct Ollama Cloud SaaS endpoint"
grep -Fq 'env_key = "OLLAMA_API_KEY"' "$CONFIG" || fail "config.toml must use OLLAMA_API_KEY for direct Ollama Cloud auth"
if grep -Fq "localhost:11434" "$CONFIG"; then
  fail "config.toml must not require a local Ollama proxy"
fi

for slug in $(jq -r '.models[].slug' "$CATALOG"); do
  grep -Fq "\`$slug\`" "$CAPABILITIES" || fail "capabilities doc missing slug: $slug"
done

jq -e '
  [
    .models[]
    | select(.slug | test("^(glm-5|glm-5.1|minimax-m2.7|qwen3-coder-next):cloud$"))
    | select(.input_modalities != ["text"])
  ]
  | length == 0
' "$CATALOG" >/dev/null || fail "text-only Ollama models must not advertise image input"

jq -e '
  .models[]
  | select(.slug == "qwen3-coder-next:cloud")
  | select(.supports_reasoning_summaries == false and .default_reasoning_level == "low" and (.supported_reasoning_levels | length == 1))
' "$CATALOG" >/dev/null || fail "qwen3-coder-next:cloud must remain non-thinking"

jq -e '
  [
    .models[]
    | select(.slug | test(":cloud$"))
    | select(.supports_search_tool != true or .web_search_tool_type != "text")
  ]
  | length == 0
' "$CATALOG" >/dev/null || fail "Ollama Cloud models must enable text web search to match the gpt-5.2 baseline"

for file in "${script_files[@]}"; do
  bash -n "$file" || fail "shell syntax check failed: $file"
done

echo "validation passed"
