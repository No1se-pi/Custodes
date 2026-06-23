#!/bin/bash

selected_lang=$(grep -o -E "ru|eng" "${HOME}/.local/share/custodes/.env" | head -n 1)
selected_lang=${selected_lang:-eng}

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
vesion_error_text_eng='Your Custodes version is outdated! $version_now
Do you want to launch an update?
[yes\no]'

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
vesion_error_text_ru='Ваша версия Custodes устарела! $version_now
Вы хотите запустить обновление?
[yes/no]'

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

#___________code___________

if ((  $# != 1  )); then
    v="incorrect_input_text_$selected_lang"; echo "${!v}"
    exit 1
fi

case "$1" in

    "help"|"-h")
        v="help_text_$selected_lang"; echo "${!v}"
        exit 0
        ;;

    "init"|"-i")

        git rev-parse --is-inside-work-tree > /dev/null 2>&1
        (( $? != 0 )) && { v="custodes_init_text_$selected_lang"; echo "${!v}"; exit 1; }

        git_dir="$(git rev-parse --absolute-git-dir)"
        cd "$git_dir/hooks"

        if [[ -f "pre-commit" ]]; then
            v="pre_commit_text_$selected_lang"; echo "${!v}"
            exit 1
        fi

        echo -e "#!/bin/sh\ncustodes check" > pre-commit

        chmod 755 pre-commit
        (( $? != 0 )) && { v="hook_rights_text_$selected_lang"; echo "${!v}"; exit 1; }

        v="success_hook_text_$selected_lang"; echo "${!v}"
        exit 0
        ;;
    
    "remove"|"-r")
        git rev-parse --is-inside-work-tree > /dev/null 2>&1
        (( $? != 0 )) && { v="custodes_remove_text_$selected_lang"; echo "${!v}"; exit 1; }

        git_dir="$(git rev-parse --absolute-git-dir)"
        cd "$git_dir/hooks"

        echo "Are you sure you want to delete Custodes from this repository? 0_-\n[yes\no]"
        read confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0        

        rm -f pre-commit || { v="custodes_init_text_$selected_lang"; echo "${!v}"; exit 1; }
        
        echo "Custodes removed from $git_dir"
        exit 0
        ;;

    "check"|"-ch")
        ~/.local/share/custodes/.venv/bin/python ~/.local/share/custodes/parser.py
        parser_code=$?
        exit "$parser_code"
        ;;

    "status"|"-s")
        cd ~
        version_now=$(grep "Version" "${HOME}/.local/share/custodes/README.md" | awk '{print $NF}' | tr -d '.')
        version_server=$(curl -sSL "https://raw.githubusercontent.com/No1se-pi/Custodes/refs/heads/main/README.md" | grep "Version" | awk '{print $NF}' | tr -d '.')

        if (( $version_now < $version_server ));then
            eval "v="version_error_text_$selected_lang"; echo "${!v}" "
            exit 1
        else
            echo "The latest version of Custodes is installed $version_now"
            exit 0
        fi
        ;;

    "update"|"-up")
        custodes status
        (( $? == 0 )) && { echo "The latest version of Custodes is installed $version_now"; exit 0; }

        # Инициализируем пути (тильда без кавычек работает правильно)
        TARGET_DIR=~/.local/share/custodes
        TEMP_DIR="$TARGET_DIR/temp"

        # Создаем структуру папок, если её нет (-p предотвратит ошибку, если папки существуют)
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR" || exit 1

        # 1. Скачиваем список файлов
        curl -sSL "https://raw.githubusercontent.com/No1se-pi/Custodes/refs/heads/main/files_to_download.txt" > files_to_download.txt

        # 2. Читаем список и скачиваем каждый файл во временную папку
        while IFS= read -r file || [ -n "$file" ]; do
            # Пропускаем пустые строки, если они есть в файле
            [ -z "$file" ] && continue
            
            echo "Скачиваю $file..."
            curl -sSL "https://raw.githubusercontent.com/No1se-pi/Custodes/refs/heads/main/$file" -o "$file"
        done < files_to_download.txt

        echo "custodes update does not touch .env, in order to avoid conflicts,\nwe recommend comparing .env.exemple in the file README.md"

        # 3. Переносим скачанные файлы на один уровень выше (в целевую папку)
        while IFS= read -r file || [ -n "$file" ]; do
            [ -z "$file" ] && continue
            
            # -f перезапишет старые файлы новыми без лишних вопросов
            mv -f "$file" "$TARGET_DIR/$file"
        done < files_to_download.txt

        # 4. Возвращаемся назад и безопасно удаляем временную папку
        cd "$TARGET_DIR" || exit 1
        rm -rf "$TEMP_DIR"

        # 5. Запуск инсталлятора
        bash ~/.local/share/custodes/installer.sh
        ;;

    "config"|"-cfg")
        nano ~/.local/share/custodes/.env
        ;;

    "uninstall"|"-un")
        echo "Are you sure you want to remove Custodes from your system?\n[yes\no]"
        read confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

        echo "Are you REALLY sure you want to delete Custodes? 0_-\n[yes\no]"
        read confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

        echo "Well, click "yes" if you don't mind the work of a student from Russia and you don't want to support him.
        ＞︿＜\n[yes\no]"
        read confirmation
        [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0


        rm -rf ~/.local/share/custodes/ ~/.local/bin/custodes || {
            echo "Error deleting Custodes folders sudo rights may be required.\nThe system itself does not want to delete the program..."
            exit 1
        }

        echo "All system folders of the Custodes program have been deleted ＞﹏＜\nbye........"
        exit 0
        ;;

    "about"|"-a")
        echo "$about_text"
        exit 0
        ;;

    *)
        echo "$incorrect_input_text"
        exit 1
        ;;
esac