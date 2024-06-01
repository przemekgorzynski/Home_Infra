[![YAML-lint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yaml-lint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yaml-lint.yml)
[![Ansible-lint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/ansible-lint.yml)
[![Dry-run](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/dry-run.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/dry-run.yml)
# Home_Infra
Home infrastructure configuration

# Prerequisites

- Install locally Bitwarden CLI

    `https://bitwarden.com/help/cli/`

- Install locally OS packages
    - ansible

- Genrate Bitwarden API key and export as env variable (Account Settings -> Security -> Keys -> API Key)
    ```
    export BW_CLIENTID=username
    export BW_CLIENTSECRET=password
    ```

- You have locally generated SSH key-pair and this key is uploaded to GitHub account - will be fetched during OS installation
# Server Instalation

During installation process install OpenSSH server and import ssh keys from your GitHub account. 

It will be used for ansible authentication.

<img src="docs/images/import_ssh.png" alt="alt text" width="600">

# Renovate

https://docs.renovatebot.com/configuration-options/

# BitWarden

```bash
bw login --apikey
```

```bash
bw unlock
```

```bash
bw sync
```

```bash
export BW_SESSION=XXXXX
```

# Playbooks

Install Ansible collection

```bash
ansible-galaxy collection install -r requirments.yml
```

## Base Config

```bash
ansible-playbook -i inventory.yml playbook_base_config.yml 
```

## Software config
```bash
ansible-playbook -i inventory.yml playbook_software_config.yml 
```

## Maintenance
```bash
ansible-playbook -i inventory.yml playbook_maintenance.yml 
```

