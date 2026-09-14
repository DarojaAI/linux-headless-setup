#!/bin/bash
# scripts/bash53.sh — provision /opt/bash-5.3/bin/bash from the GNU release tarball.
#
# Why this lives in L2: the install scripts that run after this point
# (install-openclaw-compact.sh, install-runtime-seam-binaries.sh,
# monitorFan.sh, etc.) consume bash ≥ 5.3 to dodge the bash 5.2 + ERR-trap
# + nested-bash SIGSEGV class. Ubuntu 24.04 (Hetzner default) ships
# bash 5.2.21, so before any of those scripts can run we have to install
# 5.3 ourselves.
#
# Two reasons we build from source rather than a PPA:
#   1. No new trust boundary. gnu.org is on the apt-mirror trust path
#      already; a third-party Ubuntu PPA is not.
#   2. Reproducible across three images (Hetzner ubuntu-24.04, GitHub-
#      hosted ubuntu-24.04 runners, any local dev VM). Pinned to the
#      5.3.0 tarball.
#
# Idempotent: short-circuits if /opt/bash-5.3/bin/bash already exists.
# Failure modes:
#   - missing toolchain (build-essential, bison, wget) → apt-get install
#     + retry
#   - wget non-2xx → fatal, exit 1
#   - configure/make/install non-zero → fatal, exit 1, leaves the workdir
#     behind so the operator can inspect
#
# BUG-CLASS anchors: 2026-08-14-bash-5.2-ERR-trap-sigsegv (L3a
# postmortem). Right-layer fix lives here, in L2.
#
# Usage: bash scripts/bash53.sh   (called from deploy-headless.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

BASH53_PREFIX=/opt/bash-5.3
BASH53_VERSION=5.3
BASH53_TARBALL_URL="https://ftp.gnu.org/gnu/bash/bash-${BASH53_VERSION}.tar.gz"

if [ -x "$BASH53_PREFIX/bin/bash" ]; then
	info "bash ${BASH53_VERSION} already provisioned at $BASH53_PREFIX/bin/bash"
	exit 0
fi

info "bash ${BASH53_VERSION} not found — building from $BASH53_TARBALL_URL"

# ── Toolchain (idempotent; build-essential already installed by system.sh
# on most VMs, but spelled out here so a fresh image without L2's package
# set doesn't break). ──
apt_install build-essential
apt_install bison
apt_install wget

WORK=$(mktemp -d)
# shellcheck disable=SC2064  # we want $WORK captured NOW, not at signal time
trap "rm -rf '$WORK'" EXIT

info "Fetching $BASH53_TARBALL_URL"
if ! wget -q --show-progress=off "$BASH53_TARBALL_URL" -O "$WORK/bash.tar.gz"; then
	error "wget failed for $BASH53_TARBALL_URL (workdir preserved at $WORK for diagnostics)"
	trap - EXIT
	exit 1
fi

info "Extracting"
tar -xzf "$WORK/bash.tar.gz" -C "$WORK"
SRC_DIR=$(find "$WORK" -maxdepth 1 -type d -name "bash-${BASH53_VERSION}*" | head -1)
if [ -z "$SRC_DIR" ]; then
	error "Could not locate extracted bash-${BASH53_VERSION}* directory under $WORK"
	exit 1
fi

pushd "$SRC_DIR" >/dev/null
info "Configuring --prefix=$BASH53_PREFIX --enable-readline --without-bash-malloc"
if ! ./configure --prefix="$BASH53_PREFIX" --enable-readline --without-bash-malloc; then
	popd >/dev/null
	error "./configure failed for bash ${BASH53_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
info "Building (nproc=$(nproc))"
if ! make -j"$(nproc)"; then
	popd >/dev/null
	error "make failed for bash ${BASH53_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
info "Installing to $BASH53_PREFIX"
if ! make install; then
	popd >/dev/null
	error "make install failed for bash ${BASH53_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
popd >/dev/null

if [ ! -x "$BASH53_PREFIX/bin/bash" ]; then
	error "bash ${BASH53_VERSION} build/install completed but $BASH53_PREFIX/bin/bash missing"
	exit 1
fi

# shellcheck disable=SC2016  # nested bash:literal $BASH_VERSION must double-expand
INSTALLED_VERSION=$("$BASH53_PREFIX/bin/bash" -c 'echo "$BASH_VERSION"')
info "bash ${INSTALLED_VERSION} provisioned at $BASH53_PREFIX/bin/bash"
# Persist /opt/bash-5.3/bin ahead of system bash for the rest of the
# L2 deploy chain. Idempotent — subsequent shells prepend it again but
# the PATH-dedup behaviour is fine.
export PATH="$BASH53_PREFIX/bin:$PATH"
