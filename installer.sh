#!/bin/bash
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

read confirmation
[[ $confirmation == @(yes|Yes|y|Y) ]] || exit 1

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

mkdir -p ~/.local/share/custodes/
cp custodes.sh parser.py messeges.py README.md requirements.txt .env ~/.local/share/custodes/
(( $? != 0 )) && { echo "Error creating a working folder or copying files to it"; exit 1; }
cd ~/.local/share/custodes/


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



mkdir -p ~/.local/bin/

echo "#!/bin/bash
~/.local/share/custodes/custodes.sh \"\$@\"" > ~/.local/bin/custodes
(( $? != 0 )) && { echo "Error creating a startup command"; exit 1; }

chmod 755 ~/.local/share/custodes/custodes.sh
(( $? != 0 )) && { echo "Error in granting script execution rights"; exit 1; }

chmod 755 ~/.local/bin/custodes
(( $? != 0 )) && { echo "Error in granting script execution rights"; exit 1; }

echo "Installation of Custodes is completed"

cd "$SCRIPT_DIR"
if [[ ! ~/.local/share/custodes/ == "$SCRIPT_DIR" ]];then

   echo "Do you want to delete the current git clone folder?
   [yes\no]"
   read confirmation
   [[ $confirmation == @(yes|Yes|y|Y) ]] || exit 0

   cd ..
   rm -rf "$SCRIPT_DIR"
   echo "$SCRIPT_DIR deleted, installation completed"
fi


exit 0