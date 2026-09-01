#!/bin/bash
# install-apt-policy.sh — L2 apt policy pin. Hold kernels + critical packages
# so unattended-upgrades doesn't silently swap a running component, restrict
# unattended-upgrades to security only, and disable automatic-reboot.
# Idempotent: safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Installing L2 apt policy pin..."

# 1) Hold kernel packages so -dist-upgrade doesn't swap the running kernel.
# Hold is idempotent — apt-mark output goes to stderr on already-held, but
# exit code is 0; redirect stderr to stdout for readability.
for pkg in \
    linux-image-generic \
    linux-headers-generic \
    linux-image-virtual \
    linux-modules-extra-$(uname -r) ; do
    if ! apt-mark showhold "$pkg" | grep -qx "$pkg" 2>/dev/null; then
        info "Holding: $pkg"
        apt-mark hold "$pkg" 2>&1 || warn "Could not hold $pkg (may not exist on this distro)"
    else
        info "Already held: $pkg"
    fi
done

# 2) Restrict unattended-upgrades: only security pocket, no auto-reboot.
mkdir -p /etc/apt/apt.conf.d
cat >/etc/apt/apt.conf.d/20-unattended-restrictions <<'EOF'
// L2 unattended-upgrades restrictions: security pocket only,
// no automatic-reboot, no -dist-upgrade.
// Source of truth is docs/runbooks/audit/2026-09-01-apt-policy-pin.md (DarojaAI/linux-headless-setup#48)
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Origins-Pattern {
    "origin=Ubuntu,archive=${distro_codename}-security";
    "origin=Ubuntu,archive=${distro_codename},label=Ubuntu-Security";
};
EOF
chmod 0644 /etc/apt/apt.conf.d/20-unattended-restrictions

# 3) Refresh apt-mark holds if any of the held packages is no longer held
# (e.g. someone manually unheld it). This re-asserts policy at deploy time.
CURRENT_KERNEL=""
if command -v uname >/dev/null; then
    CURRENT_KERNEL="$(uname -r)"
fi
# Re-apply unconditionally for the kernel-modules-extra; apt-mark hold is
# idempotent.
if [ -n "$CURRENT_KERNEL" ]; then
    apt-mark hold "linux-modules-extra-${CURRENT_KERNEL}" 2>/dev/null || true
fi

# 4) Install the boot-time drift guard: apt-policy-applied.service re-asserts
# the holds (apt-mark showhold check; re-hold on drift) after every boot.
# Fail-soft (warn-only): container/immutable hosts may lack a full systemd.
UNIT_SRC="$SCRIPT_DIR/systemd/apt-policy-applied.service"
UNIT_DEST="/etc/systemd/system/apt-policy-applied.service"
if [ -f "$UNIT_SRC" ]; then
    mkdir -p /etc/systemd/system
    install -m 0644 "$UNIT_SRC" "$UNIT_DEST"
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable apt-policy-applied.service >/dev/null 2>&1 \
        || warn "Could not enable apt-policy-applied.service (no systemd on this host?)"
else
    warn "apt-policy-applied.service not found next to install-apt-policy.sh (unit ships from scripts/systemd/)"
fi

info "L2 apt policy pin installed."