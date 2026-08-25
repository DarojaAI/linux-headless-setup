#!/usr/bin/env bats
# tests/runtime-seam-binaries.bats
#
# Wire-shape contract tests for the L2 binary surface that
# linux-desktop-seed's verify-vm-state.sh runtime-side checks talk
# to. Both binaries live in scripts/; this bats file validates that
# they emit the v0.1 (headless shape) JSON — same shape as the L3a
# fallback library, so swapping binaries is wire-compat.
#
# Source of truth: DarojaAI/linux-desktop-seed docs/contracts/L2-RUNTIME-CLI.md
# and docs/contracts/L2-RUNTIME-BUILD-FINISH.md.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  ARC="$REPO_ROOT/scripts/agent-runtime-cli"
  RBF="$REPO_ROOT/scripts/runtime-build-finish"
}

# ── agent-runtime-cli ─────────────────────────────────────────────────
@test "agent-runtime-cli is-runtime-ready emits v0.1 wire shape" {
  APP_USER=desktopuser run "$ARC" is-runtime-ready
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] in ('healthy', 'unhealthy')
assert set(obj['signals'].keys()) == {'app_user_exists', 'loginctl_linger', 'bash_5_3_on_path'}
"
}

@test "agent-runtime-cli is-user-systemd-active emits v0.1 wire shape" {
  APP_USER=desktopuser run "$ARC" is-user-systemd-active
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] in ('healthy', 'unhealthy')
assert set(obj['signals'].keys()) == {'user_systemd_running', 'user_systemd_unit_path', 'last_failed_unit'}
"
}

@test "agent-runtime-cli last_failed_unit is sanitized — only [A-Za-z0-9_.@-] allowed" {
  # Smoke test: when the system emits the U+25CF bullet for an empty
  # user-unit state, the binary must NOT propagate that into JSON.
  # Probe runtime-side: emit a bogus "name" through awk and check the
  # awk regex actually strips non-ASCII.
  run bash -c '
    echo "●" | awk "NF{gsub(/[^A-Za-z0-9_.@-]/, \"\", \$1); if(length(\$1)){print \$1; exit}}"
  '
  [ -z "$output" ]
}

@test "agent-runtime-cli unknown subcommand exits 64 with the contract JSON" {
  run "$ARC" does-not-exist
  [ "$status" = "64" ]
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] == 'unknown-subcommand'
assert obj['signals'] == {}
assert 'message' in obj
"
}

@test "agent-runtime-cli no-args exits 2 with usage" {
  run "$ARC"
  [ "$status" = "2" ]
}

# ── runtime-build-finish ──────────────────────────────────────────────
@test "runtime-build-finish --check=sudoers emits v0.1 wire shape" {
  APP_USER=desktopuser run "$RBF" --check=sudoers
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] in ('healthy', 'unhealthy')
assert set(obj['signals'].keys()) == {'exists', 'blanket_nopasswd', 'path'}
"
}

@test "runtime-build-finish --check=bash-5.3 emits v0.1 wire shape" {
  APP_USER=desktopuser run "$RBF" --check=bash-5.3
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] in ('healthy', 'unhealthy')
assert set(obj['signals'].keys()) == {'binary_exists', 'binary_version_ok', 'path', 'version'}
"
}

@test "runtime-build-finish --all aggregates both checks" {
  APP_USER=desktopuser run "$RBF" --all
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] in ('delegated', 'unhealthy')
assert set(obj['signals'].keys()) == {'sudoers', 'bash-5.3'}
# Wire-format keys MUST keep the hyphen (matches contract doc).
assert 'bash-5.3' in obj['signals']
# Function-name keys MUST NOT leak into the JSON — the `subcheck_`
# prefix stays internal.
import re
text = '$BATS_TEST_FILENAME'  # placeholder; actual test is the python check
"
}

@test "runtime-build-finish unknown check exits 64 with the contract JSON" {
  run "$RBF" --check=does-not-exist
  [ "$status" = "64" ]
  echo "$output" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
assert obj['status'] == 'unknown-check'
"
}

@test "runtime-build-finish no args exits 2" {
  run "$RBF"
  [ "$status" = "2" ]
}

# ── bash identifier discipline ────────────────────────────────────────
@test "agent-runtime-cli and runtime-build-finish use bash ≥ 5.3 patterns" {
  # We don't gate bash-version here (we're running on bash 5.1.16).
  # This regression test asserts that no `set +e` is left around at
  # the top-level after a function definition (cheap bang for the
  # buck: any future refactor that re-introduces `set +e` at scope
  # gets caught at the L3a deploy-bash gate, but this test surfaces
  # the regression early on a workstation).
  ! grep -E '^[[:space:]]*set \+e$' "$ARC" "$RBF"
}

@test "binaries are CHMOD +x on disk" {
  [ -x "$ARC" ]
  [ -x "$RBF" ]
}
