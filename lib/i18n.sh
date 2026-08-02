#!/usr/bin/env bash

# Новые тексты добавляются в locales/en.sh и locales/ru.sh с одинаковым ключом.
t() {
    local key="$1"
    # shellcheck disable=SC2154 # selected_lang задаёт load_language из config.sh.
    if [[ "$selected_lang" == "ru" ]]; then
        message_ru "$key"
    else
        message_en "$key"
    fi
}
