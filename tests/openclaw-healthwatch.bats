#!/usr/bin/env bats
# Regression tests for the openclaw-healthwatch systemd pair (issue #53,
# epic #48): a VM-layer watchdog that probes the openclaw gateway's
# /healthz endpoint every 30s and restarts the USER gateway unit on
# failure (5xx or TCP-level curl error).
#
# Verifies (hermetic — parses the shipped unit files + install script,
# never drives live systemctl from inside the BATS run):
#   - openclaw-healthwatch.service matches the documented contract:
#     Wants= (NOT PartOf=) toward openclaw-session-compact.timer
#     (AGENTS.md "Use Wants= not PartOf=" anchor — the watchdog must
#     never cascade a stop/restart to the compaction sibling), oneshot
#     curl probe with `systemctl --user restart` fallback
#   - openclaw-healthwatch.timer cadence (2min after boot, then every
#     30s, 5s accuracy) + Persistent=true + WantedBy=timers.target
#   - install-openclaw-compact.sh copies both units into
#     /etc/systemd/system and enables the timer

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/openclaw-healthwatch.bats}")/.." && pwd)"
}

@test "scripts/systemd/openclaw-healthwatch.service exists" {
  [ -f "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service" ]
}

@test "scripts/systemd/openclaw-healthwatch.timer exists" {
  [ -f "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer" ]
}

@test "healthwatch service has the documented Description" {
  grep -qE '^Description=OpenClaw gateway health probe \+ auto-restart' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
}

@test "healthwatch service uses Wants= (and never PartOf=) toward openclaw-session-compact" {
  # AGENTS.md "Use Wants= not PartOf=" anchor: a PartOf= edge would make
  # a stop/restart of the watchdog cascade onto the compaction sibling.
  grep -qE '^Wants=openclaw-session-compact\.timer' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
  ! grep -qE '^PartOf=openclaw-session-compact' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
}

@test "healthwatch service is a oneshot curl probe with systemctl --user restart fallback" {
  grep -qE '^Type=oneshot' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
  grep -qE '^ExecStart=.*curl' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
  grep -qE '^ExecStart=.*systemctl --user restart openclaw-gateway\.service' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
}

@test "healthwatch service probes /healthz on 127.0.0.1:18789 with a 5s timeout" {
  grep -qE '^ExecStart=.*http://127\.0\.0\.1:18789/healthz' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
  grep -qE '^ExecStart=.*--max-time 5' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
}

@test "healthwatch timer runs 2min after boot then every 30s with 5s accuracy" {
  grep -qE '^OnBootSec=2min' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
  grep -qE '^OnUnitActiveSec=30s' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
  grep -qE '^AccuracySec=5s' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
}

@test "healthwatch timer is persistent (missed cycles catch up on boot)" {
  grep -qE '^Persistent=true' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
}

@test "healthwatch timer is wanted by timers.target" {
  grep -qE '^WantedBy=timers\.target' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
}

@test "install-openclaw-compact.sh copies both healthwatch units into /etc/systemd/system" {
  grep -qE 'HEALTHWATCH_SERVICE_DEST=.*openclaw-healthwatch\.service' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
  grep -qE 'HEALTHWATCH_TIMER_DEST=.*openclaw-healthwatch\.timer' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
  grep -qE 'HEALTHWATCH_UNIT_DIR="/etc/systemd/system"' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
  grep -qE 'cp "\$HEALTHWATCH_SERVICE_FILE" "\$HEALTHWATCH_SERVICE_DEST"' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
  grep -qE 'cp "\$HEALTHWATCH_TIMER_FILE" "\$HEALTHWATCH_TIMER_DEST"' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}

@test "install-openclaw-compact.sh enables the healthwatch timer" {
  grep -qE 'systemctl enable --now openclaw-healthwatch\.timer' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}

@test "install-openclaw-compact.sh uninstall removes the healthwatch units" {
  grep -qE 'rm -f "\$HEALTHWATCH_SERVICE_DEST" "\$HEALTHWATCH_TIMER_DEST"' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}

@test "healthwatch unit files have no literal backticks (heredoc footgun shadow)" {
  ! grep -qE '\x60' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.service"
  ! grep -qE '\x60' "$REPO_ROOT/scripts/systemd/openclaw-healthwatch.timer"
}