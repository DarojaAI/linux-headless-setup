#!/bin/bash
# runtimes.sh — Node.js 22, Python 3, basic toolchain
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting runtime installation..."

# ── Node.js 22 (NodeSource) ──
if ! command -v node &>/dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" != "22" ]; then
	info "Installing Node.js 22..."
	curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
	apt-get install -y --no-install-recommends nodejs
else
	info "Node.js 22 already installed: $(node -v)"
fi

# ── Python 3 + pip ──
apt_install python3
apt_install python3-pip
apt_install python3-venv

# Upgrade pip
python3 -m pip install --upgrade pip --break-system-packages 2>/dev/null || python3 -m pip install --upgrade pip || true

info "Runtimes complete: Node $(node -v 2>/dev/null || echo 'N/A'), Python $(python3 --version)"
