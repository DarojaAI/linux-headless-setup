#!/bin/bash
# openclaw-prep.sh — Create dirs, set perms for OpenClaw Layer 3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting OpenClaw prep..."

# ── Directories ──
mkdir -p "$APP_HOME/.openclaw/scripts/maintenance"
mkdir -p "$APP_HOME/.openclaw/scripts/monitor"
mkdir -p "$APP_HOME/.openclaw/skills"
mkdir -p "$APP_HOME/.openclaw/config"
mkdir -p /usr/local/bin
mkdir -p /tmp/config
mkdir -p /etc/systemd/system

# ── Permissions ──
chown -R "$APP_USER:$APP_USER" "$APP_HOME/.openclaw"

info "OpenClaw prep complete."
