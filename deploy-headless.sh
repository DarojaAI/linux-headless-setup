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
# ── L2 sysctl hardening ──
# optimize.sh MUST run before any sysctl-networking-side deployment
#(e.g. Docker's ip_forward drop-in / firewalling): its
# 99-l2-hardening.conf sorts numerically last among /etc/sysctl.d/*.conf,
# so it wins any conflicts with Hetzner cloud-init defaults.
bash "$SCRIPT_DIR/scripts/optimize.sh"
bash "$SCRIPT_DIR/scripts/security.sh"
bash "$SCRIPT_DIR/scripts/runtimes.sh"
bash "$SCRIPT_DIR/scripts/user.sh"
# install-docker.sh installs Docker + writes /etc/docker/daemon.json +
# enables ip_forward via sysctl drop-in. Required for the OpenClaw agent
# sandbox (agents.defaults.sandbox.backend = "docker" in
# linux-desktop-seed). Must run AFTER user.sh (so APP_USER exists) and
# BEFORE monitoring.sh (so the docker daemon is up before node_exporter
# and friends probe it).
# BUG-CLASS: bash 5.2.21 + lib.sh ERR trap segfaults under `set -euo pipefail`
# exit 139. Route through /opt/bash-5.3/bin/bash which we built on the VM
# during the 2026-08-14 SIGSEGV investigation. Falls back to system bash
# with a warning if /opt/bash-5.3 isn't present (the gate inside
# install-openclaw-compact.sh itself will abort cleanly if so).
if [ -x /opt/bash-5.3/bin/bash ]; then
  BASH=/opt/bash-5.3/bin/bash
else
  warn "/opt/bash-5.3/bin/bash not found, falling back to system bash (compaction install may segfault)"
  BASH=bash
fi
"$BASH" "$SCRIPT_DIR/scripts/install-docker.sh"
"$BASH" "$SCRIPT_DIR/scripts/monitoring.sh"
"$BASH" "$SCRIPT_DIR/scripts/install-openclaw-compact.sh"
"$BASH" "$SCRIPT_DIR/scripts/openclaw-prep.sh"
# install-runtime-seam-binaries.sh installs the bash binaries that
# linux-desktop-seed's verify-vm-state.sh and runtime-build-finish.sh
# call into at deploy time. Same bash-5.3 routing as the other gated
# calls (lib.sh ERR-trap SIGSEGV class). MUST run LAST: openclaw-prep.sh
# leaves the user-systemd path ready, and the contract-shape smoke at
# the bottom of the install helper wants the runtime wired up. Wire-
# compat with the L3a fallback library (linux-desktop-seed#1428) is
# verified by the install helper's parseable-JSON assertion — a fall-
# through with non-parseable JSON would surface as install-helper
# exit 1, which `set -e` propagates here as a deploy failure. Don't
# reorder this without re-reading docs/contracts/L2-RUNTIME-CLI.md.
"$BASH" "$SCRIPT_DIR/scripts/install-runtime-seam-binaries.sh"
echo "→ install-login-policy.sh"
"$BASH" "$SCRIPT_DIR/scripts/install-login-policy.sh"

info "=== deploy-headless.sh complete ==="
