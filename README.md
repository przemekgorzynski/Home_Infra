[![YAML-lint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/YAML-lint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/YAML-lint.yml)
[![Ansible-lint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/Ansible-lint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/Ansible-lint.yml)
[![Dry-Run](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/Dry-Run.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/Dry-Run.yml)
# Home_Infra
Home infrastructure configuration

# Prerequisites

- Install locally Bitwarden CLI

    `https://bitwarden.com/help/cli/`

- Install locally OS packages
    - ansible

- Install Ansible collections

    ```bash
    ansible-galaxy collection install -r requirments.yml
    ``` 

- Genrate Bitwarden API key and export as env variable (Account Settings -> Security -> Keys -> API Key)
    ```
    export BW_CLIENTID=username
    export BW_CLIENTSECRET=password
    ```

- You have locally generated SSH key-pair and this key is uploaded to GitHub account - will be fetched during OS installation
# Remote Server Instalation

During remote server installation install "OpenSSH server" and import ssh keys from your GitHub account. 

It will be used for ansible authentication.

<img src="docs/images/import_ssh.png" alt="alt text" width="600">


# External tools

## Renovate

Renovate tools check docker images definition inside `inventory.yml` file and checks for new releases available. If found creates PR.

It's configuration stored in `.github/renovate.json` file.  
Official docs:  
https://docs.renovatebot.com/configuration-options/

## BitWarden

All secrets passed into playbooks are fetchec from Bitwarden secret manager. In order to make it available need to execute following steps before playbooks execution.

```bash
bw login [--apikey]
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

# Deploying

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

# Testing

All following tests are implemented and executed in Github Actions pipelines.

## Lint

Check before pushing lints pass, as this will be check in pipeline
```
pip3 install yamllint ansible-lint
```

```
yamllint  -c .github/yamllint .
```
```
ansible-lint
```

## Dry-run

Deploy software stack locally.

```bash
ansible-playbook -i inventory.yml tests/playbook_dry_run.yml
```

Test local software deployment.
```
ansible-playbook -i inventory.yml tests/playbook_test.yml
```

Testing pipeline runs against each container and return it's status:

```yml
    GENERAL:
      Name: JELLYFIN
      State: RUNNING
      Image: linuxserver/jellyfin:10.9.3@sha256:8c02cf2b830fd770e270e8947a5232a15cd860c53fb15c10e2773e16548156e8
      Restarting: False
      Error:
    HTTP:
      Endpoint: HTTP://LOCALHOST:8096/WEB/#/WIZARDSTART.HTML
      Code: 200
    HEALTHCHECK:
      Status: HEALTHY
      Failing: 0
```