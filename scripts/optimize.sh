#!/bin/bash
# optimize.sh — L2 kernel/network sysctl hardening drop-in
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting L2 sysctl hardening..."

# ── L2 hardening sysctl drop-in ──
# /etc/sysctl.d/*.conf runs ahead of /etc/sysctl.conf, and
# 99-l2-hardening.conf sorts numerically last so this drop-in wins over
# Hetzner cloud-init defaults and the docker forwarding drop-in.
cat >/etc/sysctl.d/99-l2-hardening.conf <<'EOF'
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
kernel.randomize_va_space=2
EOF

info "Applying sysctl settings..."
sysctl --system >/dev/null

# Confirm the drop-in made it through (guards against cloud-init/other
# sysctl consumers clobbering the value after --system).
sysctl_output="$(sysctl net.ipv4.tcp_syncookies)"
if [ "$sysctl_output" != "net.ipv4.tcp_syncookies = 1" ]; then
	error "L2 sysctl drop-in not applied (sysctl returned: $sysctl_output)"
	exit 1
fi

info "L2 sysctl hardening complete (net.ipv4.tcp_syncookies =  1"