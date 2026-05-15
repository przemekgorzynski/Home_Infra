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
echo "Load secrets from .env"

if [ -f ".env" ]; then
    set -a
    # shellcheck source=.env
    source .env
    set +a
else
    echo "ERROR: .env file not found!"
    exit 1
fi

REQUIRED_VARS=(
    "ARGOCD_ADMIN_PASS"
    "CLOUDFLARE_API_TOKEN"
    "SAMBA_PASSWORD_PRZEMEK"
)

MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING+=("$var")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: Missing required environment variables:"
    for var in "${MISSING[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

echo ""
echo "##################### STEP 5 ##############################"

# Check if a tag argument was passed to the script
if [ -n "$1" ]; then
    echo "Running with tag: $1"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass --tags "$1"
else
    echo "Running all tasks (no tags specified)"
    ansible-playbook -i os_cfg_inventory.yml os_cfg_playbook.yml --ask-become-pass
fi
