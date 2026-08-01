#!/usr/bin/env bash

# shellcheck disable=SC2034 # Цвета используются в других sourced-модулях.

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    readonly UI_RESET=$'\033[0m'
    readonly UI_BOLD=$'\033[1m'
    readonly UI_MUTED=$'\033[90m'
    readonly UI_PURPLE=$'\033[35m'
    readonly UI_BLUE=$'\033[36m'
    readonly UI_GREEN=$'\033[32m'
    readonly UI_YELLOW=$'\033[33m'
    readonly UI_RED=$'\033[31m'
else
    readonly UI_RESET="" UI_BOLD="" UI_MUTED="" UI_PURPLE="" UI_BLUE=""
    readonly UI_GREEN="" UI_YELLOW="" UI_RED=""
fi

ui_banner() {
    printf '%s\n' "${UI_PURPLE}${UI_BOLD}╭────────────────────────────────────────────╮${UI_RESET}"
    printf '%s\n' "${UI_PURPLE}${UI_BOLD}│  CUSTODES  ·  pre-commit security guard   │${UI_RESET}"
    printf '%s\n' "${UI_PURPLE}${UI_BOLD}╰────────────────────────────────────────────╯${UI_RESET}"
}

ui_section() { printf '\n%s%s%s\n' "$UI_BOLD" "$1" "$UI_RESET"; }
ui_info()    { printf '%s●%s %s\n' "$UI_BLUE" "$UI_RESET" "$1"; }
ui_success() { printf '%s✓%s %s\n' "$UI_GREEN" "$UI_RESET" "$1"; }
ui_warn()    { printf '%s!%s %s\n' "$UI_YELLOW" "$UI_RESET" "$1"; }
ui_error()   { printf '%s✗%s %s\n' "$UI_RED" "$UI_RESET" "$1" >&2; }
ui_key_value() { printf '  %-24s %s\n' "$1" "$2"; }

ui_confirm() {
    local prompt="$1"
    local answer
    printf '%s [y/N] ' "$prompt"
    read -r answer
    case "${answer,,}" in y|yes|д|да) return 0 ;; *) return 1 ;; esac
}
