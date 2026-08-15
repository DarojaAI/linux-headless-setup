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
# Required tools: systemctl, jq, openclaw

set -euo pipefail

# ── Bash ≥ 5.3 gate (PR #21 extended; moved BEFORE source lib.sh) ──
# On bash 5.2.21 (Ubuntu 24.04 default), `set -euo pipefail` + lib.sh's
# ERR trap + nested `bash` invocation segfaults (exit 139 SIGSEGV) in
# the trap-cleanup race. The only safe path is to refuse to run on
# bash < 5.3 BEFORE anything touches the offending code path.
# We do NOT source lib.sh nor depend on any ERR trap here — just a
# bare substring match on BASH_VERSION.
if [ -n "${BASH_VERSION:-}" ] && \
   ! { printf '%s\n' "$BASH_VERSION" | grep -Eq '^(5\.[3-9]|[6-9]\.|[0-9]{2,})'; }; then
  >&2 echo "FATAL: install-openclaw-compact.sh requires bash >= 5.3 (this is bash ${BASH_VERSION})."
  >&2 echo "  Ubuntu 24.04 ships bash 5.2 by default. Install bash 5.3 from upstream:"
  >&2 echo "    wget https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz"
  >&2 echo "    cd bash-5.3 && ./configure --prefix=/opt/bash-5.3 --enable-readline && make -j2 && make install"
  >&2 echo "  Then invoke this script with /opt/bash-5.3/bin/bash."
  >&2 echo "  Or run deploy-headless.sh, which routes through /opt/bash-5.3/bin/bash."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

UNIT_DIR="/etc/systemd/user"
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
    echo "ERROR: must run as root (timer/unit live in /etc/systemd/user; the install + systemctl --user --global enable need root)" >&2
    exit 1
  fi

  # bash 5.2.x (Ubuntu 24.04) regression: under `set -euo pipefail`
  # + an ERR trap (lib.sh line 16), a non-zero `command -v` exit that
  # is intentionally handled by `if ! ...; then` still fires lib.sh's
  # ERR trap on the OUTER shell's wrapper, killing the script with
  # SIGSEGV (exit 139). Same shape as PR #19's systemctl enable
  # workaround: disable errexit around the soft pre-flight probe.
  set +e
  if ! command -v openclaw >/dev/null 2>&1; then
    echo "WARN: openclaw CLI not found on PATH — service will be enabled but will fail until openclaw is installed (typical order: this script runs after install-docker + openclaw-prep, so it should be present)" >&2
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

  # Substitute the placeholders directly. The prior implementation ran
  # this inside `env -i bash -c '...'` for isolation, but that block
  # lost the outer-script variables (SERVICE_DEST, TIMER_DEST,
  # WORKER_DEST) under `set -euo pipefail` because they're local-scope,
  # not exported. Deploy 31815364007 (post-#17) failed at line 52 of
  # deploy-headless.sh with `bash: line 5: SERVICE_DEST: unbound
  # variable`. The substitution is a pure transformation; the outer
  # `set -euo pipefail` is sufficient isolation.
  THRESHOLD_MIN="${THRESHOLD_MIN:-120}"
  CADENCE_MIN="${CADENCE_MIN:-30}"
  sed -e "s/__THRESHOLD_MIN__/${THRESHOLD_MIN}/g" \
      -e "s/__CADENCE_MIN__/${CADENCE_MIN}/g" \
      "$SERVICE_FILE" > "$SERVICE_DEST"
  cp "$TIMER_FILE" "$TIMER_DEST"
  chmod 0644 "$SERVICE_DEST" "$TIMER_DEST"
  install -m 0755 "$WORKER_FILE" "$WORKER_DEST"

  systemctl daemon-reload
  # bash 5.2.x (Ubuntu 24.04) regression: `set -euo pipefail` +
  # `systemctl enable --now <unit>` + inherited SIGPIPE/SIGCHLD during
  # unit activation produces SIGSEGV (exit 139) on bash cleanup.
  # Disable errexit around the systemd call; the post-call `|| true`
  # covers anything that still sets non-zero. Same pattern as the rest
  # of this script's idempotency helpers.
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
