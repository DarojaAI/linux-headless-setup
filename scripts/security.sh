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
# Always ensure UFW is active — enforce state, not skip-on-apparent-presence
if ! ufw status | grep -q "^Status: active"; then
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
# ── SSH hardening (configurable) ──
# SSH_ACCESS_MODE controls how the deploy chain connects once cloud-init
# has finished. Permitted values:
#   - "desktopuser" (default) — PermitRootLogin `no`. The deploy driver
#     uses `desktopuser` for all post-cloud-init SSH, mirroring
#     linux-desktop-seed PR #1463. The deploy-driver side authenticates
#     as `desktopuser` via a separate SSH key shipped by
#     ~/.openclaw/deploy-keys/desktopuser_ed25519; root's authorized_keys
#     is untouched after the cloud-init pass.
#   - "root" (legacy fallback for envs where desktopuser setup has not yet
#     landed) — PermitRootLogin `prohibit-password`, matching the prior
#     cloud-init posture.
# The default can be overridden with SSH_ACCESS_MODE=root to keep the
# legacy path alive during migration windows. Idempotent re-render:
# the script replaces an existing PermitRootLogin line in-place rather
# than ap-pending a duplicate configuration fragment.
: "${SSH_ACCESS_MODE:=desktopuser}"

case "$SSH_ACCESS_MODE" in
	desktopuser) EXPECTED_PERMIT_ROOT="no" ;;
	root)        EXPECTED_PERMIT_ROOT="prohibit-password" ;;
	*) warn "Unrecognised SSH_ACCESS_MODE=$SSH_ACCESS_MODE; falling back to 'desktopuser'"
		SSH_ACCESS_MODE=desktopuser
		EXPECTED_PERMIT_ROOT="no" ;;
esac

if [ -f /etc/ssh/sshd_config ]; then
	info "Applying SSH hardening (mode=$SSH_ACCESS_MODE, target=PermitRootLogin $EXPECTED_PERMIT_ROOT)..."
	if grep -qE "^#?PermitRootLogin " /etc/ssh/sshd_config; then
		# Idempotent in-place replacement; re-running this script will
		# not produce duplicate PermitRootLogin fragments.
		sed -i -E "s|^#?PermitRootLogin .*|PermitRootLogin $EXPECTED_PERMIT_ROOT|" /etc/ssh/sshd_config
	else
		# No existing PermitRootLogin line — append under the SSH defaults.
		# `printf` rather than `cat <<EOF` so we do not depend on a heredoc
		# in `set -euo pipefail` here.
		printf '\nPermitRootLogin %s\n' "$EXPECTED_PERMIT_ROOT" >>/etc/ssh/sshd_config
	fi
	systemctl reload ssh >/dev/null 2>&1 || systemctl restart ssh || true
fi

info "Security hardening complete."
