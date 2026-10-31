#!/bin/bash
# security.sh — Firewall, fail2ban, SSH hardening, auto-updates
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
# shellcheck source=ssh-hardening.sh
source "$SCRIPT_DIR/ssh-hardening.sh"

# SSH drop-in directory. L2 no longer writes an sshd drop-in (issue #52 —
# sshd limits are owned by L1, terraform-hcloud-linux-vm#9) but still
# retires the one it used to own. Overridable so the hermetic bats suite
# can point it at a temp dir; prod always uses /etc/ssh/sshd_config.d.
SSHD_CONFIG_DIR="${SSHD_CONFIG_DIR:-/etc/ssh/sshd_config.d}"

# ssh service name detection. Ubuntu 24.04+ ships `ssh.service`;
# Ubuntu 22.04 / Debian use `sshd.service`. The L2 deploy must work
# against either image, so detect the loaded unit name once and use
# it for every systemctl invocation. If neither is loaded the SSH
# reload / restart steps become no-ops; we log WARN once and continue.
SSHD_SERVICE=""
if systemctl list-unit-files ssh.service 2>/dev/null | awk '{print $1}' | grep -qx ssh.service; then
	SSHD_SERVICE="ssh.service"
elif systemctl list-unit-files sshd.service 2>/dev/null | awk '{print $1}' | grep -qx sshd.service; then
	SSHD_SERVICE="sshd.service"
fi
if [ -n "$SSHD_SERVICE" ]; then
	info "Detected SSH service: $SSHD_SERVICE"
else
	info "WARN: neither ssh.service nor sshd.service is loaded; SSH service-restart paths will no-op"
fi

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
		if [ -n "$SSHD_SERVICE" ]; then
			systemctl restart "$SSHD_SERVICE" || true
		fi
	else
		info "Root SSH is already restricted"
	fi

	# ── L2 SSH drop-in retirement (issue #52) ──
	# L2 previously wrote $SSHD_CONFIG_DIR/10-l2.conf with `MaxStartups
	# 3:50:10` (plus keepalives), which dropped unauthenticated connections
	# once three scanners filled the queue — CI runners hit
	# `kex_exchange_identification: read: Connection reset by peer`, 54
	# drops in 6 h on the test VM (2026-10-31). Ownership of sshd limits
	# moved to L1 (terraform-hcloud-linux-vm issue #9 → 09-sshd-limits.conf
	# with `MaxStartups 40:30:100`); sshd keeps the FIRST value it reads and
	# `Include` sits at the top of sshd_config, so an L2 10- drop-in would
	# shadow L1's 09- file. L2 therefore retires the drop-in it used to own
	# — rename (never silently delete; evidence preserved under a
	# `.retired-<UTC ts>` suffix), reload only when it existed, and fail
	# loud if the effective MaxStartups is still 3:50:10. MUST NOT
	# introduce any other sshd setting (keepalives included) — those belong
	# in L1's 09-sshd-limits.conf. The step lives in scripts/ssh-hardening.sh
	# (sourced above) so the hermetic bats suite can exercise it with fake
	# sshd/systemctl on PATH against temp dirs.
	l2_retire_sshd_dropin "$SSHD_SERVICE"
fi

info "Security hardening complete."
