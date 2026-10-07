#!/usr/bin/env bats
# Regression tests for scripts/install-openclaw-gateway-unit.sh — Fix B
# (structural, L2-owned install) for the head-gateway unit-void class: after
# a rollback sweep the VM can have NO openclaw-gateway.service user unit and
# nothing reinstalls it.
#
# After the 2026-08-14 lib.sh ERR-trap SIGSEGV incident, install scripts
# refuse bash < 5.3. These tests route through the repo's $BASH
# (/opt/bash-5.3/bin/bash) like deploy-headless.sh does, and hermeticize the
# system side effects (systemctl / loginctl / sudo) with PATH fakes so the
# host user manager is never touched. GATEWAY_UNIT_BASE is the test-only
# seam that redirects the unit install off the real /home tree.

setup() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/install-openclaw-gateway-unit.bats}")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/install-openclaw-gateway-unit.sh"
  if [ -x /opt/bash-5.3/bin/bash ]; then
    BASH53=/opt/bash-5.3/bin/bash
  else
    BASH53=bash
  fi
  FAKEBIN=""
  FAKE_SYSTEMCTL_LOG=""
  FAKE_LOGINCTL_LOG=""
}

teardown() {
  rm -f /tmp/r1-migration-deploy
  if [ -n "$FAKEBIN" ] && [ -d "$FAKEBIN" ]; then
    rm -rf "$FAKEBIN"
  fi
}

# make_fakes: build a hermetic FAKEBIN dir (fake systemctl / sudo / loginctl)
# prepended to PATH so the script's user-manager calls never touch the real
# system. The fakes record their argv so tests can assert real behavior.
make_fakes() {
  FAKEBIN="$(mktemp -d)"
  FAKE_SYSTEMCTL_LOG="$FAKEBIN/systemctl.log"
  FAKE_LOGINCTL_LOG="$FAKEBIN/loginctl.log"

  cat > "$FAKEBIN/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_SYSTEMCTL_LOG:-/dev/null}"
exit 0
EOF
  cat > "$FAKEBIN/sudo" <<'EOF'
#!/usr/bin/env bash
# Strip -u <user> and any VAR=val arguments (shell passes XDG_RUNTIME_DIR=…
# as a positional), then exec the remainder so the faked systemctl runs.
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -u) shift ;;
    -u*) ;;
    *=*) ;;
    *) args+=("$1") ;;
  esac
  shift
done
exec "${args[@]}"
EOF
  cat > "$FAKEBIN/loginctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_LOGINCTL_LOG:-/dev/null}"
exit 0
EOF

  chmod +x "$FAKEBIN/systemctl" "$FAKEBIN/sudo" "$FAKEBIN/loginctl"
  export PATH="$FAKEBIN:$PATH"
  export FAKE_SYSTEMCTL_LOG FAKE_LOGINCTL_LOG
}

@test "scripts/install-openclaw-gateway-unit.sh passes bash -n syntax check" {
  bash -n "$SCRIPT"
}

@test "script source pins the root check, bash-5.3 gate, unit path, and r1-marker contract (CI: no root/bash-5.3)" {
  grep -qE 'id -u.*ne 0|must run as root' "$SCRIPT"
  grep -q 'requires bash >= 5.3' "$SCRIPT"
  grep -q 'openclaw-gateway.service' "$SCRIPT"
  grep -q 'r1-migration-deploy' "$SCRIPT"
  # override.conf is L3-owned: the installer must never write it
  ! grep -qE '(cat|tee|install)[^#]*(>|into)[^#]*override\.conf' "$SCRIPT"
}

@test "--check exits 1 when unit missing, 0 when present (no side effects)" {
  local base
  base="$(mktemp -d)"
  # Missing → exit 1
  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing"* ]]
  # Present → exit 0 (just create the file; --check must not need root/systemd)
  mkdir -p "$base/desktopuser/.config/systemd/user"
  touch "$base/desktopuser/.config/systemd/user/openclaw-gateway.service"
  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"present"* ]]
  rm -rf "$base"
}

@test "install is idempotent: second run logs already-current and content is unchanged" {
  if [ "$(id -u)" -ne 0 ] || [ ! -x /opt/bash-5.3/bin/bash ]; then
    skip "exec path needs root + /opt/bash-5.3 (CI: source-pattern test covers the contract)"
  fi
  make_fakes
  local base
  base="$(mktemp -d)"

  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"wrote"*"$base/desktopuser/.config/systemd/user/openclaw-gateway.service"* ]]

  local unit="$base/desktopuser/.config/systemd/user/openclaw-gateway.service"
  local before
  before="$(cksum "$unit" | awk '{print $1 $2}')"

  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already current"* ]]

  local after
  after="$(cksum "$unit" | awk '{print $1 $2}')"
  [ "$before" = "$after" ]

  rm -rf "$base"
}

@test "installed unit contains resolved ExecStart with node + openclaw paths" {
  if [ "$(id -u)" -ne 0 ] || [ ! -x /opt/bash-5.3/bin/bash ]; then
    skip "exec path needs root + /opt/bash-5.3 (CI: source-pattern test covers the contract)"
  fi
  make_fakes
  local base
  base="$(mktemp -d)"
  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT"
  [ "$status" -eq 0 ]

  local unit="$base/desktopuser/.config/systemd/user/openclaw-gateway.service"
  local node openclaw
  node="$(command -v node || echo /usr/bin/node)"
  openclaw="$(command -v openclaw || echo /usr/bin/openclaw)"
  grep -F "ExecStart=$node $openclaw gateway --port 18789" "$unit"
  # lock the full expected unit shape
  grep -q '^Restart=always$' "$unit"
  grep -q '^WantedBy=default.target$' "$unit"
  grep -q '^After=network-online.target$' "$unit"
  rm -rf "$base"
}

@test "r1-migration marker present -> start is skipped (enable still runs)" {
  if [ "$(id -u)" -ne 0 ] || [ ! -x /opt/bash-5.3/bin/bash ]; then
    skip "exec path needs root + /opt/bash-5.3 (CI: source-pattern test covers the contract)"
  fi
  make_fakes
  local base
  base="$(mktemp -d)"
  : > /tmp/r1-migration-deploy

  run env GATEWAY_UNIT_BASE="$base" "$BASH53" "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"R1-migration mode: leaving gateway stopped"* ]]

  # Unit was enabled but never started.
  grep -q -- '--user enable openclaw-gateway.service' "$FAKE_SYSTEMCTL_LOG"
  ! grep -q -- '--user start' "$FAKE_SYSTEMCTL_LOG"
  rm -rf "$base"
}

@test "deploy-headless.sh invokes install-openclaw-gateway-unit.sh after install-apt-policy.sh and before the complete echo" {
  local apt_line gate_line complete_line
  apt_line=$(grep -n 'install-apt-policy\.sh' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  gate_line=$(grep -n 'install-openclaw-gateway-unit\.sh' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  complete_line=$(grep -n 'deploy-headless\.sh complete' "$REPO_ROOT/deploy-headless.sh" | head -1 | cut -d: -f1)
  [ -n "$apt_line" ] || { echo "install-apt-policy.sh chain entry not found"; return 1; }
  [ -n "$gate_line" ] || { echo "install-openclaw-gateway-unit.sh chain entry not found"; return 1; }
  [ -n "$complete_line" ] || { echo "complete echo not found"; return 1; }
  [ "$apt_line" -lt "$gate_line" ] || { echo "gate at line $gate_line must be AFTER install-apt-policy.sh at line $apt_line"; return 1; }
  [ "$gate_line" -lt "$complete_line" ] || { echo "gate at line $gate_line must be BEFORE complete echo at line $complete_line"; return 1; }
}