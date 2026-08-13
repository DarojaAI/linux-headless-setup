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
