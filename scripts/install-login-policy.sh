#!/bin/bash
# install-login-policy.sh — L2 login policy drop-in.
# Replaces strict-defaults with a sane long-rotation policy.
# Idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Installing L2 login policy drop-in..."

# /etc/login.defs.d/ is read by login(5) NOT by default on libpam-shadow;
# many Linux PAM stacks will still read /etc/login.defs in full, but
# Ubuntu's `/etc/pam.d/common-password` honors the policy block we drop.
# Drop a 99-l2-policy.conf which becomes the canonical override; do not
# rewrite /etc/login.defs itself (that's a Hetzner cloud-init venue).
mkdir -p /etc/login.defs.d
cat >/etc/login.defs.d/99-l2-policy.conf <<'EOF'
# L2 login policy — applied each deploy.
# PASS_MAX_DAYS days: rotate password every 365 days (FHS-aligned).
# PASS_MIN_DAYS: 1 day minimum between changes.
# PASS_WARN_AGE: warn 14 days before expiration.
PASS_MAX_DAYS 365
PASS_MIN_DAYS 1
PASS_WARN_AGE 14
# Default UMASK is already 022; L2 picks 027 for tighter default.
UMASK 027
EOF
chmod 0644 /etc/login.defs.d/99-l2-policy.conf

info "L2 login policy drop-in installed."