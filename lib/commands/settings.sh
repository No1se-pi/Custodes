#!/usr/bin/env bash

readonly CUSTODES_SETTING_KEYS=(
    CUSTODES_LANG
    CUSTODES_BANWORDS
    CUSTODES_EXCLUDE_PATHS
    CUSTODES_LOGO
    CUSTODES_OUTPUT_VIOLATIONS
    CUSTODES_REVEAL_VALUES
    CUSTODES_ENTROPY_ENABLED
    CUSTODES_ENTROPY_THRESHOLD
    CUSTODES_ENTROPY_MIN_LENGTH
    CUSTODES_SONAR_ENABLED
    CUSTODES_SONAR_MODE
    CUSTODES_SONAR_HOST_URL
    CUSTODES_SONAR_PROJECT_KEY
    CUSTODES_SONAR_TOKEN
    CUSTODES_SONAR_BLOCK_ON_FAILURE
    CUSTODES_SONAR_QUALITY_GATE_WAIT
    CUSTODES_SONAR_QUALITY_GATE_TIMEOUT
    CUSTODES_SONAR_SCANNER_IMAGE
)

valid_setting_key() {
    local wanted="$1" key
    for key in "${CUSTODES_SETTING_KEYS[@]}"; do
        [[ "$key" == "$wanted" ]] && return 0
    done
    return 1
}

validate_setting_value() {
    local key="$1" value="$2"
    case "$key" in
        CUSTODES_LANG) [[ "$value" == "eng" || "$value" == "ru" ]] ;;
        CUSTODES_LOGO|CUSTODES_OUTPUT_VIOLATIONS|CUSTODES_REVEAL_VALUES|\
        CUSTODES_ENTROPY_ENABLED|CUSTODES_SONAR_ENABLED|\
        CUSTODES_SONAR_BLOCK_ON_FAILURE|CUSTODES_SONAR_QUALITY_GATE_WAIT)
            [[ "${value,,}" =~ ^(yes|no|true|false|on|off|1|0)$ ]]
            ;;
        CUSTODES_ENTROPY_THRESHOLD)
            [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]] &&
                awk -v number="$value" 'BEGIN { exit !(number >= 2.5 && number <= 8.0) }'
            ;;
        CUSTODES_ENTROPY_MIN_LENGTH)
            [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 12 && value <= 512 ))
            ;;
        CUSTODES_SONAR_QUALITY_GATE_TIMEOUT)
            [[ "$value" =~ ^[0-9]+$ ]] && (( value >= 10 && value <= 3600 ))
            ;;
        CUSTODES_SONAR_MODE) [[ "$value" == "docker" || "$value" == "native" ]] ;;
        CUSTODES_SONAR_HOST_URL) [[ "$value" =~ ^https?://[^[:space:]]+$ ]] ;;
        CUSTODES_SONAR_PROJECT_KEY) [[ -z "$value" || "$value" =~ ^[A-Za-z0-9_.:-]+$ ]] ;;
        CUSTODES_BANWORDS|CUSTODES_EXCLUDE_PATHS|CUSTODES_SONAR_TOKEN|CUSTODES_SONAR_SCANNER_IMAGE) [[ -n "$value" ]] ;;
        *) return 1 ;;
    esac
}

masked_setting() {
    local key="$1" value="$2"
    if [[ "$key" == "CUSTODES_SONAR_TOKEN" && -n "$value" ]]; then
        printf '%s\n' "<configured, hidden>"
    else
        printf '%s\n' "${value:-<empty>}"
    fi
}

show_settings() {
    ensure_config || return 2
    ui_section "Custodes settings"
    local key value
    for key in "${CUSTODES_SETTING_KEYS[@]}"; do
        value="$(config_get_raw "$key" 2>/dev/null || true)"
        ui_key_value "$key" "$(masked_setting "$key" "$value")"
    done
    printf '\n%s%s%s\n' "$UI_MUTED" "$CUSTODES_CONFIG" "$UI_RESET"
}

set_setting() {
    local key="${1:-}" value="${2:-}"
    valid_setting_key "$key" || {
        ui_error "Unknown or unsafe setting key: ${key:-<empty>}"
        return 2
    }
    validate_setting_value "$key" "$value" || {
        ui_error "Invalid value for $key. Configuration was not changed."
        return 2
    }
    config_set "$key" "$value" || { ui_error "Cannot write $CUSTODES_CONFIG"; return 2; }
    [[ "$key" == "CUSTODES_LANG" ]] && load_language
    ui_success "$(t config_saved)"
}

settings_menu() {
    local choice value
    while true; do
        ui_banner
        ui_section "Settings"
        ui_key_value "1) Language" "$(config_value CUSTODES_LANG eng lang_custodes)"
        ui_key_value "2) Entropy detection" "$(config_value CUSTODES_ENTROPY_ENABLED yes entropy)"
        ui_key_value "3) Entropy threshold" "$(config_value CUSTODES_ENTROPY_THRESHOLD 4.0)"
        ui_key_value "4) Minimum token length" "$(config_value CUSTODES_ENTROPY_MIN_LENGTH 20)"
        ui_key_value "5) Banwords" "$(config_value CUSTODES_BANWORDS 'API_KEY,password' banwords)"
        ui_key_value "6) SonarQube" "$(config_value CUSTODES_SONAR_ENABLED no)"
        ui_key_value "7) Sonar mode" "$(config_value CUSTODES_SONAR_MODE docker)"
        ui_key_value "8) Sonar URL" "$(config_value CUSTODES_SONAR_HOST_URL http://localhost:9000)"
        ui_key_value "9) Sonar project" "$(config_value CUSTODES_SONAR_PROJECT_KEY '<auto>')"
        ui_key_value "10) Sonar token" "$(masked_setting CUSTODES_SONAR_TOKEN "$(config_value CUSTODES_SONAR_TOKEN '')")"
        ui_key_value "11) Block on Sonar error" "$(config_value CUSTODES_SONAR_BLOCK_ON_FAILURE yes)"
        ui_key_value "12) Reveal secret values" "$(config_value CUSTODES_REVEAL_VALUES no)"
        printf '\n0) Back\n> '
        read -r choice
        case "$choice" in
            1) printf 'eng/ru: '; read -r value; set_setting CUSTODES_LANG "$value" ;;
            2) printf 'yes/no: '; read -r value; set_setting CUSTODES_ENTROPY_ENABLED "$value" ;;
            3) printf '2.5..8.0: '; read -r value; set_setting CUSTODES_ENTROPY_THRESHOLD "$value" ;;
            4) printf '12..512: '; read -r value; set_setting CUSTODES_ENTROPY_MIN_LENGTH "$value" ;;
            5) printf 'Comma-separated rules: '; read -r value; set_setting CUSTODES_BANWORDS "$value" ;;
            6) printf 'yes/no: '; read -r value; set_setting CUSTODES_SONAR_ENABLED "$value" ;;
            7) printf 'docker/native: '; read -r value; set_setting CUSTODES_SONAR_MODE "$value" ;;
            8) printf 'URL: '; read -r value; set_setting CUSTODES_SONAR_HOST_URL "$value" ;;
            9) printf 'Project key (empty = auto): '; read -r value; set_setting CUSTODES_SONAR_PROJECT_KEY "$value" ;;
            10)
                printf 'Sonar token (input hidden): '
                read -rs value
                printf '\n'
                set_setting CUSTODES_SONAR_TOKEN "$value"
                unset value
                ;;
            11) printf 'yes/no: '; read -r value; set_setting CUSTODES_SONAR_BLOCK_ON_FAILURE "$value" ;;
            12) printf 'yes/no (no is safer): '; read -r value; set_setting CUSTODES_REVEAL_VALUES "$value" ;;
            0) return 0 ;;
            *) ui_warn "Choose a number from the menu." ;;
        esac
        printf '\nPress Enter to continue...'
        read -r
    done
}

cmd_settings() {
    local action="${1:-}"
    case "$action" in
        show) show_settings ;;
        path) printf '%s\n' "$CUSTODES_CONFIG" ;;
        set) shift; set_setting "${1:-}" "${2:-}" ;;
        "")
            if [[ -t 0 ]]; then settings_menu; else show_settings; fi
            ;;
        *) ui_error "Usage: custodes settings [show|path|set KEY VALUE]"; return 2 ;;
    esac
}
