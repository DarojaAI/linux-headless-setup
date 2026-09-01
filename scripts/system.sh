#!/bin/bash
# system.sh — Base OS configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting system baseline..."

# ── Apt ──
info "Updating package lists..."
apt-get update -y

info "Installing base packages..."
apt_install curl
apt_install jq
apt_install git
apt_install tmux
apt_install unzip
apt_install ca-certificates
apt_install apt-transport-https
apt_install gnupg
apt_install software-properties-common
apt_install build-essential
apt_install htop
apt_install ncdu
apt_install tree

# ── Time sync (chrony) ──
# Layer-2 hardening (#49,epic #48): silent clock drift has broken TLS
# validation (cert "not yet valid"/"not anymore valid") and auth against
# OpenRouter/Discord/S3. chrony is preferred over systemd-timesyncd for
# accuracy; `chronyc waitsync` makes sync an explicit bootstrap invariant,
# so a flaky metadata NTP resolver fails loudly here instead of silently
# drifting during pip/pnpm TLS handshakes..
info "Installing chrony (NTP daemon)..."
apt_install chrony

mkdir -p /etc/chrony/conf.d
cat >/etc/chrony/conf.d/20-l2-pool.conf <<'EOF'
pool time.cloudflare.com iburst maxsources 4
pool time.nist.gov iburst maxsources 2
driftfile /var/lib/chrony/chrony.drift
makestep 1 -1
EOF

systemctl enable --now chrony

info "Verifying NTP synchronization (waitsync)..."
chronyc waitsync 5 -v

# ── Timezone ──
# Use UTC explicitly (common for servers)
if [ -f /etc/localtime ] && [ "$(readlink -f /etc/localtime)" != "/usr/share/zoneinfo/UTC" ]; then
	info "Setting timezone to UTC..."
	timedatectl set-timezone UTC || true
fi

info "System baseline complete."
