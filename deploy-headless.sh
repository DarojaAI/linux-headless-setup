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

# ── Handoff setup: copy root SSH key to APP_USER so subsequent steps use APP_USER SSH ──
# This must happen BEFORE security.sh disables root SSH.
# The GitHub runner will use APP_USER SSH for all post-deploy steps.
if [ "$APP_USER" != "root" ]; then
	info "Setting up SSH handoff: copying root authorized_keys to $APP_USER"
	mkdir -p "/home/$APP_USER/.ssh"
	chmod 700 "/home/$APP_USER/.ssh"
	cp /root/.ssh/authorized_keys "/home/$APP_USER/.ssh/authorized_keys" 2>/dev/null || \
		cat /root/.ssh/authorized_keys > "/home/$APP_USER/.ssh/authorized_keys"
	chmod 600 "/home/$APP_USER/.ssh/authorized_keys"
	chown -R "$APP_USER:$APP_USER" "/home/$APP_USER/.ssh"
	chown -R "$APP_USER:$APP_USER" "/home/$APP_USER"
	info "SSH handoff complete — /home/$APP_USER now accessible via SSH"
fi

# ── Run modular scripts in order ──
bash "$SCRIPT_DIR/scripts/system.sh"
bash "$SCRIPT_DIR/scripts/security.sh"
bash "$SCRIPT_DIR/scripts/runtimes.sh"
bash "$SCRIPT_DIR/scripts/user.sh"
bash "$SCRIPT_DIR/scripts/monitoring.sh"
bash "$SCRIPT_DIR/scripts/openclaw-prep.sh"

info "=== deploy-headless.sh complete ==="
