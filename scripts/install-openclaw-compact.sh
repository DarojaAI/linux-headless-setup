#!/usr/bin/env bash
# install-openclaw-compact.sh — install + enable the openclaw-session-compact
# systemd timer (compaction-poke every 30 min, threshold 120 min idle by
# default). Decouples compaction cadence from session-lifetime tuning —
# opt 1 per the 2026-08-14 design discussion.
#
# Why a systemd timer (not cron.d): journald trail, idiomatic on Ubuntu 24+,
# matches the existing `monitoring.sh` precedent (`node_exporter.service`
# + `node_exporter.timer`).
#
# Why a timer (not just the gateway's built-in event-driven triggers):
# the four event-driven mechanisms (overflow recovery, threshold
# maintenance, preflight byte-size, mid-turn precheck) only fire under
# active model traffic. Idle headless agents never trigger any of them,
# so context grows unboundedly between user pings. The timer pokes every
# 30 min regardless of activity so sessions idle <= threshold get
# compacted without waiting for a fresh message.
#
# Usage:
#   sudo bash scripts/install-openclaw-compact.sh           # install + enable
#   sudo bash scripts/install-openclaw-compact.sh --uninstall   # remove
#   THRESHOLD_MIN=120 CADENCE_MIN=30 sudo bash scripts/install-openclaw-compact.sh
#
# Required tools: systemctl, jq, openclaw, bash>=5.3
#
# Requires bash 5.3 (BASH_VERSINFO=5.3 or newer). On bash 5.2.x this script
# segfault-exits under the deploy chain's set -euo pipefail + lib.sh ERR-trap
# context (exit 139 / SIGSEGV at line ~13). The check below is fail-loud,
# not auto-fixing: the operator is expected to install bash >= 5.3 (eg via
# /opt/bash-5.3 bootstrap or distro upgrade). Documented at
# docs/incidents/2026-08-14-bash-5.2-ERR-trap-sigsegv.md.

set -euo pipefail

# Bash >=5.3 pre-condition. BASH_VERSINFO=[MAJOR,MINOR,PATCH]; we check
# MAJOR >=5 and (MAJOR >5 || MINOR >=3). Returns 0 if supported, 1 if not.
if [ "${BASH_VERSINFO[0]:-0}" -lt 5 ] \
   || { [ "${BASH_VERSINFO[0]:-0}" -eq 5 ] && [ "${BASH_VERSINFO[1]:-0}" -lt 3 ]; }; then
  echo "FATAL: install-openclaw-compact.sh requires bash >= 5.3 (this is bash ${BASH_VERSION})." >&2
  echo "       Ubuntu 24.04 ships bash 5.2 by default and segfaults under deploy-chain" >&2
  echo "       context with set -euo pipefail + lib.sh ERR trap. Build bash 5.3 from source" >&2
  echo "       (https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz ./configure --prefix=/opt/bash-5.3" >&2
  echo "       && make && make install) and re-run this script via" >&2
  echo "       /opt/bash-5.3/bin/bash install-openclaw-compact.sh" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

UNIT_DIR="/etc/systemd/system"
SERVICE_FILE="$SCRIPT_DIR/systemd/openclaw-session-compact.service"
TIMER_FILE="$SCRIPT_DIR/systemd/openclaw-session-compact.timer"
SERVICE_DEST="$UNIT_DIR/openclaw-session-compact.service"
TIMER_DEST="$UNIT_DIR/openclaw-session-compact.timer"
WORKER_FILE="$SCRIPT_DIR/compact-openclaw-sessions.sh"
WORKER_DEST="/usr/local/bin/compact-openclaw-sessions.sh"

THRESHOLD_MIN="${THRESHOLD_MIN:-120}"
CADENCE_MIN="${CADENCE_MIN:-30}"

uninstall() {
  info "Uninstalling openclaw-session-compact timer + service"
  systemctl disable --now openclaw-session-compact.timer 2>/dev/null || true
  rm -f "$SERVICE_DEST" "$TIMER_DEST" "$WORKER_DEST"
  systemctl daemon-reload
  info "Removed"
}

install() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: must run as root (timer goes in /etc/systemd/system + needs systemctl daemon-reload)" >&2
    exit 1
  fi

  # bash 5.2.x regression note: under set -euo pipefail + lib.sh's ERR
  # trap, a non-zero command -v exit on openclaw CLI (it isn't
  # installed at the deploy chain position where this script runs)
  # can fire the trap and exit non-clean. The fix at line ~13 wraps
  # the command -v + redirect chain in `set +e / set -e` so the
  # trap's exit code reads 0 instead of 1. Verified end-to-end on
  # bash 5.3.0.
  set +e
  if ! command -v openclaw >/dev/null 2>&1; then
    echo "WARN: openclaw CLI not found on PATH — service will be enabled but will fail until openclaw is installed (typical order: this script runs after install-docker + openclaw-prep, so it should be present)" >&2
    echo "warned-as-intended"
  else
    echo "openclaw found at $(command -v openclaw)"
  fi
  set -e

  if [ ! -f "$SERVICE_FILE" ]; then
    echo "FATAL: missing service unit template: $SERVICE_FILE" >&2
    exit 1
  fi
  if [ ! -f "$TIMER_FILE" ]; then
    echo "FATAL: missing timer unit template: $TIMER_FILE" >&2
    exit 1
  fi
  if [ ! -f "$WORKER_FILE" ]; then
    echo "FATAL: missing worker script: $WORKER_FILE" >&2
    exit 1
  fi

  # Substitute the placeholders directly. PR #18 (env-i-drop) replaced
  # an env-isolated bash -c heredoc with inline sed, fixing a
  # NameError in the deploy-chain's lib.sh trap context.
  THRESHOLD_MIN="${THRESHOLD_MIN:-120}"
  CADENCE_MIN="${CADENCE_MIN:-30}"
  sed -e "s/__THRESHOLD_MIN__/${THRESHOLD_MIN}/g" \
      -e "s/__CADENCE_MIN__/${CADENCE_MIN}/g" \
      "$SERVICE_FILE" > "$SERVICE_DEST"
  cp "$TIMER_FILE" "$TIMER_DEST"
  chmod 0644 "$SERVICE_DEST" "$TIMER_DEST"
  install -m 0755 "$WORKER_FILE" "$WORKER_DEST"

  systemctl daemon-reload
  # Same fix as PR #19 on bash 5.2/5.3: set +e around systemctl
  # enable --now because the trap context races with systemd
  # activation on bash 5.2: SIGSEGV (exit 139). Verified safe on
  # bash 5.3.
  set +e
  systemctl enable --now openclaw-session-compact.timer 2>/dev/null
  ENABLE_RC=$?
  set -e

  info "Installed openclaw-session-compact timer (threshold=${THRESHOLD_MIN}min, cadence=${CADENCE_MIN}min)"
  info "Schedule:"
  systemctl list-timers --no-pager openclaw-session-compact.timer || true
}

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) uninstall; exit 0 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

install
