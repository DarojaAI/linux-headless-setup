#!/bin/bash
# scripts/git-pin.sh — provision /opt/git-2.56.0/bin/git from the kernel.org
# release tarball.
#
# Why this lives in L2: the distro default (Ubuntu 24.04 / noble ships
# git 2.43.x) lags upstream by a year+ and floats with the
# noble-updates pocket — the version is not frozen per deploy, and it
# never tracks the latest stable. This script pins git to the latest
# stable release (2.56.0) built from the canonical source, so the VM
# gets a known, current git regardless of apt pocket drift.
#
# Two reasons we build from source rather than a PPA (same reasoning as
# bash53.sh):
#   1. No new trust boundary. kernel.org is on the apt-mirror trust path
#      already; a third-party Ubuntu PPA is not.
#   2. Reproducible across three images (Hetzner ubuntu-24.04, GitHub-
#      hosted ubuntu-24.04 runners, any local dev VM). Pinned to the
#      2.56.0 tarball.
#
# Idempotent: short-circuits if /opt/git-2.56.0/bin/git already exists.
# Failure modes:
#   - missing toolchain (build-essential, libcurl4-openssl-dev, etc.) →
#     apt-get install + retry
#   - wget non-2xx → fatal, exit 1
#   - make/install non-zero → fatal, exit 1, leaves the workdir behind
#     so the operator can inspect
#
# Usage: bash scripts/git-pin.sh   (called from deploy-headless.sh, AFTER
# bash53.sh so the build toolchain is guaranteed, BEFORE user.sh so git
# identity config and any later git invocations see the pinned binary).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

GIT_PREFIX=/opt/git-2.56.0
GIT_VERSION=2.56.0
GIT_TARBALL_URL="https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz"

if [ -x "$GIT_PREFIX/bin/git" ]; then
	info "git ${GIT_VERSION} already provisioned at $GIT_PREFIX/bin/git"
	"$GIT_PREFIX/bin/git" --version
	exit 0
fi

info "git ${GIT_VERSION} not found — building from $GIT_TARBALL_URL"

# ── Toolchain (idempotent; build-essential already installed by system.sh
# on most VMs, but spelled out here so a fresh image without L2's package
# set doesn't break). ──
# Cargo is required for git 2.49+ because libgitcore (Rust bindings used
# by `make all`) links a Rust static lib. Without it, `make` fails with
# `cargo: not found` / Error 127 — observed in head deploy 37075271395.
# apt_install is idempotent so re-runs are no-ops; the rustc dependency
# is pulled in by the cargo apt package on noble.
apt_install build-essential
apt_install libcurl4-openssl-dev
apt_install libssl-dev
apt_install libexpat1-dev
apt_install gettext
apt_install zlib1g-dev
apt_install cargo
apt_install wget

WORK=$(mktemp -d)
# shellcheck disable=SC2064  # we want $WORK captured NOW, not at signal time
trap "rm -rf '$WORK'" EXIT

info "Fetching $GIT_TARBALL_URL"
if ! wget -q --show-progress=off "$GIT_TARBALL_URL" -O "$WORK/git.tar.gz"; then
	error "wget failed for $GIT_TARBALL_URL (workdir preserved at $WORK for diagnostics)"
	trap - EXIT
	exit 1
fi

info "Extracting"
tar -xzf "$WORK/git.tar.gz" -C "$WORK"
SRC_DIR=$(find "$WORK" -maxdepth 1 -type d -name "git-${GIT_VERSION}*" | head -1)
if [ -z "$SRC_DIR" ]; then
	error "Could not locate extracted git-${GIT_VERSION}* directory under $WORK"
	exit 1
fi

pushd "$SRC_DIR" >/dev/null
info "Configuring --prefix=$GIT_PREFIX"
if ! ./configure --prefix="$GIT_PREFIX"; then
	popd >/dev/null
	error "./configure failed for git ${GIT_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
info "Building (nproc=$(nproc))"
if ! make -j"$(nproc)" all; then
	popd >/dev/null
	error "make failed for git ${GIT_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
info "Installing to $GIT_PREFIX"
if ! make install; then
	popd >/dev/null
	error "make install failed for git ${GIT_VERSION} (workdir preserved at $WORK)"
	exit 1
fi
popd >/dev/null

if [ ! -x "$GIT_PREFIX/bin/git" ]; then
	error "git ${GIT_VERSION} build/install completed but $GIT_PREFIX/bin/git missing"
	exit 1
fi

# Shadow the distro git (/usr/bin/git 2.43.x) with the pinned build.
# /usr/local/bin precedes /usr/bin on the default Ubuntu PATH, so a
# symlink per binary wins without touching apt state. Loop over bin/*
# so git-* helpers (git-receive-pack, git-upload-pack, …) are covered
# too — those matter for SSH-based git operations over the wire.
# Idempotent: ln -sf re-links on re-run.
for bin in "$GIT_PREFIX"/bin/*; do
	[ -e "$bin" ] || continue
	ln -sf "$bin" "/usr/local/bin/$(basename "$bin")"
done

INSTALLED_VERSION=$("$GIT_PREFIX/bin/git" --version)
info "git ${INSTALLED_VERSION} provisioned at $GIT_PREFIX/bin/git (shadowing /usr/bin/git)"
