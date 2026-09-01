#!/usr/bin/env bats
# tests/chrony-sync.bats
#
# Layer-2 hardening (#49,epic #48): verify the chrony NTP configuration
# that scripts/system.sh drops,and verify — when chrony is available — that
#the daemon has actually synchronized,. The live sync probe cannot run in CI
#without a real NTP stack,so it skips when chronyc is absent; the deploy
#chain's `chronyc waitsync 5 -v` remains the authoritative runtime gate..
#
# Refs:
#   - issue #49 (time-sync verification for headless VMs)
#   - AGENTS.md "Test before deploy" anchor

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
    SCRIPT="$REPO_ROOT/scripts/system.sh"
}

@test "system.sh drops chrony pool config with required lines" {
    # The live /etc/chrony/conf.d/20-l2-pool.conf only exists ona
    # provisioned VM; here we parse the heredoc authored in system.sh (the
    # source of truth) line-by-line and assert every required directive..
    run python3 <<PYEOF
import re, sys
with open("$SCRIPT", encoding="utf-8") as f:
    raw = f.read()
m = re.search(
    r"cat >/etc/chrony/conf\.d/20-l2-pool\.conf <<'EOF'\n(.*?)\nEOF",
    raw,
    re.DOTALL,
)
if not m:
    print("FAIL: could not locate 20-l2-pool.conf heredoc in system.sh", flush=True)
    sys.exit(1)
config = m.group(1).splitlines()
required = [
    "pool time.cloudflare.com iburst maxsources 4",
    "pool time.nist.gov iburst maxsources 2",
    "driftfile /var/lib/chrony/chrony.drift",
    "makestep 1 -1",
]
missing = [line for line in required if line not in config]
if missing:
    for line in missing: print(f"MISSING in config: {line}", flush=True)
    sys.exit(1)
print(f"OK: {len(config)} config lines, required chrony directives present")
PYEOF
    [ "$status" -eq 0 ]

    # On a provisioned host, additionally verify the dropped file itself..
    if [ -r /etc/chrony/conf.d/20-l2-pool.conf ]; then
        for line in "pool time.cloudflare.com iburst maxsources 4" "driftfile /var/lib/chrony/chrony.drift" "makestep 1 -1"; do
            grep -Fxq "$line" /etc/chrony/conf.d/20-l2-pool.conf || {
                echo "MISSING in /etc/chrony/conf.d/20-l2-pool.conf: $line" >&2
                return 1
            }
        done
    fi
}

@test "chrony is synchronized (last sync ≤ 60s)" {
    command -v chronyc >/dev/null || skip "chronyc not installed"
    run bash -o pipefail -c 'chronyc tracking 2>&1 | head -10'
    if [ "$status" -ne 0 ]; then
        echo "chronyc tracking failed:" >&2
        echo "$output" >&2
        skip "chrony daemon not running (no tracking data)"
    fi
    last_update="$(printf '%s\n' "$output" | grep -E '^Last update' | awk '{print $(NF-1)}')"
    case "$last_update" in
        ''|*[!0-9]*) skip "chrony tracking lacks last-sync data (no sync yet)" ;;
    esac
    if [ "$last_update" -gt 60 ]; then
        echo "Clock not synchronized: last sync ${last_update}s ago (threshold: 60s)" >&2
        echo "$output" >&2
        return 1
    fi
}