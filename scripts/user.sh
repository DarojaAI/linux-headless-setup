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
info "Ensuring passwordless sudo for $APP_USER"
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" >"/etc/sudoers.d/$APP_USER"
chmod 440 "/etc/sudoers.d/$APP_USER"

# ── Enable systemd linger for user manager (needed for --user services without login) ──
info "Ensuring systemd linger is enabled for $APP_USER"
loginctl enable-linger "$APP_USER" 2>/dev/null || true

# ── Ensure .ssh dir exists ──
mkdir -p "$APP_HOME/.ssh"
chmod 700 "$APP_HOME/.ssh"
chown "$APP_USER:$APP_USER" "$APP_HOME/.ssh"

info "User setup complete."
