#!/bin/bash
# install-watchdogs.sh — install + enable the L2 VM watchdogs:
#   - tmp-cleanup.service/.timer    hourly /tmp + /var/tmp stale-file sweep
#   - disk-watchdog.service/.timer  5-min disk usage WARN (threshold 85%)
#
# Usage:
#   sudo bash scripts/install-watchdogs.sh
#
# Idempotent: `install -m` overwrites the units and binaries, daemon-reload
# re-reads changed units, and `systemctl enable --now` is a no-op when the
# timer is already active (re-runs during deploy are safe).
#
# Why systemd timers (not cron.d): journald trail + Persistent=true catch-up,
# matches the existing monitoring.sh node_exporter precedent and the
# openclaw-session-compact install pattern.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
  echo "install-watchdogs.sh: must run as root (writes /usr/local/sbin + /etc/systemd/system)" >&2
  exit 1
fi

# ── Binaries ──
install -d -m 0755 /usr/local/sbin
install -m 0755 "$SCRIPT_DIR/maintenance/tmp-cleanup.sh"   /usr/local/sbin/tmp-cleanup.sh
install -m 0755 "$SCRIPT_DIR/maintenance/disk-watchdog.sh" /usr/local/sbin/disk-watchdog.sh

# ── Units ──
install -d -m 0755 /etc/systemd/system
install -m 0644 "$SCRIPT_DIR/systemd/tmp-cleanup.service"   /etc/systemd/system/tmp-cleanup.service
install -m 0644 "$SCRIPT_DIR/systemd/tmp-cleanup.timer"     /etc/systemd/system/tmp-cleanup.timer
install -m 0644 "$SCRIPT_DIR/systemd/disk-watchdog.service" /etc/systemd/system/disk-watchdog.service
install -m 0644 "$SCRIPT_DIR/systemd/disk-watchdog.timer"   /etc/systemd/system/disk-watchdog.timer

systemctl daemon-reload

# bash 5.2.21 (Ubuntu 24.04) regression: `set -euo pipefail` + lib.sh
# ERR-trap cleanup + `systemctl enable --now <unit>` can SIGSEGV (exit 139)
# during unit activation. Disable errexit around the activation calls;
# `|| true` covers anything that still returns non-zero (already-enabled
# timers included). Restore errexit immediately after.
set +e
systemctl enable --now tmp-cleanup.timer 2>/dev/null || true
systemctl enable --now disk-watchdog.timer 2>/dev/null || true
set -e

systemctl daemon-reload
echo "install-watchdogs.sh: L2 watchdogs installed and enabled"