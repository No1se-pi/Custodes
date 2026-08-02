#!/usr/bin/env bash

readme_version() {
    local readme_path="$1"
    [[ -f "$readme_path" ]] || return 1
    awk '/^# Version / { print $3; exit }' "$readme_path"
}

version_key() {
    awk -F. -v version="$1" 'BEGIN {
        split(version, parts, ".")
        printf "%03d%03d%03d\n", parts[1], parts[2], parts[3]
    }'
}

cleanup_update_temp() {
    local allowed_prefix="${TMPDIR:-/tmp}/custodes-update."
    if [[ -n "${CUSTODES_UPDATE_TEMP_DIR:-}" &&
          "$CUSTODES_UPDATE_TEMP_DIR" == "${allowed_prefix}"* ]]; then
        rm -rf -- "$CUSTODES_UPDATE_TEMP_DIR"
    fi
}

cmd_status() {
    ui_banner
    ui_section "Runtime"
    ui_key_value "version" "$CUSTODES_VERSION"
    ui_key_value "installation" "$CUSTODES_ROOT"
    ui_key_value "configuration" "$CUSTODES_CONFIG"
    ui_key_value "Git hook" "$(hook_status)"
    ui_section "Security"
    ui_key_value "entropy" "$(config_value CUSTODES_ENTROPY_ENABLED yes entropy)"
    ui_key_value "threshold" "$(config_value CUSTODES_ENTROPY_THRESHOLD 4.0)"
    ui_key_value "minimum length" "$(config_value CUSTODES_ENTROPY_MIN_LENGTH 20)"
    ui_key_value "SonarQube" "$(config_value CUSTODES_SONAR_ENABLED no)"
    if sonar_server_status >/dev/null; then
        ui_key_value "Sonar server" "UP"
    else
        ui_key_value "Sonar server" "unavailable"
    fi
}

cmd_update() {
    local temp_dir repo_dir current_version remote_version python_bin
    current_version="$(readme_version "${CUSTODES_ROOT}/README.md")" || {
        ui_error "Installed README.md was not found."
        return 2
    }
    temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/custodes-update.XXXXXX")" || return 2
    CUSTODES_UPDATE_TEMP_DIR="$temp_dir"
    trap cleanup_update_temp EXIT
    repo_dir="${temp_dir}/repo"
    ui_info "Downloading ${REMOTE_BRANCH}..."
    git clone --quiet --depth 1 --single-branch --branch "$REMOTE_BRANCH" \
        "$REMOTE_REPO_URL" "$repo_dir" || return 2
    remote_version="$(readme_version "${repo_dir}/README.md")" || return 2

    if [[ ! "$(version_key "$remote_version")" > "$(version_key "$current_version")" ]]; then
        ui_success "$(t update_none)"
        return 0
    fi
    [[ -f "${repo_dir}/custodes.sh" && -d "${repo_dir}/lib" && -d "${repo_dir}/custodes" ]] || {
        ui_error "Downloaded release is incomplete."
        return 2
    }

    python_bin="$(find_python)" || return 2
    "$python_bin" -m pip install -q -r "${repo_dir}/requirements.txt" || return 2
    safe_custodes_home || { ui_error "Unsafe update target: $CUSTODES_HOME"; return 2; }

    # Сохраняем пользовательский конфиг, venv и кэш Sonar. Остальное является
    # версионируемым кодом релиза и заменяется атомарно подготовленной копией.
    find "$CUSTODES_HOME" -mindepth 1 -maxdepth 1 \
        ! -name '.env' ! -name '.venv' ! -name 'sonar-cache' \
        -exec rm -rf -- {} + || return 2
    rm -rf -- "${repo_dir}/.git" "${repo_dir}/.env" "${repo_dir}/.sonar"
    cp -a "${repo_dir}/." "$CUSTODES_HOME/" || return 2
    chmod 755 "${CUSTODES_HOME}/custodes.sh" 2>/dev/null || true
    rm -rf -- "$temp_dir"
    CUSTODES_UPDATE_TEMP_DIR=""
    trap - EXIT
    ui_success "Custodes updated: ${current_version} -> ${remote_version}"
}

cmd_uninstall() {
    safe_custodes_home || { ui_error "Unsafe uninstall target: $CUSTODES_HOME"; return 2; }
    ui_confirm "Remove Custodes from this system?" || return 0
    rm -rf -- "$CUSTODES_HOME" || return 2
    rm -f -- "$CUSTODES_BIN" "${CUSTODES_BIN}.cmd" || return 2
    ui_success "Custodes was removed. Repository hooks were left untouched."
}

cmd_about() {
    ui_banner
    printf '\nCustodes %s\n' "$CUSTODES_VERSION"
    printf 'GitHub:  %s\n' "$REMOTE_REPO_URL"
    printf 'Website: https://no1se-pi.github.io/Custodes/\n'
    printf 'Author:  Yaroslav Boikov / No1se\n'
}

cmd_help() {
    ui_banner
    cat <<'HELP'

Usage: custodes <command> [options]

Repository
  init                    Install the managed pre-commit hook
  check [--no-sonar]      Scan staged secrets, then optional SonarQube
  remove                  Remove only the managed hook
  status                  Show hook, entropy and SonarQube status

Configuration
  settings                Open the interactive settings interface
  settings show           Print settings with the Sonar token masked
  settings set KEY VALUE  Change one supported setting
  sonar status            Show SonarQube connection state
  sonar start|scan|logs   Control/use the existing `sonarqube` container

System
  update                  Update from the stable release branch
  uninstall               Remove the installed application
  about                   Project information
  help                    This screen

Pipeline: staged secrets -> entropy -> SonarQube -> Quality Gate -> commit
HELP
}

interactive_menu() {
    local choice
    while true; do
        ui_banner
        printf '\n1) Check staged changes\n2) Status\n3) Settings\n4) SonarQube status\n5) Help\n0) Exit\n> '
        read -r choice
        case "$choice" in
            1) cmd_check ;;
            2) cmd_status ;;
            3) settings_menu ;;
            4) cmd_sonar status ;;
            5) cmd_help ;;
            0) return 0 ;;
            *) ui_warn "Choose a number from the menu." ;;
        esac
        printf '\nPress Enter to continue...'
        read -r
    done
}
