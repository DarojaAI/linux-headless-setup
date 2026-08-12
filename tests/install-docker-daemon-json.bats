#!/usr/bin/env bats
# tests/install-docker-daemon-json.bats
#
# Regression gate for the daemon.json template embedded in
# scripts/install-docker.sh. Validates that the install script writes
# (or merges-in) the keys required for the OpenClaw agent sandbox to
# function correctly.
#
# Refs:
#   - docs/plans/2026-06-22-agent-test-broke-prod-recovery.md (Layer 2)
#   - research-orchestrator deploy run 31544671328 on ubuntu-8gb-hel1-1
#     ("Temporary failure resolving 'deb.debian.org'" + "WARNING: IPv4
#     forwarding is disabled. Networking will not work.")

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
    SCRIPT="$REPO_ROOT/scripts/install-docker.sh"
}

@test "install-docker.sh exists" {
    [ -f "$SCRIPT" ]
}

@test "install-docker.sh passes bash -n" {
    run bash -n "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-docker.sh passes shellcheck (--norc, to bypass repo's .shellcheckrc bug)" {
    command -v shellcheck >/dev/null || skip "shellcheck not installed"
    run shellcheck --norc -S error "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-docker.sh writes daemon.json with required keys" {
    # Extract the DAEMON_DEFAULTS block from the script using a Python
    # regex (more robust than sed line ranges; the block lives inside
    # DAEMON_DEFAULTS='{...}' and may have nested braces).
    run python3 <<PYEOF
import re, json
with open("$SCRIPT") as f:
    raw = f.read()
m = re.search(r"DAEMON_DEFAULTS='(\{.*?\})'", raw, re.DOTALL)
if not m:
    print("FAIL: could not locate DAEMON_DEFAULTS block", flush=True)
    raise SystemExit(1)
d = json.loads(m.group(1))
required = ["log-driver", "live-restore", "storage-driver", "userland-proxy",
            "iptables", "ip-forward", "ipv6-forwarding", "dns"]
missing = [k for k in required if k not in d]
if missing:
    print(f"MISSING: {missing}", flush=True); raise SystemExit(1)
if d["ip-forward"] is not True:
    print("ip-forward must be true", flush=True); raise SystemExit(2)
if d["ipv6-forwarding"] is not True:
    print("ipv6-forwarding must be true", flush=True); raise SystemExit(3)
dns = d["dns"]
if not isinstance(dns, list) or len(dns) < 2:
    print(f"dns must be a list with >=2 entries, got: {dns}", flush=True); raise SystemExit(4)
print(f"OK: defaults = {sorted(d.keys())}")
PYEOF
    [ "$status" -eq 0 ]
}

@test "install-docker.sh merges into existing daemon.json, does NOT skip" {
    # The pre-2026-08-12 script had:
    #   if [ ! -f "$DAEMON_JSON" ]; then ... else info '... not overwriting'; fi
    # which meant re-runs on existing daemon.json never added new fields
    # (dns, ip-forward, etc.). This regression gate ensures the new
    # behavior actually merges.
    run grep -E 'already exists; merging' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-docker.sh writes sysctl drop-in for ip_forward" {
    run grep -E 'SYSCTL_DROPIN=|ip_forward' "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-docker.sh does not use the old hardcoded ip-forward: false template" {
    # Old template had '"ip-forward": false' hardcoded. The new logic
    # should never write that value.
    if grep -q '"ip-forward": false' "$SCRIPT"; then
        echo "FAIL: script still contains hardcoded 'ip-forward: false'" >&2
        return 1
    fi
}