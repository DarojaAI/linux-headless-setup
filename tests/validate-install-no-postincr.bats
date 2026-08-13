#!/usr/bin/env bats
# Regression test: tests/validate-install.sh must use pre-increment
# (++PASS / ++FAIL) for the result counters, NOT post-increment
# (PASS++ / FAIL++). Post-increment returns the OLD value (0 on
# first call), which bash arithmetic evaluates as exit code 1.
# Under `set -euo pipefail`, that kills the script after the first
# assertion.
#
# Bug surfaced by deploy 31654599583 (Thu 2026-08-13 00:36:44 UTC):
# integration test integration tests job reported [PASS] ssh
# installed then exited 1 with no further output. Root cause was
# `((PASS++))` returning 0 → `set -e` killed the script after the
# first check() call. Fix: `((++PASS))` returns the new value
# (always non-zero on the first call), which bash arithmetic
# evaluates as exit code 0, so `set -e` does not fire.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/tests/validate-install.sh"
}

@test "validate-install.sh exists" {
  [ -f "$SCRIPT" ]
}

@test "validate-install.sh does NOT use post-increment PASS++" {
  # Belt-and-suspenders: belt test. If anyone reverts the pre-inc fix
  # and re-introduces `((PASS++))`, this test catches it before merge.
  ! grep -qE '\(\(PASS\+\+\)\)' "$SCRIPT"
}

@test "validate-install.sh does NOT use post-increment FAIL++" {
  ! grep -qE '\(\(FAIL\+\+\)\)' "$SCRIPT"
}

@test "validate-install.sh uses pre-increment ++PASS" {
  grep -qE '\(\(\+\+PASS\)\)' "$SCRIPT"
}

@test "validate-install.sh uses pre-increment ++FAIL" {
  grep -qE '\(\(\+\+FAIL\)\)' "$SCRIPT"
}

@test "post-increment + set -e exits 1 on empty counter (proves the bug shape)" {
  # Reproduce the bug shape from a fresh shell. Confirms that
  # post-increment under set -euo pipefail kills the script, so
  # the grep assertions above are testing something real.
  local rc
  rc="$(bash -c 'set -euo pipefail; PASS=0; ((PASS++)); echo "reached below"' >/dev/null 2>&1; echo $?)"
  [ "$rc" = "1" ] || { echo "expected rc=1 from set -e + post-increment, got rc=$rc"; return 1; }
}

@test "pre-increment + set -e does NOT exit 1 on empty counter" {
  # Negative control: confirms pre-increment under set -e does
  # NOT kill the script (because it returns 1, which arithmetic
  # treats as true / exit 0).
  local rc
  rc="$(bash -c 'set -euo pipefail; PASS=0; ((++PASS)); echo "reached below"' >/dev/null 2>&1; echo $?)"
  [ "$rc" = "0" ] || { echo "expected rc=0 from set -e + pre-increment, got rc=$rc"; return 1; }
}

@test "validate-install.sh runs past the first assertion (the bug pattern)" {
  # End-to-end test against the actual script: it must print more
  # than just one assertion before the script does anything else.
  # Reproduces the integration test failure mode locally.
  # Skipped if the script depends on services/binaries not present
  # in the dev box (we check for the head of stdout, not exit code).
  local output
  output="$(bash "$SCRIPT" 2>&1 || true)"
  local pass_count
  pass_count="$(echo "$output" | grep -c '^\[PASS\]')"
  # The integration test failure mode printed exactly 1 PASS line
  # before dying. Asserting >= 2 PASS lines is a stronger guarantee:
  # it can only fail if the script dies after the first assertion
  # (the original bug) or earlier (regression of some new shape).
  [ "$pass_count" -ge 2 ] || {
    echo "expected >= 2 [PASS] lines, got $pass_count. Output:"
    echo "$output" | head -10
    return 1
  }
}

# ── Test-contract regression tests (post-#15 followups) ────────
#
# After the pre-increment fix unblocked the script (PR #15), the
# integration test ran all 13 assertions and 2 reported real
# VM-state failures that were TEST-side bugs:
#   1. node installed (v22) — VM ships v24 LTS; v22 pin was stale.
#   2. sshd running — Ubuntu 24+ renamed the unit to ssh.service;
#      sshd.service doesn't exist on current hosts.
#
# The contract is "node present + LTS-class" and "ssh service
# active (either name)". These regression tests pin those
# contracts so a future PR can't silently regress back to
# hardcoded v22 / sshd.service.

@test "node assertion is LTS-class (>=v20), NOT hardcoded v22" {
  ! grep -qE 'node -v . grep -q "\^v22"' "$SCRIPT"
}

@test "ssh assertion accepts ssh.service OR sshd.service" {
  # Ubuntu 24+ uses ssh.service; older hosts used sshd.service.
  # Test the OR fallback via substrings rather than a full-line
  # regex (the original regex tried to match a single-quoted shell
  # body, which is brittle to escape in a bats test).
  grep -qF 'systemctl is-active ssh >/dev/null 2>&1' "$SCRIPT" || {
    echo "missing ssh.service check"; return 1
  }
  grep -qF 'systemctl is-active sshd >/dev/null 2>&1' "$SCRIPT" || {
    echo "missing sshd.service fallback check"; return 1
  }
}

@test "node assertion grep regex accepts v20-v99" {
  grep -qE 'grep -qE .\^v\(2\[0-9\].' "$SCRIPT"
}
