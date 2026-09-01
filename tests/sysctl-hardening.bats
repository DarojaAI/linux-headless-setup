#!/usr/bin/env bats
# tests/sysctl-hardening.bats
#
# Hermetic regression gate for the L2 kernel/network sysctl hardening
# drop-in written by scripts/optimize.sh. Parses the heredoc embedded
# in the script (no live VM required) and asserts deploy-headless.sh
# wires optimize.sh in between system.sh and security.sh.
#
# Refs:
#   - DarojaAI/linux-headless-setup issue #51 (part of epic #48)
#   - scripts/install-docker.sh writes /etc/sysctl.d/99-docker-forward.conf;
#     optimize.sh's 99-l2-hardening.conf sorts after it and wins on conflicts.

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
    OPTIMIZE="$REPO_ROOT/scripts/optimize.sh"
    DEPLOY="$REPO_ROOT/deploy-headless.sh"
}

@test "optimize.sh drops the 99-l2-hardening.conf heredoc with every L2 hardening key=value line" {
    run python3 <<PYEOF
import re, sys
with open("$OPTIMIZE") as f:
    raw = f.read()
m = re.search(r"cat >/etc/sysctl\.d/99-l2-hardening\.conf <<'EOF'\n(.*?)\nEOF", raw, re.DOTALL)
if not m:
    print("FAIL: could not locate 99-l2-hardening.conf heredoc", flush=True)
    raise SystemExit(1)
body = [line.strip() for line in m.group(1).splitlines() if line.strip() and not line.startswith("#")]
required = [
    "net.ipv4.tcp_syncookies=1",
    "net.ipv4.conf.all.rp_filter=1",
    "net.ipv4.conf.default.rp_filter=1",
    "net.ipv4.conf.all.accept_redirects=0",
    "net.ipv4.conf.default.accept_redirects=0",
    "net.ipv4.conf.all.secure_redirects=0",
    "net.ipv4.conf.default.secure_redirects=0",
    "net.ipv4.conf.all.send_redirects=0",
    "net.ipv4.conf.default.send_redirects=0",
    "net.ipv6.conf.all.accept_ra=0",
    "net.ipv6.conf.default.accept_ra=0",
    "net.ipv6.conf.all.accept_redirects=0",
    "net.ipv6.conf.default.accept_redirects=0",
    "kernel.randomize_va_space=2",
]
missing = [k for k in required if k not in body]
if missing:
    print(f"MISSING: {missing}", flush=True); raise SystemExit(1)
print(f"OK: {len(required)} hardening settings present in heredoc")
PYEOF
    [ "$status" -eq 0 ]
}

@test "deploy-headless.sh wires optimize.sh between system.sh and security.sh" {
    system_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/system\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
    optimize_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/optimize\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
    security_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/security\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
    [ -n "$system_line" ]
    [ -n "$optimize_line" ]
    [ -n "$security_line" ]
    [ "$system_line" -lt "$optimize_line" ]
    [ "$optimize_line" -lt "$security_line" ]
}

@test "existing deploy-headless-includes-install-helper.bats still passes (skipped when absent on this branch)" {
    local helper="$REPO_ROOT/tests/deploy-headless-includes-install-helper.bats"
    if [ ! -f "$helper" ]; then
        # Not tracked on this worktree's baseline (main); the parent runs
        # that test at integration time where it does exist.
        skip "deploy-headless-includes-install-helper.bats not present on this branch"
    fi
    run bats "$helper"
    [ "$status" -eq 0 ]
}