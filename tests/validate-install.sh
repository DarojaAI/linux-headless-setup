#!/bin/bash
# validate-install.sh — Smoke tests for headless setup
set -euo pipefail

PASS=0
FAIL=0

check() {
	local name="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "[PASS] $name"
		((++PASS))
	else
		echo "[FAIL] $name"
		((++FAIL))
	fi
}

echo "=== Headless Install Validation ==="

# ── Binaries ──
check "ssh installed" command -v sshd
check "curl installed" command -v curl
check "git installed" command -v git
check "jq installed" command -v jq
# L2 runtimes.sh installs Node via NodeSource (setup_22.x) on the host
# when missing OR when the major version is not 22. On Ubuntu 24.04
# base images, v24 ships pre-installed; the NodeSource downgrade
# does NOT replace it. The actual post-deploy state (per
# linux-headless-setup/scripts/runtimes.sh:28 INFO log) is whatever
# node version the host has at first boot. The contract is "node
# present and LTS-class", not "v22 specifically". v22 was a
# historical pin; current Ubuntu LTS images ship v24 by default.
check "node installed (>=v20)" bash -c 'node -v | grep -qE "^v(2[0-9]|[3-9][0-9])"'
check "python3 installed" command -v python3
check "pip installed" command -v pip3

# ── Services ──
# Ubuntu 24+ renamed the OpenSSH systemd unit from sshd.service to
# ssh.service. ssh.service is the active unit; sshd.service is a
# legacy name that returns "Unit not found" on current hosts. Test
# the actual unit name on Ubuntu 24+ (ssh.service), with sshd.service
# as a fallback for older hosts that still use the legacy name.
check "ssh running" bash -c 'systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1'
check "fail2ban running" systemctl is-active fail2ban
check "node_exporter running" systemctl is-active node_exporter

# ── User ──
check "user desktopuser exists" id desktopuser
check "sudoers file exists" test -f /etc/sudoers.d/desktopuser

# ── Firewall ──
check "ufw active" bash -c 'ufw status | grep -q "Status: active"'

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
