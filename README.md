[![YAMLlint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yamllint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yamllint.yml)
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

- You have locally generated SSh key-pair and this key is uploaded to GitHub account - will be fetched during OS installation
# Server Instalation

During installation process install OpenSSH server and import ssh keys from your GitHub account. 

It will be used for ansible authentication.

<img src="docs/images/import_ssh.png" alt="alt text" width="600">

# Renovate

https://docs.renovatebot.com/configuration-options/

Local test command
```bash
sudo apt install renovate
LOG_LEVEL=info renovate --platform=local --repository-cache=reset
```

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "enabled": true,
  "dependencyDashboard": true,
  "ignoreUnstable": true,
  "ignoreDeprecated": true,
  "prHourlyLimit": 10,
  "prConcurrentLimit": 3,
  "prCreation": "immediate",
  "assignees": ["przemekgorzynski"],
  "baseBranches": ["main", "/^renovate.*/"],
  "labels": ["renovate"],
  "automerge": false,
  "separateMajorMinor": true,
  "separateMinorPatch": true,
  "schedule": "* 10 * * 6",
  "timezone": "Europe/Warsaw",
  "pinDigests": true,
  "enabledManagers": [
    "custom.regex",
    "github-actions",
    "dockerfile"
  ],
  "customManagers": [
    {
      "customType": "regex",
      "description": "update _IMAGE versions in Ansible inventory",
      "fileMatch": ["^inventory.yml$"],
      "matchStrings": [
        ".*_image: (?<depName>\\S+)\\n\\s+.*_image_tag: (?<currentValue>\\S+)\\n\\s+image_digest: (?<currentDigest>sha256:[a-f0-9]+)"
      ],
      "datasourceTemplate": "docker",
      "versioningTemplate": "docker"
    }
  ]
}
```

# BitWarden unlock

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

# Base Config

```bash
ansible-galaxy collection install -r requirments.yml
```

```bash
ansible-playbook -i inventory.yml playbook_base_config.yml 
```

# Software config
```bash
ansible-playbook -i inventory.yml playbook_software_config.yml 
```
