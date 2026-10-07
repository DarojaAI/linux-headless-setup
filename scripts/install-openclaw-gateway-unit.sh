#!/usr/bin/env bash
# install-openclaw-gateway-unit.sh — install + enable the OpenClaw gateway
# USER systemd unit (openclaw-gateway.service) into
# ~APP_USER/.config/systemd/user/. Fix B (structural, L2-owned install) for
# the head-gateway unit-void class: after a rollback sweep the VM can end up
# with NO openclaw-gateway.service user unit and nothing reinstalls it. This
# script is that reinstall path.
#
# Ownership split (linux-desktop-seed commit 95214c07): L3 owns
# orchestration, L3b owns defaults, L2 owns install. This script is the L2
# install layer. It creates the unit ONLY; it NEVER creates/modifies the
# override.conf under the .service.d/ dir (that file is owned by the L3
# deploy chain — we just make sure the dir exists so the chain can drop its
# overrides in).
#
# R1-migration seam: if /tmp/r1-migration-deploy exists, the unit is
# installed + enabled but NOT started — the L3 deploy chain owns the start.
# Otherwise we start it and fail loud (rc=1) if it does not go active.
#
# Usage:
#   sudo bash scripts/install-openclaw-gateway-unit.sh         # install + enable (+ start unless R1 marker)
#   sudo bash scripts/install-openclaw-gateway-unit.sh --check # exit 0 if unit file present, 1 if missing (no side effects)
#   APP_USER=foo GATEWAY_UNIT_BASE=/tmp sudo bash scripts/install-openclaw-gateway-unit.sh  # env seams
#
# Required tools: systemctl, sudo, loginctl, node, openclaw

set -euo pipefail

# ── Bash ≥ 5.3 gate (same abort-cleanly style as install-openclaw-compact.sh) ──
# On bash 5.2.21 (Ubuntu 24.04 default), `set -euo pipefail` + lib.sh's
# ERR trap + nested `bash` invocation segfaults (exit 139 SIGSEGV). We do
# NOT source lib.sh nor depend on any ERR trap here; a bare substring match
# on BASH_VERSION is the safe refusal path.
if [ -n "${BASH_VERSION:-}" ] && \
   ! { printf '%s\n' "$BASH_VERSION" | grep -Eq '^(5\.[3-9]|[6-9]\.|[0-9]{2,})'; }; then
  >&2 echo "FATAL: install-openclaw-gateway-unit.sh requires bash >= 5.3 (this is bash ${BASH_VERSION})."
  >&2 echo "  Ubuntu 24.04 ships bash 5.2 by default. Install bash 5.3 from upstream:"
  >&2 echo "    wget https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz"
  >&2 echo "    cd bash-5.3 && ./configure --prefix=/opt/bash-5.3 --enable-readline && make -j2 && make install"
  >&2 echo "  Then invoke this script with /opt/bash-5.3/bin/bash."
  >&2 echo "  Or run deploy-headless.sh, which routes through /opt/bash-5.3/bin/bash."
  exit 1
fi

# No lib.sh sourcing — the 2026-08-14 ERR-trap SIGSEGV incident (bash 5.2.x
# AND 5.3.x segfault (exit 139) while bash processes the trap-armed import
# under `set -euo pipefail`) bans it. Inline the three logging helpers.

info()  { echo "[$(date -Iseconds)] [INFO]  $*"; }
warn()  { echo "[$(date -Iseconds)] [WARN]  $*"; }
error() { echo "[$(date -Iseconds)] [ERROR] $*"; }

# ── Config ──
APP_USER="${APP_USER:-desktopuser}"
# Test-only seam: base dir for the unit install. Production default /home so
# the unit lands at /home/$APP_USER/.config/systemd/user/...
GATEWAY_UNIT_BASE="${GATEWAY_UNIT_BASE:-/home}"
UNIT_REL_DIR=".config/systemd/user"
UNIT_DIR="$GATEWAY_UNIT_BASE/$APP_USER/$UNIT_REL_DIR"
UNIT_FILE="$UNIT_DIR/openclaw-gateway.service"
OVERRIDE_DIR="$UNIT_FILE.d"
R1_MARKER="/tmp/r1-migration-deploy"

# Resolve node + openclaw paths at install time; fall back to /usr/bin.
NODE_PATH="${NODE_PATH:-$(command -v node 2>/dev/null || echo /usr/bin/node)}"
OPENCLAW_PATH="${OPENCLAW_PATH:-$(command -v openclaw 2>/dev/null || echo /usr/bin/openclaw)}"

# ── Unit content (L2 owns install; the file itself is the L2 contract) ──
render_unit() {
  cat <<EOF
[Unit]
Description=OpenClaw Gateway
After=network-online.target
Wants=network-online.target
StartLimitBurst=5
StartLimitIntervalSec=60

[Service]
ExecStart=$NODE_PATH $OPENCLAW_PATH gateway --port 18789
Restart=always
RestartSec=5
RestartPreventExitStatus=78
# 330s: openclaw doctor requires an effective stop timeout >= 330s for its
# drain; the old 30s made doctor abort maintenance with
# "330s or longer is required" (head h45 37696901436 step 41).
TimeoutStopSec=330
TimeoutStartSec=30
SuccessExitStatus=0 143
KillMode=control-group

[Install]
WantedBy=default.target
EOF
}

# ── --check: presence probe, no side effects (L3 chain gates on this) ──
check() {
  if [ -f "$UNIT_FILE" ]; then
    echo "$UNIT_FILE present"
    exit 0
  fi
  echo "$UNIT_FILE missing"
  exit 1
}

# ── install ──
install() {
  if [ "$EUID" -ne 0 ]; then
    echo "ERROR: must run as root (the unit lives under $GATEWAY_UNIT_BASE/$APP_USER/$UNIT_REL_DIR; install + systemctl --user need root)" >&2
    exit 1
  fi

  mkdir -p "$UNIT_DIR" "$OVERRIDE_DIR"
  # NEVER create/modify override.conf — that is owned by the L3 deploy chain.

  desired="$(render_unit)"
  if [ -f "$UNIT_FILE" ] && [ "$(cat "$UNIT_FILE")" = "$desired" ]; then
    info "$UNIT_FILE already current — nothing to write"
  else
    # Idempotent rewrite: stage then atomically move so a crash never
    # leaves a half-written unit.
    tmp="$UNIT_DIR/.openclaw-gateway.service.tmp.$$"
    printf '%s' "$desired" > "$tmp"
    chmod 0644 "$tmp"
    mv -f "$tmp" "$UNIT_FILE"
    chmod 0644 "$UNIT_FILE"
    info "wrote $UNIT_FILE"
  fi
  chmod 0644 "$UNIT_FILE"

  # Service dir ownership belongs to the app user (they own the user manager).
  chown -R "$APP_USER:$APP_USER" "$UNIT_DIR"

  # Enable linger for the user manager to survive logout/boot (best-effort:
  # warn on failure rather than aborting the install).
  if ! loginctl enable-linger "$APP_USER" 2>/dev/null; then
    warn "loginctl enable-linger $APP_USER failed — user manager may not persist across logout; unit still installed/enabled"
  fi

  uid="$(id -u "$APP_USER")"
  userctl() { sudo -u "$APP_USER" XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user "$@"; }

  userctl daemon-reload
  # Always enable (idempotent). Start is conditional on the R1 marker below.
  userctl enable openclaw-gateway.service

  if [ -f "$R1_MARKER" ]; then
    info "R1-migration mode: leaving gateway stopped (deploy chain owns the start)"
  else
    userctl start openclaw-gateway.service
    if ! userctl is-active --quiet openclaw-gateway.service; then
      error "openclaw-gateway.service failed to reach active state (systemctl --user is-active returned non-zero)"
      exit 1
    fi
    info "openclaw-gateway.service started + active"
  fi

  info "Installed openclaw-gateway.service (ExecStart=$NODE_PATH $OPENCLAW_PATH gateway --port 18789)"

  # Exit-boundary disarm (same class as install-openclaw-compact.sh): clear
  # any ERR trap + errexit so bash's cleanup race unwinds cleanly. Install
  # already succeeded; nothing here is actionable.
  trap - ERR
  set +e
  set +o pipefail 2>/dev/null || true
  return 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) check ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

trap - ERR
set +e
set +o pipefail 2>/dev/null || true
install