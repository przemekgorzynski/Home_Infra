#!/bin/bash

echo ""
echo "##################### STEP 1 ##############################"
echo "Install ansible and python"
sudo apt install ansible-core python3-pip

echo ""
echo "##################### STEP 2 ##############################"
echo "Install ansible collectons"
ansible-galaxy collection install -r requirments.yml

echo ""
echo "##################### STEP 3 ##############################"
echo "Install Bitwarden sdk"
pip install bitwarden-sdk --break-system-packages

echo ""
echo "##################### STEP 4 ##############################"
if [ -z "${BWS_ACCESS_TOKEN}" ]; then
    echo "BWS_ACCESS_TOKEN is not set."
    echo "export BWS_ACCESS_TOKEN=<< REDACTED >>"
else
    echo "BWS_ACCESS_TOKEN is set. Running Ansible playbook..."
    ansible-playbook -i inventory.yml playbook_base_config.yml --ask-become-pass
fi
