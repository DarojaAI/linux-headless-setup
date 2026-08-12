#!/bin/bash
# install-docker.sh — Install Docker for the OpenClaw agent sandbox
#
# Part of the 2026-06-22 agent-test-broke-prod recovery (Layer 2: agent
# sandbox). Docker provides the per-session sandbox for agent exec
# operations. The sandbox is configured in linux-desktop-seed
# (agents.defaults.sandbox.backend = "docker") and assumes Docker is
# installed + daemon is running + APP_USER is in the docker group.
#
# Why Docker (not SSH-to-sandbox-VM): for the current single-operator-agent
# threat model, Docker on this VM with --read-only + --cap-drop=ALL +
# --network=none + no-bind-mount is sufficient. The blast radius of a
# compromised agent is the container, not prod state. SSH-to-sandbox-VM
# was the original plan but is over-engineered for now; deferred.
#
# Idempotent: safe to re-run.
#
# This file lives at scripts/install-docker.sh in linux-headless-setup.
# It is invoked from deploy-headless.sh after runtimes.sh and before
# openclaw-prep.sh (so the directories openclaw-prep.sh creates exist
# when the daemon is started).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting Docker installation (for OpenClaw agent sandbox)..."

# ── 1. Install docker.io ──
# docker.io is in Ubuntu 24.04 main repos. Avoids the Docker repo
# dance (apt key, sources.list.d entry) and matches the existing
# apt_install pattern in runtimes.sh.
apt_install docker.io

# ── 2. Daemon config ────────────────────────────────────────────────────────────────────────
# These are the defaults we'd want anyway; writing them explicitly
# means a future apt upgrade that touches /etc/docker/daemon.json
# doesn't silently change behavior.
#
# - userland-proxy: false      — iptables-based port forwarding only; smaller surface
# - log-driver: journald       — log to systemd journal; integrates with monitoring.sh
# - live-restore: true         — keep containers running across daemon restarts
# - storage-driver: overlay2    — Ubuntu 24.04 default; explicit so an apt
#                                 change can't swap it for vfs (which would
#                                 silently 10x disk usage)
# - iptables: true             — required for bridge networking on most distros
# - ip-forward: true           — required so dockerd's bridge network can
#                                 forward packets between host and containers.
#                                 Without this, every 'docker run' prints
#                                 'WARNING: IPv4 forwarding is disabled.
#                                 Networking will not work.'
# - ipv6-forwarding: true      — same as above for IPv6
# - dns: ["8.8.8.8","1.1.1.1"] — dockerd defaults to inheriting host DNS
#                                 (185.12.64.1/2 on Hetzner). Those don't
#                                 respond from inside the container network
#                                 namespace, breaking apt-get in builds.
#                                 Use external upstreams explicitly.
#
# Merge semantics: on first install we write the full template; on re-runs
# we JSON-merge the above into whatever's already on disk so operator
# customizations are preserved while adding any missing keys.
DAEMON_JSON=/etc/docker/daemon.json

# Defaults that should always be present (additive merge with existing).
DAEMON_DEFAULTS='{
  "log-driver": "journald",
  "live-restore": true,
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "iptables": true,
  "ip-forward": true,
  "ipv6-forwarding": true,
  "dns": ["8.8.8.8", "1.1.1.1"]
}'

mkdir -p "$(dirname "$DAEMON_JSON")"

if [ ! -f "$DAEMON_JSON" ]; then
	info "Writing $DAEMON_JSON (first install)"
	printf '%s\n' "$DAEMON_DEFAULTS" > "$DAEMON_JSON"
else
	info "$DAEMON_JSON already exists; merging missing keys from defaults"
	# python3 -c merge: take existing file as base, overlay defaults on top
	# (defaults only add keys that don't exist; do NOT overwrite operator customizations).
	if ! MERGED=$(python3 -c '
import json, sys
with open("'"$DAEMON_JSON"'") as f:
    base = json.load(f)
with open("/dev/stdin") as f:
    defaults = json.load(f)
for k, v in defaults.items():
    if k not in base:
        base[k] = v
print(json.dumps(base, indent=2))
' <<<"$DAEMON_DEFAULTS" 2>/dev/null); then
		error "$DAEMON_JSON exists but is not valid JSON; refusing to merge"
		error "Fix manually or remove it before re-running install-docker.sh"
		exit 1
	fi
	printf '%s\n' "$MERGED" > "$DAEMON_JSON.tmp"
	mv "$DAEMON_JSON.tmp" "$DAEMON_JSON"
	info "Merged daemon.json:"
	cat "$DAEMON_JSON"
fi

# Persist ip_forward at the kernel level so dockerd doesn't have to set
# it itself; takes effect on sysctl --system. Without this, ip-forward:true
# in daemon.json alone is not enough — see research-orchestrator deploy
# run 31544671328 on ubuntu-8gb-hel1-1 where /proc/sys/net/ipv4/ip_forward=0
# left 'docker run' with 'Networking will not work' even after daemon.json
# was updated.
SYSCTL_DROPIN=/etc/sysctl.d/99-docker-forward.conf
if [ ! -f "$SYSCTL_DROPIN" ]; then
	info "Writing $SYSCTL_DROPIN"
	cat > "$SYSCTL_DROPIN" <<'EOF'
# Applied by install-docker.sh: enable IPv4 + IPv6 forwarding for dockerd
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
	sysctl --system >/dev/null
else
	info "$SYSCTL_DROPIN already exists; not overwriting"
fi

# ── 3. Enable + start the daemon ──
# systemctl enable --now is idempotent: starts if not running, enables
# at boot regardless. The || true around daemon-reload handles the
# case where dockerd isn't installed yet (first-time apt) — we'll
# daemon-reload after the enable step below.
systemctl enable docker.service 2>/dev/null || true
if ! service_active docker; then
	info "Starting docker.service..."
	systemctl daemon-reload || true
	systemctl start docker.service
fi

# ── 4. Wait for the daemon to be reachable ──
# `systemctl is-active` returns success before dockerd has finished
# initializing the socket. Polling `docker info` is the standard way
# to confirm the daemon is responsive.
info "Waiting for docker daemon to be reachable..."
for i in $(seq 1 30); do
	if docker info >/dev/null 2>&1; then
		info "Docker daemon reachable after $((30 - i)) polls"
		break
	fi
	sleep 1
done

if ! docker info >/dev/null 2>&1; then
	error "Docker daemon did not become reachable within 30 seconds"
	exit 1
fi

# ── 5. Add APP_USER to the docker group ──
# Required so agent processes (which run as desktopuser, not root)
# can invoke `docker run` without sudo. Without this, the openclaw
# runtime's docker backend fails at agent-execution time with a
# permission error — and that's the silent-failure mode we're
# trying to avoid.
#
# Idempotent: `usermod -aG` is fine to re-run; gpasswd -a is the
# safer alternative if the user already has the group. We use
# gpasswd because usermod -aG with an existing entry can produce
# duplicate groups in some edge cases.
if id -nG "$APP_USER" | tr ' ' '\n' | grep -qx docker; then
	info "$APP_USER already in docker group"
else
	info "Adding $APP_USER to docker group"
	gpasswd -a "$APP_USER" docker
fi

# ── 6. Smoke test (as APP_USER) ──
# The openclaw sandbox will fail at runtime if this fails. Catch it
# at install time instead. We need to use `su` + `newgrp`-equivalent
# to pick up the group; `sg docker` is the standard pattern.
#
# `docker info` is a no-network-call, no-permission-side-effect probe.
# If it succeeds, the daemon is up and the user has group access.
if su -s /bin/bash "$APP_USER" -c 'sg docker -c "docker info >/dev/null 2>&1"'; then
	info "Docker smoke test passed for $APP_USER"
else
	error "Docker smoke test FAILED for $APP_USER — agent sandbox will not work at runtime"
	exit 1
fi

info "Docker installation complete."