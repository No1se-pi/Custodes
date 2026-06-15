#!/bin/bash

help_text="
CUSTODES — a mini security system for Git commits

Usage:
custodes <command> [options]

Commands:
help        Show Custodes help message
init        Install the pre-commit hook in the current Git repository
check       Scan staged files for possible secrets
status      Show Custodes status in the current repository
config      Show configuration path and current settings
uninstall   Remove the Custodes hook from the current repository
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

pre_commit_text="
The hooks folder already has a pre-commit script.
To avoid losing the script, delete it from the directory."

hook_rights_text="
Error when granting pre-commit hook rights
We recommend running \"custodes init\" with sudo"

custodes_init_text="
Use \"custodes init\" in the git repository
Use \"custodes help\" for see more"

incorrect_input_text="
Incorrect input, please use \"custodes help\" to use the program correctly.
"

success_hook_text="
custodes hook has been successfully installed in your repository.
If you want to delete it, use \"custodes uninstall\"
"

about_text="
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
WebSite - 

Project by - Yaroslav Boikov (No1se) ^-^
"


if ((  $# != 1  )); then
    echo "$else_text"
    exit 1
fi

case "$#" in

    "help"|"-h")
        echo "$help_text"
        exit 0
        ;;

    "init"|"-i")

        git rev-parse --is-inside-work-tree > /dev/null 2>&1

        if (( $? != 0 )); then
            echo "$custodes_init_text"
            exit 1
        fi

        git_dir="$(git rev-parse --absolute-git-dir)"
        cd "$git_dir/hooks"

        if [[ -f "pre-commit" ]]; then
            echo "$pre_commit_text"
            exit 1
        fi

        echo -e "#!/bin/sh\ncustodes check" > pre-commit

        chmod 755 pre-commit

        if (( $? != 0 )); then
            echo "$hook_rights_text"
            exit 1
        fi

        echo "$success_hook_text"
        exit 0
        ;;

    "check"|"-ch")
        ;;

    "status"|"-s")
        ;;

    "config"|"-cfg")
        ;;

    "uninstall"|"-u")
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