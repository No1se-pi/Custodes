#!/usr/bin/env bash
set -o pipefail

# custodes.sh теперь только собирает модули и маршрутизирует команды. Вся
# предметная логика лежит в lib/commands, тексты — в locales, scanner — в Python.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

command_name="${1:-}"
if [[ -z "$command_name" ]]; then
    if [[ -t 0 ]]; then
        interactive_menu
    else
        cmd_help
    fi
    exit $?
fi
shift

case "$command_name" in
    help|-h|--help)       cmd_help "$@" ;;
    init|-i)              cmd_init "$@" ;;
    check|-ch)            cmd_check "$@" ;;
    status|-s)            cmd_status "$@" ;;
    settings|config|-cfg) cmd_settings "$@" ;;
    sonar)                cmd_sonar "$@" ;;
    remove|-r)            cmd_remove "$@" ;;
    update|-up)           cmd_update "$@" ;;
    uninstall|-un)        cmd_uninstall "$@" ;;
    about|-a)             cmd_about "$@" ;;
    *)
        ui_error "Unknown command: $command_name"
        printf 'Run: custodes help\n' >&2
        exit 2
        ;;
esac
