#!/bin/bash
# openclaw-prep.sh — Create dirs, set perms for OpenClaw Layer 3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Local minimal logging helpers (no lib.sh dependency — see install-openclaw-compact.sh
# in the same commit range for why sourcing lib.sh + ERR trap segfaults bash 5.2/5.3).
info()  { echo "[$(date -Iseconds)] [INFO]  $*"; }
warn()  { echo "[$(date -Iseconds)] [WARN]  $*"; }
error() { echo "[$(date -Iseconds)] [ERROR] $*"; }

# ── User defaults (replaces lib.sh's APP_USER/APP_HOME export) ──
APP_USER="${APP_USER:-desktopuser}"
APP_HOME="/home/$APP_USER"
export APP_USER APP_HOME

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
