#!/usr/bin/env bats
# Regression tests for the L2 /tmp + /var/tmp hourly cleanup watchdog
# (scripts/maintenance/tmp-cleanup.sh + systemd tmp-cleanup unit pair).
#
# Verifies:
#   - the 3 install-set files exist
#   - the service unit carries the kill-switch ConditionPathExists
#   - the timer cadence is hourly + Persistent=true (boot catch-up)
#   - the sweep uses -xdev on ALL four find calls (no mount crossing)
#   - deploy-headless.sh wires install-watchdogs.sh as the last step

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/tmp-cleanup.bats}")/.." && pwd)"
}

@test "scripts/maintenance/tmp-cleanup.sh exists" {
  [ -f "$REPO_ROOT/scripts/maintenance/tmp-cleanup.sh" ]
}

@test "scripts/systemd/tmp-cleanup.service exists" {
  [ -f "$REPO_ROOT/scripts/systemd/tmp-cleanup.service" ]
}

@test "scripts/systemd/tmp-cleanup.timer exists" {
  [ -f "$REPO_ROOT/scripts/systemd/tmp-cleanup.timer" ]
}

@test "tmp-cleanup.service has Description + disable-killswitch ConditionPathExists" {
  grep -qE '^Description=L2 hourly /tmp and /var/tmp cleanup sweep' "$REPO_ROOT/scripts/systemd/tmp-cleanup.service"
  grep -qE '^ConditionPathExists=!/var/run/l2-disable-tmp-cleanup' "$REPO_ROOT/scripts/systemd/tmp-cleanup.service"
}

@test "tmp-cleanup.timer: OnBootSec + hourly OnUnitActiveSec + Persistent + timers.target" {
  grep -qE '^OnBootSec=5min' "$REPO_ROOT/scripts/systemd/tmp-cleanup.timer"
  grep -qE '^OnUnitActiveSec=1h' "$REPO_ROOT/scripts/systemd/tmp-cleanup.timer"
  grep -qE '^Persistent=true' "$REPO_ROOT/scripts/systemd/tmp-cleanup.timer"
  grep -qE '^WantedBy=timers\.target' "$REPO_ROOT/scripts/systemd/tmp-cleanup.timer"
}

@test "tmp-cleanup.sh keeps every find inside -xdev (never crosses mounted volumes)" {
  # Exactly 4 find sweeps (files+dirs x /tmp + /var/tmp), and each one
  # must carry -xdev so the sweep stays inside the tmpfs and cannot
  # clobber mounted volumes.
  local finds
  finds=$(grep -cE '^find /(tmp|var/tmp) -xdev ' "$REPO_ROOT/scripts/maintenance/tmp-cleanup.sh" || true)
  [ "$finds" -eq 4 ]
}

@test "deploy-headless.sh wires install-watchdogs.sh after install-runtime-seam-binaries.sh" {
  # install-runtime-seam-binaries.sh is the existing last step; the
  # watchdog install must come after it (still before the completion
  # banner) so the deploy chain ends with the new units active.
  local seam_line watchdog_line
  seam_line=$(grep -nF '"$BASH" "$SCRIPT_DIR/scripts/install-runtime-seam-binaries.sh"' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  watchdog_line=$(grep -nF 'bash "$SCRIPT_DIR/scripts/install-watchdogs.sh"' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  [ -n "$seam_line" ] || { echo "install-runtime-seam-binaries.sh chain entry not found"; return 1; }
  [ -n "$watchdog_line" ] || { echo "install-watchdogs.sh chain entry not found"; return 1; }
  [ "$seam_line" -lt "$watchdog_line" ] || { echo "install-watchdogs.sh must run AFTER install-runtime-seam-binaries.sh"; return 1; }
}