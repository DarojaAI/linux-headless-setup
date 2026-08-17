#!/bin/bash
# shellcheck disable=SC2148
# Common library for headless setup scripts.
#
# NOTE: bash ≥ 5.3 is required for the deploy chain's
# `set -euo pipefail + ERR trap + nested bash` pattern that the prior
# version of this file used. Ubuntu 24.04 ships bash 5.2 by default,
# which segfaults (rc=139) when this library's trap fires inside an
# SSH-dispatched subshell. PR #86de02c and #7723a26 fixed the same
# class for `install-openclaw-compact.sh`; this file (the shared lib
# the orchestrator and every modular script source) is the structural
# backstop and drops the trap here so the class can't recur.

# ── Logging ── 不色用 set -euo pipefail，因为这会在
# nested bash + ERR trap combination 下触发 SIGSEGV on bash 5.2/5.3.
__log() {
	local level="$1"
	shift
	local msg="$*"
	echo "[$(date -Iseconds)] [$level] $msg"
}

info() { __log "INFO" "$@"; }
warn() { __log "WARN" "$@"; }
error() { __log "ERROR" "$@"; }

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
