#!/bin/bash
# =============================================================================
# Headless Linux Setup — Main Orchestrator
# =============================================================================
# PURPOSE:  Configure a headless Ubuntu VM as an OpenClaw gateway host.
#           No GUI. No RDP. No desktop environment.
#
# USAGE:    ./deploy-headless.sh [--help]
#
# LAYER:    L2 (runs after terraform-hcloud-linux-vm L1 provisioning)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── CLI ──
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  Headless VM bootstrap for OpenClaw gateway hosts.

Options:
  --help       Show this help and exit

Environment:
  APP_USER     Service user to create (default: desktopuser)
EOF
	exit 0
fi

# ── Source library ──
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/scripts/lib.sh"

info "=== deploy-headless.sh starting ==="
info "Target user: $APP_USER"

# ── Run modular scripts in order ──
bash "$SCRIPT_DIR/scripts/system.sh"
bash "$SCRIPT_DIR/scripts/security.sh"
bash "$SCRIPT_DIR/scripts/runtimes.sh"
bash "$SCRIPT_DIR/scripts/user.sh"
# install-docker.sh installs Docker + writes /etc/docker/daemon.json +
# enables ip_forward via sysctl drop-in. Required for the OpenClaw agent
# sandbox (agents.defaults.sandbox.backend = "docker" in
# linux-desktop-seed). Must run AFTER user.sh (so APP_USER exists) and
# BEFORE monitoring.sh (so the docker daemon is up before node_exporter
# and friends probe it).
bash "$SCRIPT_DIR/scripts/install-docker.sh"
bash "$SCRIPT_DIR/scripts/monitoring.sh"
bash "$SCRIPT_DIR/scripts/install-openclaw-compact.sh"
bash "$SCRIPT_DIR/scripts/openclaw-prep.sh"

info "=== deploy-headless.sh complete ==="
