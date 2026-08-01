#!/usr/bin/env bash
set -o pipefail

# Installer поддерживает Linux и Windows Git Bash. Он не удаляет исходный clone:
# такое поведение неожиданно и опасно для каталога, где пользователь мог работать.
readonly TARGET_DIR="${HOME}/.local/share/custodes"
readonly BIN_DIR="${HOME}/.local/bin"
readonly ENV_FILE="${TARGET_DIR}/.env"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

select_language() {
    local answer
    while true; do
        printf 'Select language / Выберите язык:\n1) English\n2) Русский\n> ' >&2
        read -r answer
        case "${answer,,}" in
            ""|1|en|eng|english) selected_language=eng; return ;;
            2|ru|rus|russian|русский) selected_language=ru; return ;;
            *) printf 'Enter 1/2 or eng/ru.\n' >&2 ;;
        esac
    done
}

find_system_python() {
    local command_name candidate
    for command_name in python3 python; do
        candidate="$(command -v "$command_name" 2>/dev/null || true)"
        [[ -n "$candidate" ]] || continue
        # Windows Store создаёт python3.exe alias, который существует, но не
        # является рабочим интерпретатором. Проверяем запуск, а не только PATH.
        if "$candidate" -c 'import sys; raise SystemExit(sys.version_info.major != 3)' \
            >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

copy_application() {
    local item
    if [[ "$SCRIPT_DIR" == "$TARGET_DIR" ]]; then
        return 0
    fi
    mkdir -p "$TARGET_DIR" "$BIN_DIR" || return 1
    for item in custodes.sh parser.py README.md LICENSE.md requirements.txt \
        lib locales custodes config; do
        [[ -e "${SCRIPT_DIR}/${item}" ]] || {
            printf 'Missing distribution component: %s\n' "$item" >&2
            return 1
        }
        rm -rf -- "${TARGET_DIR:?}/${item}"
        cp -a "${SCRIPT_DIR}/${item}" "$TARGET_DIR/" || return 1
    done
}

create_config() {
    local language="$1"
    if [[ ! -f "$ENV_FILE" ]]; then
        cp "${TARGET_DIR}/config/custodes.env.example" "$ENV_FILE" || return 1
    fi
    if grep -qE '^CUSTODES_LANG=' "$ENV_FILE"; then
        sed -i -E "s/^CUSTODES_LANG=.*/CUSTODES_LANG=${language}/" "$ENV_FILE"
    else
        printf '\nCUSTODES_LANG=%s\n' "$language" >> "$ENV_FILE"
    fi
    chmod 600 "$ENV_FILE" 2>/dev/null || true
}

create_virtualenv() {
    local python_bin="$1" venv_python
    "$python_bin" -m venv "${TARGET_DIR}/.venv" || return 1
    if [[ -x "${TARGET_DIR}/.venv/bin/python" ]]; then
        venv_python="${TARGET_DIR}/.venv/bin/python"
    else
        venv_python="${TARGET_DIR}/.venv/Scripts/python.exe"
    fi
    "$venv_python" -m pip install --quiet --upgrade pip || return 1
    "$venv_python" -m pip install --quiet -r "${TARGET_DIR}/requirements.txt"
}

create_launcher() {
    # shellcheck disable=SC2016 # HOME и $@ должны раскрыться при запуске launcher.
    printf '%s\n' '#!/usr/bin/env bash' \
        '"${HOME}/.local/share/custodes/custodes.sh" "$@"' > "${BIN_DIR}/custodes" || return 1
    chmod 755 "${TARGET_DIR}/custodes.sh" "${BIN_DIR}/custodes" || return 1
}

cat <<'WELCOME'
╭────────────────────────────────────────────╮
│  CUSTODES  ·  pre-commit security guard   │
╰────────────────────────────────────────────╯

Custodes will be installed into ~/.local/share/custodes.
The command launcher will be created at ~/.local/bin/custodes.
WELCOME
printf 'Continue? [y/N] '
read -r confirmation
case "${confirmation,,}" in y|yes|д|да) ;; *) exit 0 ;; esac

selected_language=eng
select_language
python_bin="$(find_system_python)" || {
    printf 'Python 3 was not found. Install it and run installer.sh again.\n' >&2
    exit 2
}

copy_application || { printf 'Cannot copy Custodes files.\n' >&2; exit 2; }
create_config "$selected_language" || { printf 'Cannot create settings file.\n' >&2; exit 2; }
create_virtualenv "$python_bin" || { printf 'Cannot create Python environment.\n' >&2; exit 2; }
create_launcher || { printf 'Cannot create command launcher.\n' >&2; exit 2; }

printf '\nCustodes installed successfully.\n'
printf 'If the command is not found, add ~/.local/bin to PATH.\n'
printf 'Next: cd <repository> && custodes init\n'
