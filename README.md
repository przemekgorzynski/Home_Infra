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