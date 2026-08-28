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
# ── Sudo with bounded allowlist (R4 mitigation) ──
# Default allowlist: apt + systemctl. Driven by SUDO_ALLOWLIST (space-
# separated absolute paths). Override with SUDO_ALLOWLIST="/abs/path1 /abs/path2"
# when additional commands are needed, but each addition must be reviewed.
# Empty allowlist collapses to "!ALL" rather than "ALL" — the deploy driver
# gets nothing on the box by default. The full-sudo shape ("ALL") is the
# legacy fallback (SUDO_ALLOWLIST=all) for environments still transitioning.
: "${SUDO_ALLOWLIST:=apt-get systemctl}"

if [ "$SUDO_ALLOWLIST" = "all" ]; then
	SUDO_RULE_LINE="$APP_USER ALL=(ALL) NOPASSWD:ALL"
	info "Granting legacy full-sudo (SUDO_ALLOWLIST=all); legacy mode"
elif [ -z "$SUDO_ALLOWLIST" ]; then
	SUDO_RULE_LINE="$APP_USER ALL=(ALL) NOPASSWD:!ALL"
	info "Granting bare allowlist ($SUDO_ALLOWLIST); legacy bare"
else
	# Build a comma-separated sudoers-allowlist fragment. Each token
	# becomes a fully-qualified /usr/bin/<token> entry; bare names are
	# accepted with that resolver. Override SUDO_ALLOWLIST with absolute
	# paths for production.
	SUDO_FRAGMENT=""
	for cmd in $SUDO_ALLOWLIST; do
		case "$cmd" in
			/*) SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }$cmd" ;;
			*)  SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }/usr/bin/$cmd" ;;
		esac
	done
	SUDO_RULE_LINE="$APP_USER ALL=(ALL) NOPASSWD: $SUDO_FRAGMENT"
	info "Granting bounded sudo: $SUDO_RULE_LINE"
fi

# Idempotent renderer. If the file already exists with the same line,
# don't rewrite; if it exists with a stale line, replace it. This mirrors
# the security.sh template-render pattern so migration is the same shape.
SUDOERS_FILE="/etc/sudoers.d/$APP_USER"
if [ -f "$SUDOERS_FILE" ]; then
	if [ "$(cat "$SUDOERS_FILE")" = "$SUDO_RULE_LINE" ]; then
		info "$APP_USER sudoers entry already matches; no rewrite"
	else
		info "$APP_USER sudoers entry has stale content; rewriting"
		printf '%s\n' "$SUDO_RULE_LINE" >"$SUDOERS_FILE"
		chmod 440 "$SUDOERS_FILE"
	fi
else
	printf '%s\n' "$SUDO_RULE_LINE" >"$SUDOERS_FILE"
	chmod 440 "$SUDOERS_FILE"
fi

# ── Ensure .ssh dir exists ──
mkdir -p "$APP_HOME/.ssh"
chmod 700 "$APP_HOME/.ssh"
chown "$APP_USER:$APP_USER" "$APP_HOME/.ssh"

info "User setup complete."
