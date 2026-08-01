#!/usr/bin/env bash

message_ru() {
    case "$1" in
        not_repo) printf '%s' "Запусти эту команду внутри Git-репозитория." ;;
        hook_exists) printf '%s' "Уже есть чужой pre-commit hook; Custodes не стал его перезаписывать." ;;
        hook_installed) printf '%s' "Pre-commit hook Custodes установлен." ;;
        hook_removed) printf '%s' "Hook Custodes удалён из этого репозитория." ;;
        hook_not_owned) printf '%s' "Текущий pre-commit hook не принадлежит Custodes." ;;
        scan_start) printf '%s' "Проверяю staged-изменения на секреты..." ;;
        scan_failed) printf '%s' "Проверка безопасности заблокировала коммит; SonarQube не запускался." ;;
        sonar_disabled) printf '%s' "Проверка SonarQube отключена в настройках." ;;
        sonar_start) printf '%s' "Секретов нет. Запускаю анализ SonarQube..." ;;
        sonar_passed) printf '%s' "Анализ SonarQube и Quality Gate пройдены." ;;
        sonar_failed) printf '%s' "Анализ SonarQube или Quality Gate завершился ошибкой." ;;
        config_saved) printf '%s' "Настройки сохранены." ;;
        update_none) printf '%s' "Уже установлена последняя версия Custodes." ;;
        *) printf '%s' "$1" ;;
    esac
}
