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
# cd into $APP_HOME before the sudo'd `git config --global` call: the
# parent L2 process runs as root with cwd=/root, and sudo inherits cwd.
# git 2.45+ walks cwd looking for `.git`; on /root (mode 0700) the
# sudo'd user gets EACCES, which the pinned git 2.56.0 (PR #76, source
# build at /opt/git-2.56.0) treats as fatal "error reading '/root/.git'".
# The distro git 2.43.0 recovers by walking up to /, but 2.56.0 does not
# (observed in head deploy 37077954285). cd-ing to $APP_HOME places the
# probe under a directory desktopuser can traverse, so .git simply
# reports ENOENT and git continues.
#
# Supersedes the env-strip attempt in PR #78 — that fix addressed a
# hypothesized env-var leak that wasn't actually present (strace on the
# failing call shows no GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE in env).
# The real cause was cwd inheritance, not env inheritance.
if [ "$(sudo -u "$APP_USER" bash -c "cd '$APP_HOME' && git config --global user.email 2>/dev/null || echo")" != "agent@daroja.ai" ]; then
	info "Setting $APP_USER git identity → agent@daroja.ai"
	sudo -u "$APP_USER" bash -c "cd '$APP_HOME' && git config --global user.email 'agent@daroja.ai'"
	sudo -u "$APP_USER" bash -c "cd '$APP_HOME' && git config --global user.name 'Migration Agent'"
else
	info "$APP_USER git identity already set: agent@daroja.ai"
fi

# ── Merge root's authorized_keys into desktopuser (converging) ──
# The deploy workflow provides the SSH key as root; desktopuser must trust
# the same keys so subsequent deploy steps can connect. Converging merge
# (append-only, idempotent): previously this was copy-if-absent, which
# silently skipped once the file existed — so a stale/partial
# authorized_keys (e.g. a VM provisioned before the runner key was added)
# never received the runner key, and every desktopuser SSH failed auth
# (deploy runs 36969776882..37042071059). Now root keys are merged into
# desktopuser's authorized_keys on every L2 provision.
if [ -f /root/.ssh/authorized_keys ]; then
	install -d -m 700 -o "$APP_USER" -g "$APP_USER" "$APP_HOME/.ssh"
	[ -f "$APP_HOME/.ssh/authorized_keys" ] || install -m 600 -o "$APP_USER" -g "$APP_USER" /dev/null "$APP_HOME/.ssh/authorized_keys"
	chmod 600 "$APP_HOME/.ssh/authorized_keys"
	chown "$APP_USER:$APP_USER" "$APP_HOME/.ssh/authorized_keys"
	added=0
	while IFS= read -r key_line || [ -n "$key_line" ]; do
		[ -z "$key_line" ] && continue
		if ! grep -qF -- "$key_line" "$APP_HOME/.ssh/authorized_keys"; then
			printf '%s\n' "$key_line" >> "$APP_HOME/.ssh/authorized_keys"
			added=$((added + 1))
		fi
	done < /root/.ssh/authorized_keys
	if [ "$added" -gt 0 ]; then
		info "Merged ${added} key line(s) from root into $APP_USER authorized_keys"
	else
		info "$APP_USER authorized_keys up to date (no new keys from root)"
	fi
else
	warn "No /root/.ssh/authorized_keys found — desktopuser may not be reachable via SSH"
fi

info "User setup complete."
