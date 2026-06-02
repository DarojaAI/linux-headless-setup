# linux-headless-setup

Headless Ubuntu VM bootstrap for OpenClaw gateway hosts. No GUI, no RDP, no desktop bloat.

Used as Layer 2 in the DarojaAI provisioning stack:
- **L1:** `terraform-hcloud-linux-vm` — VM provisioning
- **L2:** this repo — OS configuration
- **L3:** `linux-desktop-seed` + `openclaw-gateway` — orchestration + agent

## What It Installs

- Base packages: curl, git, jq, tmux, build-essential
- Security: UFW, fail2ban, unattended-upgrades, SSH hardening
- Runtimes: Node.js 22, Python 3 + pip
- Monitoring: Prometheus node_exporter, logrotate, persistent journald
- User: `desktopuser` with passwordless sudo

## What It Does NOT Install

- GNOME, GDM, or any display manager
- XRDP, X11, Wayland
- GUI applications
- OpenClaw session monitor (no xrdp to monitor)

## Usage

```bash
./deploy-headless.sh
```

## Structure

```
├── deploy-headless.sh          # Main entrypoint
├── scripts/
│   ├── lib.sh                  # Common functions
│   ├── system.sh               # Apt update, base packages
│   ├── security.sh             # Firewall, fail2ban, SSH
│   ├── runtimes.sh             # Node.js, Python
│   ├── user.sh                 # Service user setup
│   ├── monitoring.sh           # node_exporter, logrotate
│   └── openclaw-prep.sh        # Directory layout for L3
└── tests/
    └── validate-install.sh     # Smoke tests
```

## Design

- **Idempotent:** Safe to rerun
- **Modular:** Each script is independent
- **Minimal:** No GUI stack = less attack surface, less RAM, faster boots
