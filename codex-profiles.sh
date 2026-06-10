#!/usr/bin/env bash
# codex-profiles.sh — list available Codex profiles
#
# Scans $CODEX_HOME/*.config.toml (default ~/.codex/) and displays each
# profile's name, model, and provider, marking the currently active one.
#
# Usage: ./codex-profiles.sh [--no-color]

set -euo pipefail

usage() {
    sed -n '3,8p' "$0"
    exit 0
}

# --- color support ---
use_color=true
for arg in "$@"; do
    case "$arg" in
        --no-color) use_color=false ;;
        --help|-h)  usage ;;
    esac
done

if [[ $use_color == true ]] && [[ -t 1 ]]; then
    if command -v tput &>/dev/null; then
        GREEN=$(tput setaf 2); BOLD=$(tput bold)
        DIM=$(tput dim);       RESET=$(tput sgr0)
    else
        GREEN='\033[32m'; BOLD='\033[1m'
        DIM='\033[2m';   RESET='\033[0m'
    fi
else
    GREEN=''; BOLD=''; DIM=''; RESET=''
fi

# --- determine CODEX_HOME ---
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

if [[ ! -d "$CODEX_HOME" ]]; then
    echo "Error: CODEX_HOME ('$CODEX_HOME') does not exist or is not a directory." >&2
    exit 1
fi

# --- gather profile files (exclude config.toml itself) ---
profile_files=()
shopt -s nullglob
for f in "$CODEX_HOME"/*.config.toml; do
    [[ "$(basename "$f")" != "config.toml" ]] && profile_files+=("$f")
done
shopt -u nullglob

if [[ ${#profile_files[@]} -eq 0 ]]; then
    echo "No Codex profiles found in $CODEX_HOME (no *.config.toml files)."
    exit 0
fi

mapfile -t profile_files < <(printf '%s\n' "${profile_files[@]}" | sort)

# --- helpers ---
toml_value() {
    local key="$1" file="$2"
    sed -n "s/^${key}[[:space:]]*=[[:space:]]*\"\(.*\)\".*$/\1/p" "$file" | head -1
}

# --- load current config ---
current_config="$CODEX_HOME/config.toml"
current_model=""; current_provider=""
if [[ -f "$current_config" ]]; then
    current_model=$(toml_value "model" "$current_config")
    current_provider=$(toml_value "model_provider" "$current_config")
fi

# --- find active profile by matching model + model_provider ---
active_profile=""
ambiguous=false
for f in "${profile_files[@]}"; do
    name=$(basename "$f" .config.toml)
    p_model=$(toml_value "model" "$f")
    p_provider=$(toml_value "model_provider" "$f")
    if [[ "$p_model" == "$current_model" && "$p_provider" == "$current_provider" ]]; then
        if [[ -n "$active_profile" ]]; then
            ambiguous=true
        else
            active_profile="$name"
        fi
    fi
done

# --- calculate column widths from longest data (1 space between columns) ---
col1_width=7   # "Profile"
col2_width=5   # "Model"
col3_width=8   # "Provider"

for f in "${profile_files[@]}"; do
    name=$(basename "$f" .config.toml)
    p_model=$(toml_value "model" "$f")
    p_provider=$(toml_value "model_provider" "$f")
    p_model=${p_model:-"(not set)"}
    p_provider=${p_provider:-"(not set)"}

    (( ${#name} > col1_width )) && col1_width=${#name}
    (( ${#p_model} > col2_width )) && col2_width=${#p_model}
    (( ${#p_provider} > col3_width )) && col3_width=${#p_provider}
done

# Reserve 2 chars for "→ " active marker

# --- display table (left-aligned, 1 space between columns) ---
printf "%-${col1_width}s %-${col2_width}s %s\n" "Profile" "Model" "Provider"
printf "%-${col1_width}s %-${col2_width}s %s\n" "-------" "-----" "--------"

for f in "${profile_files[@]}"; do
    name=$(basename "$f" .config.toml)
    p_model=$(toml_value "model" "$f")
    p_provider=$(toml_value "model_provider" "$f")
    p_model=${p_model:-"(not set)"}
    p_provider=${p_provider:-"(not set)"}

    if [[ "$name" == "$active_profile" ]]; then
        # Print marker/color outside padded field so ANSI codes don't skew alignment
        printf '%s' "${GREEN}→ ${GREEN}${BOLD}"
        printf "%-$((col1_width - 2))s${RESET} " "$name"
    else
        printf "%-${col1_width}s " "$name"
    fi
    printf "%-${col2_width}s %s\n" "$p_model" "$p_provider"
done

# --- footer notes ---
if [[ -z "$active_profile" ]]; then
    printf '\n%sNote:%s current config.toml (model=%s, provider=%s) does not match any profile.\n' \
        "${DIM}" "${RESET}" "${current_model:-"(not set)"}" "${current_provider:-"(not set)"}"
elif [[ "$ambiguous" == true ]]; then
    printf '\n%sNote:%s multiple profiles match the current config.toml settings.\n' \
        "${DIM}" "${RESET}"
fi

printf '\nUse: codex -p <profile-name> to switch profiles\n'
