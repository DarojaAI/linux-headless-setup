#!/usr/bin/env bats
# tests/journald-caps.bats
#
# Regression gate for the journald size/rate cap drop-in installed by
# scripts/monitoring.sh (issue #50, epic #48).
#
# The pre-#50 script sed-flipped a bare `Storage=persistent` into
# /etc/systemd/journald.conf, leaving the daemon on default SystemMaxUse
# (~15% of disk), no MaxRetentionSec`, and RateLimitBurst=1000 — footguns
# on a small VM. The fix installs a drop-in at
# /etc/systemd/journald.conf.d/99-l2-caps.conf that owns Storage= AND also
# sets the size/rate caps.

# All assertions are hermetic: they validate the drop-in content embedded
# in the script (the exact bytes that get dropped to disk) and the install
# commands — no root, systemd, or live VM required.

setup() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/journald-caps.bats}")/.." && pwd)"
    SCRIPT="$REPO_ROOT/scripts/monitoring.sh"
}

@test "monitoring.sh drop-in contains all documented journald caps" {
    # Extract the drop-in heredoc from the script and assert every [Journal]
    # key=value line matches the documented spec exactly.
    run python3 - "$SCRIPT" <<'PYEOF'
import sys

expected = {
    "Storage": "persistent",
    "SystemMaxUse": "2G",
    "SystemKeepFree": "500M",
    "MaxRetentionSec": "30day",
    "RateLimitIntervalSec": "10s",
    "RateLimitBurst": "200",
    "ForwardToSyslog": "no",
    "ForwardToWall": "no",
}

with open(sys.argv[1]) as f:
    lines = f.read().splitlines()

start = None
for i, line in enumerate(lines):
    if "99-l2-caps.conf" in line and "<<'EOF'" in line:
        start = i
        break
if start is None:
    print("FAIL: drop-in heredoc not found in monitoring.sh", flush=True)
    raise SystemExit(1)

end = None
for i in range(start + 1, len(lines)):
    if lines[i] == "EOF":
        end = i
        break
if end is None:
    print("FAIL: drop-in heredoc terminator 'EOF' not found", flush=True)
    raise SystemExit(1)

content = lines[start + 1:end]
if not content or content[0] != "[Journal]":
    print(f"FAIL: drop-in must start with [Journal], got {content[:1]!r}", flush=True)
    raise SystemExit(1)
if content.count("[Journal]") != 1:
    print(f"FAIL: drop-in must contain exactly one [Journal] header, got {content.count('[Journal]')}", flush=True)
    raise SystemExit(1)

got = {}
for line in content:
    if line == "[Journal]":
        continue
    if "=" in line:
        key, _, value = line.partition("=")
        got[key] = value
    elif line.strip():  # any other non-empty, non-key line is drift
        print(f"FAIL: unexpected line in drop-in: {line!r}", flush=True)
        raise SystemExit(1)

if got != expected:
    print(f"FAIL: drop-in keys={got!r}, expected {expected!r}", flush=True)
    raise SystemExit(1)

print(f"OK: drop-in has all {len(expected)} [Journal] keys with documented values")
PYEOF
    [ "$status" -eq 0 ]
}

@test "monitoring.sh drop-in owns Storage= (no bare flip into /etc/systemd/journald.conf)" {
    # The old block sed-flipped `Storage=persistent` into the main config
    # file. A bare key there would now conflict with the drop-in;; the drop-in
    # must be the only place Storage= is written. Assert the install path
    # no longer does the bare flip (hermetic: checks script content, not a
    # live /etc file, so no root/VM needed).
    if grep -nE 'sed[[:space:]]+.*journald\.conf|echo[[:space:]]+.*Storage=persistent.*journald\.conf' "$SCRIPT"; then
        echo "FAIL: bare Storage= flip into /etc/systemd/journald.conf still present" >&2
        return 1
    fi
    # Belt-and-braces: `Storage=persistent` appears exactly once — inside
    # the drop-in heredoc only.
    [ "$(grep -c 'Storage=persistent' "$SCRIPT")" -eq 1 ]
}

@test "monitoring.sh pins drop-in mode 0644" {
    # `cat >` create the file with umask-dependent permissions;; the script
    # explicitly pins 0644 after writing so the deployed drop-in is
    # world-readable but not group/world-writable. (Hermetic: asserts
    # the install command, not a live file.)
    grep -qE '^chmod 0644 /etc/systemd/journald\.conf\.d/99-l2-caps\.conf$' "$SCRIPT"
}