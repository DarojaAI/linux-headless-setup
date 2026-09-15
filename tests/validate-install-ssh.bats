#!/usr/bin/env bats
# Regression test for the ssh-running probe in validate-install.sh.
#
# Bug surfaced by deploy #34963321135 (Tue 2026-09-15):
#   [FAIL] sshd running
# Root cause: ssh.service / sshd.service is socket-activated on the
# hetzner image (TriggeredBy=ssh.socket). `systemctl status` reports
# ActiveState=active, but `systemctl is-active ssh` returns rc=4 from
# non-interactive SSH probes because the unit LoadState=disabled
# + TriggeredBy socket defeats the `is-active` short-circuit. The
# previous validator used `is-active ssh || is-active sshd`, which
# always fails on socket-activated sshd.
#
# This test pins the new probe shape so future maintainers can't
# reintroduce the `is-active` shortcut.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/tests/validate-install.sh"
}

@test "validate-install.sh does NOT probe sshd via 'systemctl is-active ssh|systemctl is-active sshd'" {
  ! grep -qE 'systemctl is-active ssh( |$)' "$SCRIPT"
}

@test "validate-install.sh probes ssh running via test -x /usr/sbin/sshd" {
  grep -qE 'test -x /usr/sbin/sshd' "$SCRIPT"
}

@test "validate-install.sh probes sshd process tree via pgrep -f" {
  # pgrep -f (no -x) matches the pattern anywhere in the full command
  # line. Required because the actual sshd process runs as
  #   sshd: /usr/sbin/sshd -D [listener] 0 of 3-10 startups
  # so a strict exact-match (-x) against /usr/sbin/sshd or any
  # substring of the prefix always misses. Deploy #34986471330
  # surfaced the over-strict class: PR #66 shipped `pgrep -xf` and
  # it failed on the live VM despite sshd running as PID 3665749.
  grep -qE 'pgrep -f' "$SCRIPT"
}

@test "validate-install.sh does NOT use 'pgrep -xf' against /usr/sbin/sshd (over-strict match bug)" {
  # Belt-and-braces: if anyone reverts to `pgrep -xf "/usr/sbin/sshd"`
  # or `pgrep -xf "sshd: /usr/sbin/sshd"`, the test catches it. The
  # exact-string cmdline of real sshd has extra argv after the
  # binary, so `-xf` (exact full-line match) always misses.
  ! grep -qE 'pgrep -xf "/usr/sbin/sshd"' "$SCRIPT"
  ! grep -qE 'pgrep -xf "sshd: /usr/sbin/sshd"' "$SCRIPT"
}

@test "validate-install.sh probes :22 listener via ss" {
  grep -qE 'ss -tlnH' "$SCRIPT"
}

@test "validate-install.sh no longer named 'sshd running'" {
  ! grep -qE '"sshd running"' "$SCRIPT"
}
