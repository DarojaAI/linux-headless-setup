#!/usr/bin/env bats
# Regression tests for the L2 disk usage watchdog
# (scripts/maintenance/disk-watchdog.sh + systemd disk-watchdog unit pair).
#
# Verifies:
#   - the 3 install-set files exist
#   - the service unit: Description, Type=oneshot, threshold Environment
#   - the timer unit: 5-min cadence, Persistent=true, timers.target
#   - the worker emits BOTH a syslog entry (logger) and a JSONL record
#     in /var/log/l2-disk-watchdog.jsonl when the threshold is crossed

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/disk-watchdog.bats}")/.." && pwd)"
}

@test "scripts/maintenance/disk-watchdog.sh exists" {
  [ -f "$REPO_ROOT/scripts/maintenance/disk-watchdog.sh" ]
}

@test "scripts/systemd/disk-watchdog.service exists" {
  [ -f "$REPO_ROOT/scripts/systemd/disk-watchdog.service" ]
}

@test "scripts/systemd/disk-watchdog.timer exists" {
  [ -f "$REPO_ROOT/scripts/systemd/disk-watchdog.timer" ]
}

@test "disk-watchdog.service has Description + Type=oneshot + threshold Environment" {
  grep -qE '^Description=L2 disk usage watchdog' "$REPO_ROOT/scripts/systemd/disk-watchdog.service"
  grep -qE '^Type=oneshot' "$REPO_ROOT/scripts/systemd/disk-watchdog.service"
  grep -qE '^Environment=DISK_WATCHDOG_THRESHOLD=85' "$REPO_ROOT/scripts/systemd/disk-watchdog.service"
}

@test "disk-watchdog.timer: OnBootSec + 5-min OnUnitActiveSec + Persistent + timers.target" {
  grep -qE '^OnBootSec=2min' "$REPO_ROOT/scripts/systemd/disk-watchdog.timer"
  grep -qE '^OnUnitActiveSec=300s' "$REPO_ROOT/scripts/systemd/disk-watchdog.timer"
  grep -qE '^Persistent=true' "$REPO_ROOT/scripts/systemd/disk-watchdog.timer"
  grep -qE '^WantedBy=timers\.target' "$REPO_ROOT/scripts/systemd/disk-watchdog.timer"
}

@test "disk-watchdog.sh emits a syslog entry via logger" {
  grep -qE '^  logger -t disk-watchdog' "$REPO_ROOT/scripts/maintenance/disk-watchdog.sh"
}

@test "disk-watchdog.sh appends a JSONL record to /var/log/l2-disk-watchdog.jsonl" {
  grep -qE 'l2-disk-watchdog\.jsonl' "$REPO_ROOT/scripts/maintenance/disk-watchdog.sh"
}