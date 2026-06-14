#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

mkdir -p ~/.local/share/custodes/
cp custodes.sh parser.py messeges.py README.md requirements.txt .env-exemple ~/.local/share/custodes/
if (( $? != 0 ));then
    echo "Error creating a working folder or copying files to it"
    exit 1
fi
cd ~/.local/share/custodes/

python3 -m venv .venv
if (( $? != 0 ));then
    echo "Creation error .venv"
    exit 1
fi
source .venv/bin/activate
if (( $? != 0 ));then
    echo "Launch error .venv"
    exit 1
fi
pip install --upgrade pip -q
if (( $? != 0 ));then
    echo "Pip update error"
    exit 1
fi
pip install -r requirements.txt -q
if (( $? != 0 ));then
    echo "Dependency installation error via pip"
    exit 1
fi
deactivate

mkdir -p ~/.local/bin/

echo "#!/bin/bash
~/.local/share/custodes/custodes.sh \"\$@\"" > ~/.local/bin/custodes
if (( $? != 0 ));then
    echo "Error creating a startup command"
    exit 1
fi

chmod 755 ~/.local/share/custodes/custodes.sh
if (( $? != 0 ));then
    echo "Error in granting script execution rights"
    exit 1
fi
chmod 755 ~/.local/bin/custodes
if (( $? != 0 ));then
    echo "Error in granting script execution rights"
    exit 1
fi

echo "Installation of Custodes is completed"
exit 0