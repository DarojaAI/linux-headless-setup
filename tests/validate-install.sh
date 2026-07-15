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
check "ssh installed" bash -c 'test -f /usr/sbin/sshd'
check "curl installed" command -v curl
check "git installed" command -v git
check "jq installed" command -v jq
check "node installed (v22 or v24)" bash -c 'node -v | grep -qE "^v(22\.|24\.)"'
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

# ── Docker (for OpenClaw agent sandbox) ──
# Ref: docs/plans/2026-06-22-agent-test-broke-prod-recovery.md (Layer 2).
# Without these, the openclaw runtime's docker backend fails at
# agent-execution time with a permission error — silent failure.
check "docker installed" command -v docker
check "docker daemon running" systemctl is-active docker
check "docker daemon reachable" bash -c 'docker info >/dev/null 2>&1'
check "desktopuser in docker group" bash -c 'id -nG desktopuser | tr " " "\n" | grep -qx docker'
# Smoke test as desktopuser (simulating agent runtime). The openclaw
# runtime will fail with EACCES if this fails — catch it at install time.
check "docker reachable as desktopuser" bash -c 'su -s /bin/bash desktopuser -c "sg docker -c \"docker info >/dev/null 2>&1\""'
# Daemon config we wrote in install-docker.sh — explicit so an apt
# upgrade can't silently change behavior.
check "daemon.json present" test -f /etc/docker/daemon.json
check "daemon.json has journald log driver" bash -c 'grep -q "\"log-driver\": \"journald\"" /etc/docker/daemon.json'
check "daemon.json has userland-proxy=false" bash -c 'grep -q "\"userland-proxy\": false" /etc/docker/daemon.json'

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi
