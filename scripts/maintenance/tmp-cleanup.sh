#!/bin/bash
# tmp-cleanup.sh — sweep stale files in /tmp /var/tmp. Idempotent.
set -euo pipefail
find /tmp -xdev -type f -atime +1 -delete 2>/dev/null || true
find /tmp -xdev -type d -mtime +1 -exec rmdir {} + 2>/dev/null || true
find /var/tmp -xdev -type f -atime +1 -delete 2>/dev/null || true
find /var/tmp -xdev -type d -mtime +1 -exec rmdir {} + 2>/dev/null || true