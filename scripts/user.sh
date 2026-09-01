#!/bin/bash
# user.sh — Service user, sudo, SSH layout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting user setup (user=$APP_USER)..."

# ── Create user ──
if ! id "$APP_USER" &>/dev/null; then
	info "Creating user: $APP_USER"
	useradd -m -s /bin/bash "$APP_USER"
else
	info "User already exists: $APP_USER"
fi

# ── Sudo without password ──
if [ ! -f "/etc/sudoers.d/$APP_USER" ]; then
	info "Granting passwordless sudo to $APP_USER"
	echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/$APP_USER"
	chmod 440 "/etc/sudoers.d/$APP_USER"
fi

# ── Ensure .ssh dir exists ──
mkdir -p "$APP_HOME/.ssh"
chmod 700 "$APP_HOME/.ssh"
chown "$APP_USER:$APP_USER" "$APP_HOME/.ssh"

# ── git identity (issue #F, ledger) ──
# Closes the class where deploy scripts that call `git commit` inside
# the VM fall back to operator name when the agent committer-email is
# unset (same shape as the linux-desktop-seed bypass / identity-bleed
# PR-to-PR class that closed via PR #1528 / #1528).
if [ "$(sudo -u "$APP_USER" git config --global user.email 2>/dev/null || echo)" != "agent@daroja.ai" ]; then
	info "Setting $APP_USER git identity → agent@daroja.ai"
	sudo -u "$APP_USER" git config --global user.email "agent@daroja.ai"
	sudo -u "$APP_USER" git config --global user.name "Migration Agent"
else
	info "$APP_USER git identity already set: agent@daroja.ai"
fi

# ── Copy root's authorized_keys so CI can SSH as desktopuser ──
# The deploy workflow provides the SSH key as root; we need desktopuser
# to have the same key so subsequent deploy steps can connect.
if [ -f /root/.ssh/authorized_keys ]; then
	if [ ! -f "$APP_HOME/.ssh/authorized_keys" ]; then
		info "Copying root authorized_keys to $APP_USER"
		cp /root/.ssh/authorized_keys "$APP_HOME/.ssh/authorized_keys"
		chmod 600 "$APP_HOME/.ssh/authorized_keys"
		chown "$APP_USER:$APP_USER" "$APP_HOME/.ssh/authorized_keys"
	else
		info "$APP_USER already has authorized_keys"
	fi
else
	warn "No /root/.ssh/authorized_keys found — desktopuser may not be reachable via SSH"
fi

info "User setup complete."
