# Home Infra

Ansible playbook for full provisioning of a home server running Ubuntu. Configures the OS, deploys [k3s](https://k3s.io) as a single-node Kubernetes cluster, and bootstraps [ArgoCD](https://argo-cd.readthedocs.io) which then manages all workloads via GitOps from the [ArgoCDApps](https://github.com/przemekgorzynski/ArgoCDApps) repository.

---

## What it does

| Role | Description |
|------|-------------|
| `user_mgmnt` | Creates admin user, sets up SSH keys, groups |
| `os_mgmnt` | System update, standard packages, Docker, hostname, timezone, SSH hardening |
| `samba` | Deploys Samba file server via Docker for LAN file sharing |
| `k3s` | Installs k3s single-node cluster |
| `argo_cd` | Installs ArgoCD via Helm, configures SSH repo credentials and admin password |
| `zfs` | ZFS pool and dataset setup (disabled by default) |

After ArgoCD is running, all further workload deployments are managed through the [ArgoCDApps](https://github.com/przemekgorzynski/ArgoCDApps) app-of-apps repo — no further Ansible runs needed for applications.

---

## Prerequisites

### Ubuntu 26+ — fix sudo before first run

Ubuntu 26 ships with `sudo-rs` as the default `sudo`, which is incompatible with Ansible's privilege escalation. Run this once after OS installation before executing the playbook:

```bash
ssh -t -i ~/.ssh/id_ed25519 <user>@<host> \
  "sudo update-alternatives --set sudo /usr/bin/sudo.ws"
```

Ubuntu 24 is not affected.

### Environment variables

Loaded from a `.env` file in the repo root. Copy and fill in before first run:

```bash
cp .env.example .env
```

| Variable | Description |
|----------|-------------|
| `ARGOCD_ADMIN_PASS` | ArgoCD admin password as a bcrypt hash |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token for DNS management |
| `SAMBA_PASSWORD_PRZEMEK` | Samba password for the `przemek` user |

The script validates all variables are set before running the playbook.

### Required SSH keys

| Key | Purpose |
|-----|---------|
| `~/.ssh/id_ed25519` | Ansible SSH access to hosts |
| `~/.ssh/argocd-repo-key` | ArgoCD SSH access to [ArgoCDApps](https://github.com/przemekgorzynski/ArgoCDApps) |

---

## Usage

```bash
# Run full playbook
./os_cfg.sh

# Run specific role by tag
./os_cfg.sh <tag>
```

Available tags: `user_mgmnt`, `os_mgmnt`, `k3s`, `argo`, `argocd`, `samba`, `zfs`, `ssh`

---

## ArgoCD

### Admin password

Stored as a bcrypt hash in `roles/argo_cd/files/ArgoCD_config.yml`. Generate a new hash:

```bash
python3 -c "import bcrypt; print(bcrypt.hashpw(b'<password>', bcrypt.gensalt(rounds=10)).decode())"
```

### Access

**Port-forward** (no ingress required):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
```

**Ingress** (once ingress controller is deployed via [ArgoCDApps](https://github.com/przemekgorzynski/ArgoCDApps)):

`https://argo.homebay.dev`

---

## ZFS Storage Layout

```
Pool: tank
├── vdev: mirror (2x 8TB, 1 disk fault tolerance)
│   ├── /dev/sda
│   └── /dev/sdb
└── vdev: cache (L2ARC read cache)
    └── /dev/nvme1n1

Datasets:
tank                         → /data
├── tank/photos              → /data/photos
├── tank/media               → /data/media
│   ├── tank/media/movies    → /data/media/movies
│   ├── tank/media/tv-series → /data/media/tv-series
│   └── tank/media/other     → /data/media/other
├── tank/files               → /data/files
├── tank/priv                → /data/priv
├── tank/public              → /data/public
└── tank/torrent             → /data/torrent
```

All datasets use `lz4` compression.

## Known issues

### Ubuntu 26 — sudo-rs incompatibility

See [Prerequisites](#ubuntu-26--fix-sudo-before-first-run) above.

### Samba healthcheck (dockurr/samba 4.23.5)

The image's built-in healthcheck uses `-U %` (space before `%`) and doesn't redirect stdin, causing `smbclient` to hang waiting for input and timeout. Overridden in the role with `-U%` and `< /dev/null`.
