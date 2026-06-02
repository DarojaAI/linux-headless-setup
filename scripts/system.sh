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

# ── Timezone ──
# Use UTC explicitly (common for servers)
if [ -f /etc/localtime ] && [ "$(readlink -f /etc/localtime)" != "/usr/share/zoneinfo/UTC" ]; then
	info "Setting timezone to UTC..."
	timedatectl set-timezone UTC || true
fi

info "System baseline complete."
