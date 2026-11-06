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
| `argo_cd` | Installs ArgoCD via Helm, configures SSH repo credentials and admin password, bootstraps External Secrets Operator's Bitwarden access token |
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

All secrets are fetched from Bitwarden Secrets Manager at runtime. Only one env var is required:

```bash
export BWS_ACCESS_TOKEN=<token>
```

| Secret | Purpose |
|--------|---------|
| `ARGOCD_SSH_PRIVATE_KEY` | SSH private key for ArgoCD repo access |
| `ARGOCD_SSH_PUBLIC_KEY` | SSH public key for ArgoCD repo access |
| `ARGOCD_ADMIN_PASS` | ArgoCD admin password (bcrypt hash) |
| `SAMBA_PASSWORD_PRZEMEK` | Samba password for `przemek` user |
| `ZFS_ENCRYPTION_KEY` | ZFS dataset encryption key |
| `ESO_BITWARDEN_ACCESS_TOKEN` | External Secrets Operator's Bitwarden access token |

### Required SSH keys

| Key | Purpose |
|-----|---------|
| `~/.ssh/id_ed25519` | Ansible SSH access to hosts |

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

Stored as a bcrypt hash in BWS (`ARGOCD_ADMIN_PASS`). Generate a new hash:

```bash
python3 -c "import bcrypt; print(bcrypt.hashpw(b'<password>', bcrypt.gensalt(rounds=10)).decode())"
```

### Access

**Port-forward** (no ingress required):

ArgoCD server runs with `server.insecure: true` (plain HTTP, no TLS inside the pod):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
# http://localhost:8080
```

**Ingress** (once ingress controller is deployed via [ArgoCDApps](https://github.com/przemekgorzynski/ArgoCDApps)):

`https://argo.homebay.dev`

### Metrics

Prometheus metrics are enabled for all ArgoCD components and exposed as ClusterIP services:

| Service | Port | Component |
|---------|------|-----------|
| `argocd-application-controller-metrics` | 8082 | App controller (sync status, health) |
| `argocd-server-metrics` | 8083 | API server |
| `argocd-repo-server-metrics` | 8084 | Repo server |
| `argocd-redis-metrics` | 9121 | Redis |

Port-forward to inspect metrics locally:

```bash
kubectl port-forward svc/argocd-server-metrics -n argocd 8083:8083
curl http://localhost:8083/metrics
```

---

## ZFS Storage Layout

```
Pool: tank
├── vdev: mirror (2x 8TB, 1 disk fault tolerance)
│   ├── /dev/sda
│   └── /dev/sdb
└── vdev: cache (L2ARC read cache)
    └── /dev/disk/by-id/nvme-WD_Red_SN700_500GB_<serial>

Datasets:
tank                         → /data
├── tank/photos              → /data/photos
├── tank/media               → /data/media
│   ├── tank/media/movies    → /data/media/movies
│   ├── tank/media/tv-series → /data/media/tv-series
│   ├── tank/media/other     → /data/media/other
│   └── tank/media/audio     → /data/media/audio
├── tank/files               → /data/files
├── tank/priv                → /data/priv
├── tank/public              → /data/public
└── tank/torrent             → /data/torrent

Pool: ssd
└── vdev: stripe (no redundancy)
    └── /dev/sdc

Datasets:
ssd                          → /data-ssd
└── ssd/torrent              → /data-ssd/torrent
```

All datasets use `lz4` compression.

### Physical disks

| Disk | Size | Usage |
|------|------|-------|
| `sda` | 8TB | `tank` mirror |
| `sdb` | 8TB | `tank` mirror |
| `sdc` | 1.8TB | `ssd` stripe |
| `sdd` | 3.6TB | **Unused** — not part of either pool |
| `nvme0n1` | ~1TB | OS boot disk (not ZFS) |
| `nvme1n1` | 500GB | `tank` L2ARC cache |

### Disk naming

Pool vdev disks are referenced by stable `/dev/disk/by-id/...` paths where possible instead of raw `/dev/nvmeXnY` names. NVMe device enumeration (`nvme0n1`, `nvme1n1`, ...) is not guaranteed stable across reboots, and a cache device once got silently reassigned to the OS boot disk's name after a reboot. SATA disk names (`sda`, `sdb`, `sdc`, `sdd`) are generally stable on this host but `by-id` is preferred for any new disk added to a pool.

### Checking pool/disk health

```bash
zpool status -v              # pool health, scrub/resilver state, cache device status
zpool list                   # capacity/fragmentation overview
sudo smartctl -H /dev/sda    # per-disk SMART health verdict
sudo smartctl -a /dev/sda    # full SMART attributes (reallocated/pending sectors, etc.)
```

## Known issues

### Ubuntu 26 — sudo-rs incompatibility

See [Prerequisites](#ubuntu-26--fix-sudo-before-first-run) above.
