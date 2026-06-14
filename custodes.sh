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

else_text="
Incorrect input, please use \"custodes help\" to use the program correctly.
"

if ((  $# != 1  )); then
    echo "$else_text"
    exit 1
fi

if [[ $1 = "help" || $1 = "-h" ]]; then
    echo "$help_text"
    exit 0

elif [[ $1 = "init" || $1 = "-i" ]]; then

    git rev-parse --is-inside-work-tree > /dev/null 2>&1

    if (( $? != 0 )); then
        echo "Use \"custodes init\" in the git repository"
        echo "Use \"custodes help\" for see more"
        exit 1
    fi

    git_dir="$(git rev-parse --absolute-git-dir)"
    cd "$git_dir/hooks"

    if [[ -f "pre-commit" ]]; then
        echo "
The hooks folder already has a pre-commit script.
To avoid losing the script, delete it from the directory."
        exit 1
    fi

    echo "#!/bin/sh
custodes check" > pre-commit

    chmod 755 pre-commit

    if (( $? != 0 )); then
        echo "Error when granting pre-commit hook rights"
        echo "We recommend running \"custodes init\" with sudo"
        exit 1
    fi

    exit 0

elif [[ $1 = "check" || $1 = "-ch" ]]; then
    ~/.local/share/custodes/.venv/bin/python ~/.local/share/custodes/parser.py
    parser_code=$?
    exit "$parser_code"
    
elif [[ $1 = "status" || $1 = "-s" ]]; then
    exit 0

elif [[ $1 = "config" || $1 = "-cfg" ]]; then


    exit 0

elif [[ $1 = "uninstall" || $1 = "-u" ]]; then

    echo "Are you sure you want to delete Custodes? [y\n]"
    read confirmation
    if [[ $read = "y" ]];then
        echo "Are you REALLY sure you want to delete Custodes \-_-/?! [y\n]"
        read confirmation

        if [[ $read = "y" ]];then
            echo "OK, click y one last time 
if you don't like the product of the poor student 
who worked so hard on this utility...... 
[y\n]"
            read confirmation
            if [[ $read = "y" ]];then

                # Доделать надо

            else
                exit 0
            fi
        else
            exit 0
        fi
    else
        exit 0
    fi

elif [[ $1 = "about" || $1 = "-a" ]]; then
    echo "$about_text"
    exit 0

else
    echo "$else_text"
    exit 1
fi
