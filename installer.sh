#!/bin/bash

readonly TARGET_DIR="${HOME}/.local/share/custodes"
readonly BIN_DIR="${HOME}/.local/bin"
readonly ENV_FILE="${TARGET_DIR}/.env"

selected_lang="eng"

select_language() {
   local language

   while true; do
      echo "Select Custodes language:"
      echo "1) English"
      echo "2) Russian"
      echo "[1/2, eng/ru]"
      read -r language

      case "$language" in
         ""|1|en|eng|EN|ENG|English|english)
            selected_lang="eng"
            return 0
            ;;
         2|ru|RU|rus|RUS|Russian|russian)
            selected_lang="ru"
            return 0
            ;;
         *)
            echo "Please enter 1, 2, eng or ru."
            ;;
      esac
   done
}

ensure_env_file() {
   if [[ -f "$ENV_FILE" ]]; then
      return 0
   fi

   if [[ -f "$SCRIPT_DIR/.env" ]]; then
      cp "$SCRIPT_DIR/.env" "$ENV_FILE"
   else
      touch "$ENV_FILE"
   fi
}

write_language_config() {
   local lang="$1"

   if grep -qE '^[[:space:]]*lang_custodes[[:space:]]*=' "$ENV_FILE"; then
      sed -i -E "s/^[[:space:]]*lang_custodes[[:space:]]*=.*/lang_custodes=${lang} # values: eng, ru/" "$ENV_FILE"
   else
      printf '\nlang_custodes=%s # values: eng, ru\n' "$lang" >> "$ENV_FILE"
   fi
}

echo "
   |\                 /|
   | \               / |
   |  \     /\      /  |
   |  /    /  \     \  |
   | /    / /\ \     \ |
   |/    / /()\ \     \|
   |\   / /____\ \    /|
   | \ /________\ \  / |
   |  /___________ \   |

Glad to see you ^_^
custodes needs to create a working directory in ~/.local/share/, as well as the availability of a python interpreter.
Do you give your consent to install the necessary components?
[yes\no]"

read -r confirmation
[[ $confirmation == @(yes|Yes|y|Y) ]] || exit 1

select_language

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR" || exit 1

mkdir -p "$TARGET_DIR"
(( $? != 0 )) && { echo "Error creating a working folder"; exit 1; }

if [[ "$SCRIPT_DIR" != "$TARGET_DIR" ]]; then
   cp custodes.sh parser.py messeges.py README.md requirements.txt files_to_update.txt "$TARGET_DIR/"
   (( $? != 0 )) && { echo "Error copying files to the working folder"; exit 1; }
fi

ensure_env_file
(( $? != 0 )) && { echo "Error creating the .env file"; exit 1; }

write_language_config "$selected_lang"
(( $? != 0 )) && { echo "Error saving language settings"; exit 1; }

cd "$TARGET_DIR" || exit 1


sudo apt install python3 python3-pip
(( $? != 0 )) && { echo "installation error - python3 and pip with sudo rights"; exit 1; }

python3 -m venv .venv
(( $? != 0 )) && { echo "Creation error .venv"; exit 1; }

source .venv/bin/activate
(( $? != 0 )) && { echo "Launch error .venv"; exit 1; }

pip install --upgrade pip -q
(( $? != 0 )) && { echo "Pip update error"; exit 1; }

pip install -r requirements.txt -q
(( $? != 0 )) && { echo "Dependency installation error via pip"; exit 1; }

deactivate



mkdir -p "$BIN_DIR"

echo "#!/bin/bash
\"${TARGET_DIR}/custodes.sh\" \"\$@\"" > "$BIN_DIR/custodes"
(( $? != 0 )) && { echo "Error creating a startup command"; exit 1; }

chmod 755 "$TARGET_DIR/custodes.sh"
(( $? != 0 )) && { echo "Error in granting script execution rights"; exit 1; }

chmod 755 "$BIN_DIR/custodes"
(( $? != 0 )) && { echo "Error in granting script execution rights"; exit 1; }

echo "Installation of Custodes is completed"

cd "$SCRIPT_DIR"
if [[ "$SCRIPT_DIR" != "$TARGET_DIR" ]];then

   echo "Do you want to delete the current git clone folder?
   [yes\no]"
   read -r confirmation
   [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

   cd ..
   rm -rf "$SCRIPT_DIR"
   echo "$SCRIPT_DIR deleted, installation completed"
fi


exit 0
