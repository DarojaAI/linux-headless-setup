#!/bin/bash
# runtimes.sh — Node.js 24, Python 3, basic toolchain
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
info "Starting runtime installation..."
# ── Node.js 24 (NodeSource) ──
# Pinned at major 24 to satisfy openclaw engine requirements:
# the currently-pinned openclaw version is 2026.7.x, which needs
# node >=22.22.3 <23 || >=24.15.0 <25 || >=25.9.0. We pick the 24
# line because it's the current LTS and meets the engine constraint
# with headroom for future openclaw bumps. The upgrade path handles
# existing VMs whose L2 setup pinned Node 22: purge the old
# nodejs + the old NodeSource repo, then add the 24.x repo.
NODE_MAJOR_REQUIRED=24
current_node_major="$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || true)"
if [ "${current_node_major:-}" != "$NODE_MAJOR_REQUIRED" ]; then
    if [ -n "${current_node_major:-}" ]; then
        info "Upgrading Node.js from ${current_node_major}.x to ${NODE_MAJOR_REQUIRED}.x..."
        # Drop the old NodeSource repo + the old nodejs package before
        # adding the new one. NodeSource's setup_24.x script writes
        # to the same /etc/apt/sources.list.d/nodesource.list path
        # nodesource 22 used, but only if no prior file exists; purging
        # first avoids an "E: repository 'https://deb.nodesource.com/
        # node_22.x nodistro InRelease' doesn't support architecture"
        # failure if both 22 and 24 sources coexist on a VM.
        apt-get purge -y nodejs npm 2>/dev/null || true
        rm -f /etc/apt/sources.list.d/nodesource.list
        apt-get update -qq || true
    else
        info "Installing Node.js ${NODE_MAJOR_REQUIRED}..."
    fi
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR_REQUIRED}.x" | bash -
    apt-get install -y --no-install-recommends nodejs
else
    info "Node.js ${NODE_MAJOR_REQUIRED} already installed: $(node -v)"
fi

# ── Python 3 + pip ──
apt_install python3
apt_install python3-pip
apt_install python3-venv

# Basic tools
apt_install jq
apt_install curl

# Upgrade pip
python3 -m pip install --upgrade pip --break-system-packages 2>/dev/null || python3 -m pip install --upgrade pip || true

info "Runtimes complete: Node $(node -v 2>/dev/null || echo 'N/A'), Python $(python3 --version)"
