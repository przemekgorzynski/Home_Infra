[![YAMLlint](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yamllint.yml/badge.svg)](https://github.com/przemekgorzynski/Home_Infra/actions/workflows/yamllint.yml)
# Home_Infra
Home infrastructure configuration

# Prerequisites

- Install Bitwarden CLI

    `https://bitwarden.com/help/cli/`

- Install OS packages
    - sshpass
    - ansible

- Genrate Bitwarden API key and export as env variable (Account Settings -> Security -> Keys -> API Key)
    ```
    export BW_CLIENTID=username
    export BW_CLIENTSECRET=password
    ```

# Renovate Configuration

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "enabled": true,
  "dependencyDashboard": true,
  "ignoreUnstable": true,
  "ignoreDeprecated": true,
  "prHourlyLimit": 10,
  "baseBranches": ["main"],
  "labels": ["renovate"],
  "automerge": false,
  "pinDigests": true,
  "prConcurrentLimit": 3,
  "prCreation": "immediate",
  "separateMajorMinor": true,
  "separateMinorPatch": true,
  "schedule": "0 10 * * 6",
  "timezone": "Europe/Warsaw"
}
```

- schema: Specifies the JSON schema to validate the Renovate configuration file against.
- enabled: Indicates whether Renovate is enabled for the project.
- dependencyDashboard: This option enables a dashboard or interface to view the status of dependencies and their updates.
- ignoreUnstable: If set to true, Renovate will ignore unstable versions of dependencies when considering updates.
- ignoreDeprecated: If set to true, Renovate will ignore deprecated versions of dependencies when considering updates.
- prHourlyLimit: Sets the maximum number of pull requests (PRs) that Renovate will create per hour.
- baseBranches: Specifies the branches Renovate should target for creating pull requests.
- labels: Labels to be applied to the pull requests created by Renovate.
- automerge: If set to true, Renovate will automatically merge pull requests when all checks pass.
- pinDigests: If set to true, Renovate will use dependency digests to pin dependency versions, ensuring exact reproducibility.
- prConcurrentLimit: Sets the maximum number of concurrent pull requests that Renovate will create.
- prCreation: Specifies when Renovate should create pull requests. In this case, it's set to "immediate", meaning it will create them as soon as updates are available.
- separateMajorMinor: If set to true, Renovate will separate updates for major version changes.
- separateMinorPatch: If set to true, Renovate will separate updates for minor and patch version changes.
- schedule: Sets a schedule for when Renovate should check for updates and create pull requests. 
- timezone: Specifies the timezone used for scheduling Renovate tasks.

# BitWarden unlock

```
bw login --apikey
```

```
bw unlock
```

```
export BW_SESSION=XXXXX
```

# Base Config

```
ansible-playbook -i inventory.yml base_config.yml 
```
