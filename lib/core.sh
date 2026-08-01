#!/usr/bin/env bash

# Этот файл содержит только общие константы и маленькие функции. Команды CLI
# лежат отдельно, поэтому изменение update или sonar не раздувает custodes.sh.
# shellcheck disable=SC2034 # Константы используются в других sourced-модулях.
CUSTODES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CUSTODES_ROOT
readonly CUSTODES_HOME="${CUSTODES_HOME:-${HOME}/.local/share/custodes}"
readonly CUSTODES_CONFIG="${CUSTODES_CONFIG:-${CUSTODES_HOME}/.env}"
readonly CUSTODES_BIN="${CUSTODES_BIN:-${HOME}/.local/bin/custodes}"
readonly CUSTODES_VERSION="1.1.0"
readonly REMOTE_REPO_URL="https://github.com/No1se-pi/Custodes.git"
readonly REMOTE_BRANCH="release"

export CUSTODES_CONFIG

is_true() {
    case "${1,,}" in
        1|true|yes|on|y) return 0 ;;
        *) return 1 ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_git_repository() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

git_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

find_python() {
    local candidate
    for candidate in \
        "${CUSTODES_HOME}/.venv/bin/python" \
        "${CUSTODES_HOME}/.venv/Scripts/python.exe" \
        "${CUSTODES_ROOT}/venv/Scripts/python.exe"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    if command_exists python3; then
        command -v python3
    elif command_exists python; then
        command -v python
    else
        return 1
    fi
}

safe_custodes_home() {
    [[ -n "${HOME:-}" ]] || return 1
    [[ "$CUSTODES_HOME" == "${HOME}/.local/share/custodes" ]] || return 1
    [[ "$CUSTODES_HOME" != "/" && "$CUSTODES_HOME" != "$HOME" ]] || return 1
}
