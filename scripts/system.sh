#!/bin/bash
# system.sh — Base OS configuration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Local minimal logging helpers (no lib.sh dependency — see install-openclaw-compact.sh
# in the same commit range for why sourcing lib.sh + ERR trap segfaults bash 5.2/5.3).
info()  { echo "[$(date -Iseconds)] [INFO]  $*"; }
warn()  { echo "[$(date -Iseconds)] [WARN]  $*"; }
error() { echo "[$(date -Iseconds)] [ERROR] $*"; }
package_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
apt_install() {
	local pkg="$1"
	if package_installed "$pkg"; then
		info "Package already installed: $pkg"
		return 0
	fi
	info "Installing: $pkg"
	apt-get install -y --no-install-recommends "$pkg"
}

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

# ── Timezone ──
# Use UTC explicitly (common for servers)
if [ -f /etc/localtime ] && [ "$(readlink -f /etc/localtime)" != "/usr/share/zoneinfo/UTC" ]; then
	info "Setting timezone to UTC..."
	timedatectl set-timezone UTC || true
fi

info "System baseline complete."
