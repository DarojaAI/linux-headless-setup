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
# NOTE: We do NOT disable root SSH here because CI/CD deploy pipelines
# need root access for subsequent deployments. The Terraform/Hetzner
# cloud-init already disables password auth, so root is key-only.
if [ -f /etc/ssh/sshd_config ]; then
	info "Applying light SSH hardening..."
	# Only ensure root login goes by key auth, not password
	# (Hetzner cloud-init already does this, but be explicit)
	if ! grep -qE "^#?PermitRootLogin (prohibit-password|without-password|no)" /etc/ssh/sshd_config; then
		info "Ensuring PermitRootLogin is set to prohibit-password"
		sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
		systemctl restart sshd || true
	else
		info "Root SSH is already restricted"
	fi
fi

info "Security hardening complete."
