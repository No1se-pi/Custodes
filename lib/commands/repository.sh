#!/usr/bin/env bash

readonly CUSTODES_HOOK_MARKER="# Managed by Custodes"

cmd_init() {
    require_git_repository || { ui_error "$(t not_repo)"; return 2; }
    local hooks_dir hook_path
    hooks_dir="$(git rev-parse --absolute-git-dir)/hooks"
    hook_path="${hooks_dir}/pre-commit"
    mkdir -p "$hooks_dir" || return 2

    if [[ -f "$hook_path" ]]; then
        if grep -Fq "$CUSTODES_HOOK_MARKER" "$hook_path"; then
            ui_success "$(t hook_installed)"
            return 0
        fi
        ui_error "$(t hook_exists)"
        return 1
    fi

    # Hook вызывает общий pipeline: сначала секреты, затем optional SonarQube.
    printf '%s\n' '#!/bin/sh' "$CUSTODES_HOOK_MARKER" \
        "\"${CUSTODES_ROOT}/custodes.sh\" check" > "$hook_path" || return 2
    chmod 755 "$hook_path" || return 2
    ui_success "$(t hook_installed)"
}

cmd_remove() {
    require_git_repository || { ui_error "$(t not_repo)"; return 2; }
    local hook_path
    hook_path="$(git rev-parse --absolute-git-dir)/hooks/pre-commit"
    if [[ ! -f "$hook_path" ]] || ! grep -Fq "$CUSTODES_HOOK_MARKER" "$hook_path"; then
        ui_warn "$(t hook_not_owned)"
        return 1
    fi
    rm -f -- "$hook_path" || return 2
    ui_success "$(t hook_removed)"
}

run_secret_scan() {
    local python_bin
    python_bin="$(find_python)" || { ui_error "Python interpreter not found."; return 2; }
    "$python_bin" "${CUSTODES_ROOT}/parser.py"
}

cmd_check() {
    require_git_repository || { ui_error "$(t not_repo)"; return 2; }
    local skip_sonar="no"
    [[ "${1:-}" == "--no-sonar" ]] && skip_sonar="yes"

    ui_info "$(t scan_start)"
    run_secret_scan
    local scan_code=$?
    if (( scan_code != 0 )); then
        ui_error "$(t scan_failed)"
        return "$scan_code"
    fi

    if [[ "$skip_sonar" == "yes" ]] || ! is_true "$(config_value CUSTODES_SONAR_ENABLED no)"; then
        ui_info "$(t sonar_disabled)"
        return 0
    fi

    ui_info "$(t sonar_start)"
    run_sonar_scan
    local sonar_code=$?
    if (( sonar_code == 0 )); then
        ui_success "$(t sonar_passed)"
        return 0
    fi

    ui_error "$(t sonar_failed)"
    if is_true "$(config_value CUSTODES_SONAR_BLOCK_ON_FAILURE yes)"; then
        return "$sonar_code"
    fi
    ui_warn "SonarQube failed, but CUSTODES_SONAR_BLOCK_ON_FAILURE=no."
    return 0
}

hook_status() {
    if ! require_git_repository; then
        printf '%s\n' "not in repository"
        return
    fi
    local hook_path
    hook_path="$(git rev-parse --absolute-git-dir)/hooks/pre-commit"
    if [[ -f "$hook_path" ]] && grep -Fq "$CUSTODES_HOOK_MARKER" "$hook_path"; then
        printf '%s\n' "installed"
    elif [[ -f "$hook_path" ]]; then
        printf '%s\n' "foreign hook"
    else
        printf '%s\n' "not installed"
    fi
}
