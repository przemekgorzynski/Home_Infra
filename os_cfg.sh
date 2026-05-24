#!/bin/bash
set -e
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

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
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    rm -rf "$VENV_DIR"
    if ! "$PYTHON_BIN" -m venv "$VENV_DIR" 2>/dev/null; then
        PYTHON_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        echo "Installing python${PYTHON_VERSION}-venv..."
        sudo apt-get install -y "python${PYTHON_VERSION}-venv"
        "$PYTHON_BIN" -m venv "$VENV_DIR"
    fi
fi
# shellcheck source=.venv/bin/activate
source "$VENV_DIR/bin/activate"

if ! python -m pip --version &>/dev/null; then
    echo "Bootstrapping pip..."
    python -m ensurepip --upgrade
fi

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

TAG="$1"
shift || true
EXTRA_ARGS="$*"

if [ -n "$TAG" ]; then
    echo "Running with tag: $TAG $EXTRA_ARGS"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass --tags "$TAG" $EXTRA_ARGS
else
    echo "Running all tasks (no tags specified)"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass $EXTRA_ARGS
fi
