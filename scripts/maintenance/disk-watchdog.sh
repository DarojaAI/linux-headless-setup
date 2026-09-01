#!/bin/bash
# disk-watchdog.sh — emit a structured WARN if / or /home >85% used.
set -euo pipefail
THRESHOLD=${DISK_WATCHDOG_THRESHOLD:-85}
high=$(df --output=pcent / /home 2>/dev/null | tail -n +2 | tr -d ' %' | sort -n | tail -1)
if [ -n "${high:-}" ] && [ "$high" -ge "$THRESHOLD" ]; then
  logger -t disk-watchdog -p user.warning "disk usage $high% on / or /home (threshold=$THRESHOLD%)"
  echo "{\"event\":\"disk_watchdog_warning\",\"usage_pct\":${high},\"threshold\":${THRESHOLD},\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> /var/log/l2-disk-watchdog.jsonl
fi