#!/usr/bin/env bash
# compact-openclaw-sessions.sh — find sessions idle >= THRESHOLD_MIN
# minutes and run `openclaw sessions compact <sessionId>` on each.
#
# Invoked by openclaw-session-compact.service via the OnCalendar timer.
# This script is the per-cycle worker; the timer + service unit are in
# `systemd/`.
#
# Failure mode: if `openclaw` fails for session A, session B + C still
# run. Fail-soft, not fail-fast, so one stuck session doesn't poison the
# 30-min cycle.

set -euo pipefail

THRESHOLD_MIN="${THRESHOLD_MIN:-120}"
LOG_DIR="${LOG_DIR:-/var/log/openclaw-compact}"
JOURNAL_TAG="${JOURNAL_TAG:-openclaw-session-compact}"

log() {
  # journald-tagged output; also local /var/log/openclaw-compact/ if writable
  echo "$@"
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  [ -w "$LOG_DIR" ] && echo "$(date -Iso8601=seconds) $*" >> "$LOG_DIR/last-cycle.log" 2>/dev/null || true
}

if ! command -v openclaw >/dev/null 2>&1; then
  log "FATAL: openclaw CLI not on PATH"
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  log "FATAL: jq not on PATH"
  exit 1
fi

log "cycle start: threshold=${THRESHOLD_MIN} min"

# Enumerate, filter, sort, dedupe. Fail-soft per session.
mapfile -t IDS < <(
  openclaw sessions list --json 2>/dev/null \
    | jq -r --argjson threshold "$THRESHOLD_MIN" '
        .sessions // []
        | .[]
        | select(.lastInteractionAt != null)
        | ((.lastInteractionAt | fromdateiso8601?) // 0) as $t
        | (now - $t) as $age_sec
        | select(($age_sec / 60) >= $threshold)
        | .sessionId
      ' \
    | sort -u
)

COMPACTED=0
SKIPPED=0
FAILED=0

if [ "${#IDS[@]}" -eq 0 ]; then
  log "no sessions idle >= ${THRESHOLD_MIN}m"
fi

for sid in "${IDS[@]}"; do
  [ -z "$sid" ] && continue
  log "compact $sid"
  if openclaw sessions compact "$sid" >/dev/null 2>&1; then
    COMPACTED=$((COMPACTED + 1))
  else
    rc=$?
    log "WARN: compact $sid failed (rc=$rc)"
    FAILED=$((FAILED + 1))
  fi
done

log "cycle end: compacted=$COMPACTED skipped=$SKIPPED failed=$FAILED"

# Always exit 0 — this is a periodic pumper. Failures are logged for
# observation; a stuck session must not break the 30-min cycle.
exit 0
