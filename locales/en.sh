#!/usr/bin/env bash

message_en() {
    case "$1" in
        not_repo) printf '%s' "Run this command inside a Git repository." ;;
        hook_exists) printf '%s' "A non-Custodes pre-commit hook already exists; it was not overwritten." ;;
        hook_installed) printf '%s' "Custodes pre-commit hook installed." ;;
        hook_removed) printf '%s' "Custodes hook removed from this repository." ;;
        hook_not_owned) printf '%s' "The current pre-commit hook is not managed by Custodes." ;;
        scan_start) printf '%s' "Scanning staged changes for secrets..." ;;
        scan_failed) printf '%s' "Security scan blocked the commit; SonarQube was not started." ;;
        sonar_disabled) printf '%s' "SonarQube scan is disabled in settings." ;;
        sonar_start) printf '%s' "Security scan passed. Starting SonarQube analysis..." ;;
        sonar_passed) printf '%s' "SonarQube analysis and Quality Gate passed." ;;
        sonar_failed) printf '%s' "SonarQube analysis or Quality Gate failed." ;;
        config_saved) printf '%s' "Settings saved." ;;
        update_none) printf '%s' "The latest Custodes version is already installed." ;;
        *) printf '%s' "$1" ;;
    esac
}
