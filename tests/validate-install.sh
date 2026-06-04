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
		((PASS++)) || true
	else
		echo "[FAIL] $name"
		((FAIL++)) || true
	fi
}

echo "=== Headless Install Validation ==="

# ── Binaries ──
check "ssh installed" command -v sshd
check "curl installed" command -v curl
check "git installed" command -v git
check "jq installed" command -v jq
check "node installed (v22)" bash -c 'node -v | grep -q "^v22"'
check "python3 installed" command -v python3
check "pip installed" command -v pip3

# ── Services ──
check "sshd running" systemctl is-active sshd
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
