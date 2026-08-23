#!/bin/bash
# shellcheck disable=SC2148
# Common library for headless setup scripts
set -euo pipefail

# ── Logging ──
__log() {
	local level="$1"	shift
	local msg="$*"
	echo "[$(date -Iseconds)] [$level] $msg"
}

info() { __log "INFO" "$@"; }
warn() { __log "WARN" "$@"; }
error() { __log "ERROR" "$@"; }

# ── Error handling ──
# AGENTS.md anchor: 'Bash >= 5.3 is required for the deploy chain's
# set -euo pipefail + ERR trap + nested bash pattern'. On bash 5.2 the
# trap + `eval "$(pyenv init --path)"` combo SIGSEGVs; turn it into a
# no-op under bash 5.2 to surface a clean ERR rather than a silent
# segfault.
if [ "${BASH_VERSINFO[0]:-0}" -ge 5 ] && { [ "${BASH_VERSINFO[0]:-0}" -gt 5 ] || [ "${BASH_VERSINFO[1]:-0}" -ge 3 ]; }; then
    trap 'error "Script failed on line $LINENO (exit: $?)"' ERR
fi

# ── Idempotency helpers ──
package_installed() {
	dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

service_active() {
	systemctl is-active --quiet "$1" 2>/dev/null
}

apt_install() {
	local pkg="$1"
	if package_installed "$pkg"; then
		info "Package already installed: $pkg"
		return 0
	fi
	info "Installing: $pkg"
	apt-get install -y --no-install-recommends "$pkg"
}

# ── User ──
APP_USER="${APP_USER:-desktopuser}"
APP_HOME="/home/$APP_USER"

# Export so all scripts can use these variables
export APP_USER APP_HOME
