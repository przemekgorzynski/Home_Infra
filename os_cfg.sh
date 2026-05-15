#!/bin/bash
set -e

echo ""
echo "##################### STEP 1 ##############################"
echo "Detect Python interpreter"

if [ -x "/opt/homebrew/bin/python3.11" ]; then
    PYTHON_BIN="/opt/homebrew/bin/python3.11"
elif [ -x "/usr/bin/python3.11" ]; then
    PYTHON_BIN="/usr/bin/python3.11"
elif [ -x "/usr/bin/python3" ]; then
    PYTHON_BIN="/usr/bin/python3"
else
    echo "ERROR: No suitable Python found!"
    exit 1
fi

echo "Using Python: $PYTHON_BIN"
"$PYTHON_BIN" --version

echo ""
echo "##################### STEP 2 ##############################"
echo "Create/activate virtual environment"

VENV_DIR=".venv"
if [ ! -d "$VENV_DIR" ]; then
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi
# shellcheck source=.venv/bin/activate
source "$VENV_DIR/bin/activate"

echo ""
echo "##################### STEP 3 ##############################"
echo "Install Ansible"
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

echo ""
echo "##################### STEP 4 ##############################"
echo "Install Ansible collections"
ansible-galaxy collection install -r requirements.yml

echo ""
echo "##################### STEP 5 ##############################"
echo "Load environment and check Bitwarden token"

if [ -f ".env" ]; then
    set -a
    # shellcheck source=.env
    source .env
    set +a
fi

if [ -z "${BWS_ACCESS_TOKEN}" ]; then
    echo "ERROR: BWS_ACCESS_TOKEN is not set."
    echo "Set it in .env or export BWS_ACCESS_TOKEN=<token>"
    exit 1
fi

echo ""
echo "##################### STEP 6 ##############################"

if [ -n "$1" ]; then
    echo "Running with tag: $1"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass --tags "$1"
else
    echo "Running all tasks (no tags specified)"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass
fi
