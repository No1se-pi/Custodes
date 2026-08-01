#!/usr/bin/env bash

# .env не source-ится как shell-код. Это важно: конфиг может быть повреждён,
# а выполнение его содержимого дало бы произвольный запуск команд.
ensure_config() {
    if [[ -f "$CUSTODES_CONFIG" ]]; then
        return 0
    fi
    mkdir -p "$(dirname -- "$CUSTODES_CONFIG")" || return 1
    cp "${CUSTODES_ROOT}/config/custodes.env.example" "$CUSTODES_CONFIG" || return 1
    chmod 600 "$CUSTODES_CONFIG" 2>/dev/null || true
}

config_get_raw() {
    local key="$1"
    [[ -f "$CUSTODES_CONFIG" ]] || return 1
    awk -v wanted="$key" '
        /^[[:space:]]*#/ { next }
        index($0, "=") {
            key = substr($0, 1, index($0, "=") - 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            if (key != wanted) next
            value = substr($0, index($0, "=") + 1)
            sub(/[[:space:]]+#.*/, "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (value ~ /^".*"$/ || value ~ /^'"'"'.*'"'"'$/) {
                value = substr(value, 2, length(value) - 2)
            }
            print value
            exit
        }
    ' "$CUSTODES_CONFIG"
}

config_value() {
    local key="$1"
    local default_value="$2"
    local legacy_key="${3:-}"
    local value=""
    value="$(config_get_raw "$key" 2>/dev/null || true)"
    if [[ -z "$value" && -n "$legacy_key" ]]; then
        value="$(config_get_raw "$legacy_key" 2>/dev/null || true)"
    fi
    printf '%s\n' "${value:-$default_value}"
}

config_set() {
    local key="$1"
    local value="$2"
    local temp_file
    ensure_config || return 1
    temp_file="$(mktemp "${CUSTODES_CONFIG}.XXXXXX")" || return 1
    awk -v wanted="$key" -v replacement="$value" '
        BEGIN { replaced = 0 }
        {
            line = $0
            if (index(line, "=") && line !~ /^[[:space:]]*#/) {
                key = substr(line, 1, index(line, "=") - 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                if (key == wanted) {
                    if (!replaced) print wanted "=" replacement
                    replaced = 1
                    next
                }
            }
            print line
        }
        END { if (!replaced) print wanted "=" replacement }
    ' "$CUSTODES_CONFIG" > "$temp_file" || { rm -f "$temp_file"; return 1; }
    mv "$temp_file" "$CUSTODES_CONFIG" || return 1
    chmod 600 "$CUSTODES_CONFIG" 2>/dev/null || true
}

load_language() {
    selected_lang="$(config_value CUSTODES_LANG eng lang_custodes)"
    case "$selected_lang" in
        eng|ru) ;;
        *) selected_lang="eng" ;;
    esac
}
