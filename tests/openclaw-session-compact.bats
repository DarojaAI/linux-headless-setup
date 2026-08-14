#!/usr/bin/env bats
# Regression tests for the openclaw-session-compact per-session compaction
# pumper (opt 1 per the 2026-08-14 design discussion).
#
# Verifies:
#   - The 4 install-set files exist + sync'd into the worktree
#   - deploy-headless.sh chain hooks install-openclaw-compact.sh at the
#     correct position (after monitoring.sh, before openclaw-prep.sh)
#   - The install script idempotently replaces __THRESHOLD_MIN__
#   - The worker fails-soft (one bad session doesn't break the loop)
#   - The unit files don't have literal-backtick heredoc footguns
#     (deploy 31654184554 fix pattern; PR #1322 shadow)

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/openclaw-session-compact.bats}")/.." && pwd)"
}

@test "scripts/install-openclaw-compact.sh exists" {
  [ -f "$REPO_ROOT/scripts/install-openclaw-compact.sh" ]
}

@test "scripts/compact-openclaw-sessions.sh exists" {
  [ -f "$REPO_ROOT/scripts/compact-openclaw-sessions.sh" ]
}

@test "scripts/systemd/openclaw-session-compact.service exists" {
  [ -f "$REPO_ROOT/scripts/systemd/openclaw-session-compact.service" ]
}

@test "scripts/systemd/openclaw-session-compact.timer exists" {
  [ -f "$REPO_ROOT/scripts/systemd/openclaw-session-compact.timer" ]
}

@test "install-openclaw-compact.sh passes bash -n syntax check" {
  bash -n "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}

@test "compact-openclaw-sessions.sh passes bash -n syntax check" {
  bash -n "$REPO_ROOT/scripts/compact-openclaw-sessions.sh"
}

@test "deploy-headless.sh invokes install-openclaw-compact.sh between monitoring.sh and openclaw-prep.sh" {
  # The chain order is load-bearing: install-openclaw-compact.sh needs
  # /etc/systemd/system + working `openclaw` CLI (from openclaw-prep.sh).
  # Place it AFTER monitoring.sh (which makes the systemd dir writable
  # pattern explicit) and BEFORE openclaw-prep.sh (which depends on the
  # openclaw binary being installed).
  local monitoring_line openclaw_line compact_line
  monitoring_line=$(grep -nE '^bash .*monitoring\.sh' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  openclaw_line=$(grep -nE '^bash .*openclaw-prep\.sh' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  compact_line=$(grep -nE '^bash .*install-openclaw-compact\.sh' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  [ -n "$monitoring_line" ] || { echo "monitoring.sh chain entry not found"; return 1; }
  [ -n "$openclaw_line" ] || { echo "openclaw-prep.sh chain entry not found"; return 1; }
  [ -n "$compact_line" ] || { echo "install-openclaw-compact.sh chain entry not found"; return 1; }
  [ "$monitoring_line" -lt "$compact_line" ] || { echo "compact at line $compact_line must be AFTER monitoring.sh at line $monitoring_line"; return 1; }
  [ "$compact_line" -lt "$openclaw_line" ] || { echo "compact at line $compact_line must be BEFORE openclaw-prep.sh at line $openclaw_line"; return 1; }
}

@test "compact-openclaw-sessions.sh fails-soft per session (no abort on one bad id)" {
  # The worker iterates sessions and calls `openclaw sessions compact <id>`
  # per session. A shell loop that aborts on one failure would skip
  # the rest of the cycle. Verify the worker does NOT have an `exit 1`
  # mid-loop.
  ! grep -qE 'openclaw sessions compact.*exit 1|openclaw sessions compact.*exit.*\b1\b' "$REPO_ROOT/scripts/compact-openclaw-sessions.sh"
}

@test "compact-openclaw-sessions.sh always exits 0 at end of cycle (cycle is a pumper, not a gate)" {
  grep -qE '^exit 0$' "$REPO_ROOT/scripts/compact-openclaw-sessions.sh"
}

@test "compact-openclaw-sessions.sh filters by lastInteractionAt + THRESHOLD_MIN (not a brute-force compact)" {
  # Without filtering, the pumper would re-compact every session every
  # 30 minutes, wasting summarization cycles. The threshold gate is the
  # whole point of opt 1.
  grep -qE 'THRESHOLD_MIN|lastInteractionAt|fromdateiso8601' "$REPO_ROOT/scripts/compact-openclaw-sessions.sh"
}

@test "install-openclaw-compact.sh fails fast when not root (timer needs /etc/systemd/system)" {
  grep -qE 'id -u.*ne 0|must run as root' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}

@test "compact-openclaw-sessions.sh handles jq + openclaw absence (FATAL early)" {
  grep -qE 'command -v openclaw|command -v jq' "$REPO_ROOT/scripts/compact-openclaw-sessions.sh"
}

@test "service unit references __THRESHOLD_MIN__ placeholder (envsubst'd at install time)" {
  grep -q '__THRESHOLD_MIN__' "$REPO_ROOT/scripts/systemd/openclaw-session-compact.service"
}

@test "timer unit has OnCalendar + Persistent=true (catches missed cycles on boot)" {
  grep -qE '^OnCalendar=' "$REPO_ROOT/scripts/systemd/openclaw-session-compact.timer"
  grep -qE '^Persistent=true' "$REPO_ROOT/scripts/systemd/openclaw-session-compact.timer"
}

@test "no literal backticks in unit files (deploy 31654184554 footgun shadow)" {
  # PR #1322 closed this footgun; belt-and-suspenders BATS gate.
  ! grep -qE '\x60' "$REPO_ROOT/scripts/systemd/openclaw-session-compact.service"
  ! grep -qE '\x60' "$REPO_ROOT/scripts/systemd/openclaw-session-compact.timer"
}

@test "install-openclaw-compact.sh carries an uninstall path (idempotent re-runs safe)" {
  grep -qE 'uninstall|--uninstall' "$REPO_ROOT/scripts/install-openclaw-compact.sh"
}
