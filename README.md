# Home Infra

Ansible-based configuration for home infrastructure hosts.

## Prerequisites

### Ubuntu 26+ — fix sudo before first run

Ubuntu 26 ships with `sudo-rs` as the default `sudo`, which is incompatible with Ansible's privilege escalation. Switch to traditional sudo once after OS installation:

```bash
ssh -t -i ~/.ssh/id_ed25519 <user>@<host> "sudo update-alternatives --set sudo /usr/bin/sudo.ws"
```

This only needs to be done once per host. Ubuntu 24 is not affected.

## Usage

```bash
export BWS_ACCESS_TOKEN=<token>
./os_cfg.sh            # run all tasks
./os_cfg.sh <tag>      # run specific tag
```
