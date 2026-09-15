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

@test "validate-install.sh probes sshd process tree via pgrep" {
  grep -qE 'pgrep -xf' "$SCRIPT"
}

@test "validate-install.sh probes :22 listener via ss" {
  grep -qE 'ss -tlnH' "$SCRIPT"
}

@test "validate-install.sh no longer named 'sshd running'" {
  ! grep -qE '"sshd running"' "$SCRIPT"
}
