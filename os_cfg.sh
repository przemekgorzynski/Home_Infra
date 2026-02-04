#!/bin/bash
set -e

echo ""
echo "##################### STEP 1 ##############################"
echo "Detect Python interpreter"

# Prefer Python 3.11 if available
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
echo "Upgrade pip and install Ansible"
sudo "$PYTHON_BIN" -m pip install --upgrade pip

echo ""
echo "##################### STEP 3 ##############################"
echo "Install Ansible collections"
ansible-galaxy collection install -r requirements.yml

echo ""
echo "##################### STEP 4 ##############################"

if [ -z "${DOPPLER_SERVICE_TOKEN}" ]; then
    echo "DOPPLER_SERVICE_TOKEN is not set."
    echo "export DOPPLER_SERVICE_TOKEN=<< REDACTED >>"
else
    echo "DOPPLER_SERVICE_TOKEN is set. Running Ansible playbook..."

    # Check if a tag argument was passed to the script
    if [ -n "$1" ]; then
        echo "Running with tag: $1"
        ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass --tags "$1"
    else
        echo "Running all tasks (no tags specified)"
        ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass
    fi
fi
