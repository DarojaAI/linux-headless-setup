#!/bin/bash
# security.sh — Firewall, fail2ban, SSH hardening, auto-updates
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting security hardening..."

# ── Firewall ──
if ! command -v ufw &>/dev/null; then
	info "Installing UFW..."
	apt-get install -y --no-install-recommends ufw
fi

info "Configuring UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh || true
# Only enable if not already active — avoids hanging on interactive prompt
if ! ufw status | grep -q "Status: active"; then
	ufw --force enable
fi

# ── fail2ban ──
apt_install fail2ban

info "Configuring fail2ban..."
# Minimal config: protect SSH
cat >/etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

systemctl restart fail2ban || true
systemctl enable fail2ban

# ── Unattended upgrades ──
apt_install unattended-upgrades

dpkg-reconfigure -plow unattended-upgrades -f noninteractive || true

# ── SSH hardening (light) ──
# NOTE: We do NOT disable root login here. Hetzner cloud-init sets
# PermitRootLogin prohibit-password by default, which is sufficient.
# The deploy workflow relies on root SSH for L3 orchestration.
# linux-desktop-setup follows the same pattern — no sshd_config changes.
if [ -f /etc/ssh/sshd_config ]; then
	info "Skipping root login hardening — deploy workflow requires root SSH"
fi

info "Security hardening complete."
