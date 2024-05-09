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
  "dependencyDashboard": true,
  "separateMajorReleases": true,
  "combinePatchMinorReleases": true,
  "ignoreUnstable": true,
  "prImmediately": true,
  "prHourlyLimit": null,
  "dockerMajor": true,
  "baseBranches": ["main", "master"],
  "labels": ["renovate"],
  "automerge": false,
  "pinDigests": true,
  "prConcurrentLimit": 3,
  "schedule": "0 10 * * 6",
  "timezone": "Europe/Warsaw"
}
```

- dependencyDashboard:  Enables the Dependency Dashboard feature, providing insights into your project's dependencies.
- separateMajorReleases: Creates separate pull requests for updates to major versions of dependencies.
- combinePatchMinorReleases: Combines updates for patch and minor versions into a single pull request.
- ignoreUnstable: Ignores updates to unstable versions of dependencies.
- prImmediately: Creates pull requests immediately after detecting updates.
- semanticPrefix: Specifies semantic prefixes for commit messages to categorize changes (e.g., "fix", "deps", "chore", "others").
- prHourlyLimit: Removes the hourly limit for creating pull requests.
- dockerMajor: Enables updates for major versions of Docker images.
- baseBranches: Specifies the branches Renovate should target for creating pull requests (e.g., "main", "master").
- labels: Applies labels to pull requests created by Renovate (e.g., "dependencies").
- automerge: Disables automatic merging of pull requests.
- pinDigests: Pins the digest of package registry contents to ensure consistent dependency installations.
- prConcurrentLimit: Limits the number of concurrent pull requests Renovate can create.
- schedule: Specifies the frequency and timing of checks for dependency updates using a cron-like syntax (e.g., "0 10 * * 6" for Saturdays at 10:00 AM).
- timezone: Specifies the timezone Renovate should use for scheduling.

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
