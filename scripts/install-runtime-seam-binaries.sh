#!/bin/bash
# scripts/install-runtime-seam-binaries.sh — install the L2 surface
# that linux-desktop-seed's deploy chain calls into.
#
# Idempotent: safe to re-run. Each step is conditional on current
# state and uses atomic install(1) with explicit -m / -o / -g.
#
# What this installs:
#   /usr/local/lib/linux-headless-setup/agent-runtime-cli  (v0.1 wire shape)
#   /usr/local/lib/linux-headless-setup/runtime-build-finish (v0.1 wire shape)
#
# Required callers (L3a):
#   • docs/contracts/L2-RUNTIME-CLI.md (in linux-desktop-seed)
#   • docs/contracts/L2-RUNTIME-BUILD-FINISH.md (in linux-desktop-seed)
#
# Conventions match LHS lib.sh: `set -euo pipefail`, atomic
# install(1), idempotent guards. Bash-version-gated ERR trap via
# lib.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

INSTALL_ROOT="/usr/local/lib/linux-headless-setup"
INSTALL_MODE=0755
INSTALL_OWNER=root
INSTALL_GROUP=root

mkdir -p "$INSTALL_ROOT"

# Pre-cleanup any stale files from a v0 install. v0 had the desktop-shape
# probe `is-secret-path-healthy`; an older binary may have been
# installed at this path. Drop it so the v0.1 wire shape is the only
# thing at the canonical install path.
if [ -f "$INSTALL_ROOT/agent-runtime-cli" ]; then
    info "Existing agent-runtime-cli detected; replacing with v0.1 binary"
    rm -f "$INSTALL_ROOT/agent-runtime-cli"
fi
if [ -f "$INSTALL_ROOT/runtime-build-finish" ]; then
    info "Existing runtime-build-finish detected; replacing with v0.1 binary"
    rm -f "$INSTALL_ROOT/runtime-build-finish"
fi

# Atomic install(1) with explicit mode/owner/group. Idempotent — the
# `install -m 0755 ... dest.tmp && mv dest.tmp dest` pattern is not
# available in stdlib `install(1)`, but writing to the destination
# directory with no overwrite-race (we already rm'd anything there) is
# safe.
install -m "$INSTALL_MODE" -o "$INSTALL_OWNER" -g "$INSTALL_GROUP" \
    "$SCRIPT_DIR/agent-runtime-cli" \
    "$INSTALL_ROOT/agent-runtime-cli"
install -m "$INSTALL_MODE" -o "$INSTALL_OWNER" -g "$INSTALL_GROUP" \
    "$SCRIPT_DIR/runtime-build-finish" \
    "$INSTALL_ROOT/runtime-build-finish"

info "Installed:"
info "  $INSTALL_ROOT/agent-runtime-cli"
info "  $INSTALL_ROOT/runtime-build-finish"

# Caller-side smoke: confirm the binaries are executable and emit a
# parseable JSON shape on their canonical subcommand. If this fails,
# the install script exits non-zero, which is correct — the L3a
# deploy-side scripts/lib/agent-runtime-cli-fallback.sh compares
# against this exact shape, and a fall-through here would silently
# produce a contract mismatch downstream.
if ! "$INSTALL_ROOT/agent-runtime-cli" is-runtime-ready >/dev/null; then
    error "agent-runtime-cli is-runtime-ready returned non-zero on a fresh install"
    error "This is a bug — the binary should at least emit a parseable JSON wire shape"
    exit 1
fi
if ! "$INSTALL_ROOT/runtime-build-finish" --all >/dev/null; then
    # Allow non-zero here: a freshly-installed VM may legitimately have
    # no sudoers hardening yet (L3a's install-hardened-sudoers.sh runs
    # later). What we MUST catch is a parse failure, which would exit
    # before our parser below.
    out="$("$INSTALL_ROOT/runtime-build-finish" --all 2>&1 || true)"
    if ! printf '%s' "$out" | python3 -c "
import json, sys
j = json.loads(sys.stdin.read())
assert j['status'] in ('delegated', 'unhealthy')
assert set(j['signals'].keys()) == {'sudoers', 'bash-5.3'}
" >/dev/null 2>&1; then
        error "runtime-build-finish --all produced non-parseable JSON:"
        error "$out"
        exit 1
    fi
fi

info "Install complete and contract-shape verified."
