#!/bin/bash

readonly CUSTODES_HOME="${HOME}/.local/share/custodes"
readonly CUSTODES_CONFIG="${CUSTODES_HOME}/.env"
readonly CUSTODES_BIN="${HOME}/.local/bin/custodes"
readonly DEFAULT_LANG="eng"
readonly REMOTE_BASE_URL="https://raw.githubusercontent.com/No1se-pi/Custodes/main"
readonly UPDATE_LIST_FILE="files_to_update.txt"

get_custodes_lang() {
    local lang=""

    if [[ -f "$CUSTODES_CONFIG" ]]; then
        lang=$(awk -F= '
            {
                sub(/^\357\273\277/, "")
            }
            /^[[:space:]]*lang_custodes[[:space:]]*=/ {
                value = $2
                sub(/[[:space:]]*#.*/, "", value)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                print value
                exit
            }
        ' "$CUSTODES_CONFIG")
    fi

    case "$lang" in
        eng|ru) printf '%s\n' "$lang" ;;
        *) printf '%s\n' "$DEFAULT_LANG" ;;
    esac
}

selected_lang="$(get_custodes_lang)"

print_i18n() {
    local text_var="${1}_${selected_lang}"
    printf '%s\n' "${!text_var}"
}

print_i18n_format() {
    local text_var="${1}_${selected_lang}"
    local text
    local replacement

    shift
    text="${!text_var}"

    for replacement in "$@"; do
        text="${text/\%s/$replacement}"
    done

    printf '%s\n' "$text"
}

#___________eng texts___________
help_text_eng="
CUSTODES — a mini security system for Git commits

Usage:
custodes <command> [options]

Commands:
help        Show Custodes help message
init        Install the pre-commit hook in the current Git repository
check       Scan staged files for possible secrets
status      Show Custodes status in the current repository
config      Show configuration path and current settings
uninstall   Remove Custodes and all attached components from the system
remove      Remove the Custodes hook from the current repository
about       Show project information

Examples:
custodes init
Install Custodes in the current repository

custodes check
Manually scan files added to the Git index

custodes status
Check whether the pre-commit hook is installed

Description:
Custodes scans staged changes before a commit and blocks the commit
if it finds possible secrets: API keys, tokens, passwords, or other
forbidden strings defined in the configuration.

Configuration:
Main settings are stored in the .env file or in the Custodes config file.
Forbidden words are defined through banwords / CUSTODES_BANWORDS.

Note:
Custodes scans only staged files, meaning changes added with git add.
"

pre_commit_text_eng="
The hooks folder already has a pre-commit script.
To avoid losing the script, delete it from the directory."

hook_rights_text_eng="
Error when granting pre-commit hook rights
We recommend running \"custodes init\" with sudo"

custodes_init_text_eng="
Use \"custodes init\" in the git repository
Use \"custodes help\" for see more"

custodes_remove_text_eng="
Use \"custodes remove\" in the git repository
Use \"custodes help\" for see more"

incorrect_input_text_eng="
Incorrect input, please use \"custodes help\" to use the program correctly.
"

success_hook_text_eng="
custodes hook has been successfully installed in your repository.
If you want to delete it, use \"custodes uninstall\"
"

uninstall_confirm_text_eng="
Are you sure you want to remove Custodes from your system?
[yes\no]"

uninstall_confirm_again_text_eng="
Are you REALLY sure you want to delete Custodes? 0_-
[yes\no]"

uninstall_support_confirm_text_eng="
Well, click \"yes\" if you don't mind the work of a student from Russia and you don't want to support him.
>_<
[yes\no]"

uninstall_error_text_eng="
Error deleting Custodes folders. Sudo rights may be required.
The system itself does not want to delete the program..."

uninstall_success_text_eng="
All system folders of the Custodes program have been deleted >_<
bye........"

status_latest_text_eng='The latest version of Custodes is installed: %s'

status_update_available_text_eng='Custodes update is available: %s -> %s
Run "custodes update" to install it.'

status_error_text_eng='Unable to check Custodes version: %s'

update_already_latest_text_eng='The latest version of Custodes is already installed: %s'

update_start_text_eng='Updating Custodes: %s -> %s'

update_download_text_eng='Downloading %s...'

update_dependencies_text_eng='Updating Python dependencies...'

update_preserve_env_text_eng='Skipping .env to preserve your settings.'

update_success_text_eng='Custodes updated successfully: %s -> %s'

update_error_text_eng='Update failed: %s'

about_text_eng="
   |\                 /|
   | \               / |
   |  \     /\      /  |
   |  /    /  \     \  |
   | /    / /\ \     \ |
   |/    / /()\ \     \|
   |\   / /____\ \    /|
   | \ /________\ \  / |
   |  /___________ \   |

GitHub - https://github.com/No1se-pi/Custodes
WebSite - https://no1se-pi.github.io/Custodes/

Project by - Yaroslav Boikov (No1se) ^-^
"

#___________ru texts___________
help_text_ru="
CUSTODES — мини-система безопасности для Git-коммитов

Использование:
custodes <команда> [опции]

Команды:
help        Показать это справочное сообщение Custodes
init        Установить pre-commit хук в текущий Git-репозиторий
check       Сканировать файлы в индексе (staged) на наличие возможных секретов
status      Показать статус Custodes в текущем репозитории
config      Показать путь к конфигурации и текущие настройки
uninstall   Удалить Custodes и все связанные компоненты из системы
remove      Удалить хук Custodes из текущего репозитория
about       Показать информацию о проекте

Примеры:
custodes init
Установить Custodes в текущий репозиторий

custodes check
Вручную отсканировать файлы, добавленные в индекс Git

custodes status
Проверить, установлен ли pre-commit хук

Описание:
Custodes сканирует подготовленные изменения перед коммитом и блокирует коммит,
если находит возможные секреты: API-ключи, токены, пароли или другие
запрещенные строки, определенные в конфигурации.

Конфигурация:
Основные настройки хранятся в файле .env или в конфигурационном файле Custodes.
Запрещенные слова определяются через banwords / CUSTODES_BANWORDS.

Примечание:
Custodes сканирует только файлы в индексе (staged), то есть изменения,
добавленные с помощью команды git add.
"



pre_commit_text_ru="
В папке hooks уже есть скрипт предварительной фиксации.
Чтобы избежать потери скрипта, удалите его из каталога самостоятельно сохранив его перед этим.
"

hook_rights_text_ru="
Ошибка при предоставлении прав перехвата предварительной фиксации
Мы рекомендуем запустить \"custodes init\" с помощью sudo"

custodes_init_text_ru="
Используйте \"custodes init\" в репозитории git
Используйте \"custodes help\" для получения дополнительной информации
"

custodes_remove_text_ru="
Используйте \"custodes remove\" в репозитории git
Используйте \"custodes help\", чтобы узнать больше
"

incorrect_input_text_ru="
Неправильно введенные данные, пожалуйста, используйте \"help custodes\" для правильного использования программы.
"

success_hook_text_ru="
custodes hook успешно установлен в вашем репозитории.
Если вы хотите удалить его, используйте \"custodes uninstall\".
"

uninstall_confirm_text_ru="
Вы уверены, что хотите удалить Custodes из системы?
[yes\no]"

uninstall_confirm_again_text_ru="
Вы ТОЧНО уверены, что хотите удалить Custodes? 0_-
[yes\no]"

uninstall_support_confirm_text_ru="
Что ж, нажмите \"yes\", если вам не жалко труд студента из России и вы не хотите его поддержать.
>_<
[yes\no]"

uninstall_error_text_ru="
Ошибка удаления папок Custodes. Возможно, нужны права sudo.
Система сама не хочет удалять программу..."

uninstall_success_text_ru="
Все системные папки программы Custodes были удалены >_<
bye........"

status_latest_text_ru='Установлена последняя версия Custodes: %s'

status_update_available_text_ru='Доступно обновление Custodes: %s -> %s
Запустите "custodes update", чтобы установить его.'

status_error_text_ru='Не удалось проверить версию Custodes: %s'

update_already_latest_text_ru='Уже установлена последняя версия Custodes: %s'

update_start_text_ru='Обновляю Custodes: %s -> %s'

update_download_text_ru='Скачиваю %s...'

update_dependencies_text_ru='Обновляю Python-зависимости...'

update_preserve_env_text_ru='Пропускаю .env, чтобы сохранить ваши настройки.'

update_success_text_ru='Custodes успешно обновлён: %s -> %s'

update_error_text_ru='Ошибка обновления: %s'

about_text_ru="
   |\                 /|
   | \               / |
   |  \     /\      /  |
   |  /    /  \     \  |
   | /    / /\ \     \ |
   |/    / /()\ \     \|
   |\   / /____\ \    /|
   | \ /________\ \  / |
   |  /___________ \   |

GitHub проекта - https://github.com/No1se-pi/Custodes
Сайт проекта - https://no1se-pi.github.io/Custodes/

Для вас старался - Яролсав Бойков (No1se) ^-^
"

get_readme_version() {
    local readme_path="$1"

    [[ -f "$readme_path" ]] || return 1
    grep -m 1 "^# Version" "$readme_path" | awk '{print $NF}'
}

get_remote_version() {
    curl -fsSL "${REMOTE_BASE_URL}/README.md" | grep -m 1 "^# Version" | awk '{print $NF}'
}

version_key() {
    local version="$1"

    awk -F. -v version="$version" 'BEGIN {
        split(version, parts, ".")
        printf "%03d%03d%03d\n", parts[1], parts[2], parts[3]
    }'
}

is_version_newer() {
    local new_version="$1"
    local old_version="$2"

    [[ "$(version_key "$new_version")" > "$(version_key "$old_version")" ]]
}

trim_update_line() {
    local value="$1"

    value="${value%%#*}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s\n' "$value"
}

is_safe_update_path() {
    local file="$1"

    [[ -n "$file" ]] || return 1

    case "$file" in
        /*|*\\*|*..*)
            return 1
            ;;
    esac

    return 0
}

#___________code___________

if ((  $# != 1  )); then
    print_i18n incorrect_input_text
    exit 1
fi

case "$1" in

    "help"|"-h")
        print_i18n help_text
        exit 0
        ;;

    "init"|"-i")

        git rev-parse --is-inside-work-tree > /dev/null 2>&1
        (( $? != 0 )) && { print_i18n custodes_init_text; exit 1; }

        git_dir="$(git rev-parse --absolute-git-dir)"
        cd "$git_dir/hooks"

        if [[ -f "pre-commit" ]]; then
            print_i18n pre_commit_text
            exit 1
        fi

        echo -e "#!/bin/sh\ncustodes check" > pre-commit

        chmod 755 pre-commit
        (( $? != 0 )) && { print_i18n hook_rights_text; exit 1; }

        print_i18n success_hook_text
        exit 0
        ;;
    
    "remove"|"-r")
        git rev-parse --is-inside-work-tree > /dev/null 2>&1
        (( $? != 0 )) && { print_i18n custodes_remove_text; exit 1; }

        git_dir="$(git rev-parse --absolute-git-dir)"
        cd "$git_dir/hooks"

        echo "Are you sure you want to delete Custodes from this repository? 0_-\n[yes\no]"
        read confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0        

        rm -f pre-commit || { print_i18n custodes_init_text; exit 1; }
        
        echo "Custodes removed from $git_dir"
        exit 0
        ;;

    "check"|"-ch")
        ~/.local/share/custodes/.venv/bin/python ~/.local/share/custodes/parser.py
        parser_code=$?
        exit "$parser_code"
        ;;

    "status"|"-s")
        version_now="$(get_readme_version "${CUSTODES_HOME}/README.md")" || {
            print_i18n_format status_error_text "installed README.md not found"
            exit 1
        }

        version_server="$(get_remote_version)" || {
            print_i18n_format status_error_text "remote README.md is unavailable"
            exit 1
        }

        if [[ -z "$version_now" || -z "$version_server" ]]; then
            print_i18n_format status_error_text "version value is empty"
            exit 1
        fi

        if is_version_newer "$version_server" "$version_now"; then
            print_i18n_format status_update_available_text "$version_now" "$version_server"
            exit 1
        else
            print_i18n_format status_latest_text "$version_now"
            exit 0
        fi
        ;;

    "update"|"-up")
        version_now="$(get_readme_version "${CUSTODES_HOME}/README.md")" || {
            print_i18n_format update_error_text "installed README.md not found"
            exit 1
        }

        version_server="$(get_remote_version)" || {
            print_i18n_format update_error_text "remote README.md is unavailable"
            exit 1
        }

        if [[ -z "$version_now" || -z "$version_server" ]]; then
            print_i18n_format update_error_text "version value is empty"
            exit 1
        fi

        if ! is_version_newer "$version_server" "$version_now"; then
            print_i18n_format update_already_latest_text "$version_now"
            exit 0
        fi

        mkdir -p "$CUSTODES_HOME" || {
            print_i18n_format update_error_text "cannot create ${CUSTODES_HOME}"
            exit 1
        }

        temp_dir="$(mktemp -d "${CUSTODES_HOME}/update.XXXXXX")" || {
            print_i18n_format update_error_text "cannot create temporary directory"
            exit 1
        }
        trap 'rm -rf "$temp_dir"' EXIT

        update_list_path="${temp_dir}/.update-files"

        print_i18n_format update_start_text "$version_now" "$version_server"

        curl -fsSL "${REMOTE_BASE_URL}/${UPDATE_LIST_FILE}" -o "$update_list_path" || {
            print_i18n_format update_error_text "cannot download ${UPDATE_LIST_FILE}"
            exit 1
        }

        while IFS= read -r file || [[ -n "$file" ]]; do
            file="$(trim_update_line "$file")"
            [[ -z "$file" ]] && continue

            if ! is_safe_update_path "$file"; then
                print_i18n_format update_error_text "unsafe path in update list: ${file}"
                exit 1
            fi

            if [[ "$file" == ".env" ]]; then
                print_i18n update_preserve_env_text
                continue
            fi

            print_i18n_format update_download_text "$file"
            mkdir -p "$(dirname "${temp_dir}/${file}")" || {
                print_i18n_format update_error_text "cannot create temporary path for ${file}"
                exit 1
            }

            curl -fsSL "${REMOTE_BASE_URL}/${file}" -o "${temp_dir}/${file}" || {
                print_i18n_format update_error_text "cannot download ${file}"
                exit 1
            }
        done < "$update_list_path"

        if [[ -f "${temp_dir}/requirements.txt" ]]; then
            if [[ ! -x "${CUSTODES_HOME}/.venv/bin/python" ]]; then
                print_i18n_format update_error_text "virtual environment not found; reinstall Custodes"
                exit 1
            fi

            print_i18n update_dependencies_text
            "${CUSTODES_HOME}/.venv/bin/python" -m pip install -r "${temp_dir}/requirements.txt" -q || {
                print_i18n_format update_error_text "dependency update failed"
                exit 1
            }
        fi

        while IFS= read -r file || [[ -n "$file" ]]; do
            file="$(trim_update_line "$file")"
            [[ -z "$file" || "$file" == ".env" ]] && continue

            if ! is_safe_update_path "$file"; then
                print_i18n_format update_error_text "unsafe path in update list: ${file}"
                exit 1
            fi

            mkdir -p "$(dirname "${CUSTODES_HOME}/${file}")" || {
                print_i18n_format update_error_text "cannot create target path for ${file}"
                exit 1
            }

            mv -f "${temp_dir}/${file}" "${CUSTODES_HOME}/${file}" || {
                print_i18n_format update_error_text "cannot replace ${file}"
                exit 1
            }
        done < "$update_list_path"

        cp "$update_list_path" "${CUSTODES_HOME}/${UPDATE_LIST_FILE}" || {
            print_i18n_format update_error_text "cannot save ${UPDATE_LIST_FILE}"
            exit 1
        }

        [[ -f "${CUSTODES_HOME}/custodes.sh" ]] && chmod 755 "${CUSTODES_HOME}/custodes.sh"

        rm -rf "$temp_dir"
        trap - EXIT

        print_i18n_format update_success_text "$version_now" "$version_server"
        exit 0
        ;;

    "config"|"-cfg")
        nano ~/.local/share/custodes/.env
        ;;

    "uninstall"|"-un")
        print_i18n uninstall_confirm_text
        read -r confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

        print_i18n uninstall_confirm_again_text
        read -r confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

        print_i18n uninstall_support_confirm_text
        read -r confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0


        rm -rf ~/.local/share/custodes/ ~/.local/bin/custodes || {
            print_i18n uninstall_error_text
            exit 1
        }

        print_i18n uninstall_success_text
        exit 0
        ;;

    "about"|"-a")
        print_i18n about_text
        exit 0
        ;;

    *)
        print_i18n incorrect_input_text
        exit 1
        ;;
esac
