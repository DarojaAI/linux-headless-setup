#!/usr/bin/env bats
# tests/deploy-headless-includes-install-helper.bats
#
# Regression tests for the deploy-headless.sh orchestration shape.
# The install-runtime-seam-binaries.sh step is structurally last and
# bash-5.3-gated for two reasons:
#
#   1. lib.sh ERR-trap SIGSEGV class on bash 5/5.1: the install helper
#      sources lib.sh, which arms an ERR trap. Bash 5.2/5.1 segfault
#      on signal-cleanup under that trap. So the helper MUST run via
#      /opt/bash-5.3/bin/bash like the other gated calls (deploy run
#      31639176531, 2026-08-14, err-139 root cause).
#
#   2. Order matters: openclaw-prep.sh leaves the user-systemd path
#      ready, and the contract-shape smoke at the bottom of the install
#      helper wants the runtime wired up. Reordering it would silently
#      break wire-compat with the L3a fallback library in
#      linux-desktop-seed#1428. The helper's contract-shape smoke
#      would still pass (binaries are executable), but the deployment-
#      time user_systemd_running signal would be unhealthy because the
#      user bus hasn't been set up yet. That's the bug class this
#      regression test closes.
#
# Refs: DarojaAI/linux-headless-setup PR #39 (binary shipping) and the
# followup chore/install-helper-into-deploy-driver.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DEPLOY="$REPO_ROOT/deploy-headless.sh"
}

@test "deploy-headless.sh exists at the canonical path" {
  [ -f "$DEPLOY" ]
}

@test "deploy-headless.sh invokes install-runtime-seam-binaries.sh" {
  # Belt: if the helper invocation is removed entirely (e.g. merge
  # conflict strips the block), this catches it.
  grep -qE 'install-runtime-seam-binaries\.sh' "$DEPLOY"
}

@test "install-runtime-seam-binaries.sh is invoked under the bash-5.3 gate" {
  # The grep must hit a line that uses the $BASH variable, not a
  # naked `bash $SCRIPT_DIR/scripts/install-runtime-seam-binaries.sh`.
  # Pattern: the line containing install-runtime-seam-binaries.sh must
  # ALSO reference the $BASH variable via the standard invocation shape.
  # Anchor: every gated call ends with `"$BASH" "$SCRIPT_DIR/scripts/...`.
  local helper_line
  helper_line="$(grep -nE 'install-runtime-seam-binaries\.sh' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  [ -n "$helper_line" ]
  # Same line number must reference the BASH variable in `"$BASH"` form
  # (one of the existing direct invocations) — check the surrounding
  # 5-line window to allow for the trailing comment block the
  # deploy-headless.sh edit introduced.
  sed -n "$((helper_line-5)),$((helper_line+2))p" "$DEPLOY" | grep -q '"$BASH"'
}

@test "install-runtime-seam-binaries.sh is the LAST gated invocation" {
  # Belt-and-suspenders for the order invariant. Locate every
  # `"$BASH" "$SCRIPT_DIR/scripts/*.sh"` invocation line, take the
  # last, and assert it's install-runtime-seam-binaries.sh.
  local last_gated_line
  last_gated_line="$(grep -nE '"\$BASH" "\$SCRIPT_DIR/scripts/.*\.sh"' "$DEPLOY" \
                     | tail -n 1)"
  echo "$last_gated_line" | grep -q 'install-runtime-seam-binaries\.sh'
}

@test "openclaw-prep.sh precedes install-runtime-seam-binaries.sh" {
  # The order matters: openclaw-prep.sh must be before
  # install-runtime-seam-binaries.sh or the user-systemd runtime is
  # not yet wired when the helper runs.
  local openclaw_line helper_line
  openclaw_line="$(grep -nE 'openclaw-prep\.sh' "$DEPLOY" \
                   | grep -E '"\$BASH"' | head -n 1 | cut -d: -f1)"
  helper_line="$(grep -nE 'install-runtime-seam-binaries\.sh' "$DEPLOY" \
                 | grep -E '"\$BASH"' | head -n 1 | cut -d: -f1)"
  [ -n "$openclaw_line" ]
  [ -n "$helper_line" ]
  [ "$openclaw_line" -lt "$helper_line" ]
}

@test "deploy-headless.sh does NOT directly bash scripts/install-runtime-seam-binaries.sh ungated" {
  # Anti-regression: nobody adds a `bash $SCRIPT_DIR/scripts/install-
  # runtime-seam-binaries.sh` line that bypasses the bash-5.3 gate.
  ! grep -nE '^[^"]*bash "[^"]*scripts/install-runtime-seam-binaries\.sh"' "$DEPLOY"
}

@test "deploy-headless.sh comment block explains the ordering invariant" {
  # Future maintainers need this comment or they'll reorder the helper
  # invocation mid-sequence, silently breaking the contract-shape smoke.
  # The block must be physically near the invocation line.
  local helper_line
  helper_line="$(grep -nE 'install-runtime-seam-binaries\.sh' "$DEPLOY" \
                | grep -E '"\$BASH"' | head -n 1 | cut -d: -f1)"
  [ -n "$helper_line" ]
  # The 10-line window above the invocation must reference either the
  # bash-5.3 ERR-trap SIGSEGV class OR the contract compat. Either
  # is enough.
  local window
  window="$(sed -n "$((helper_line-10)),$((helper_line-1))p" "$DEPLOY")"
  echo "$window" | grep -qE 'SIGSEGV|lib\.sh|contract|MUST'
}

@test "deploy-headless.sh final info log still says 'complete'" {
  # Regression: don't accidentally remove the closing log line.
  grep -qE 'deploy-headless\.sh complete' "$DEPLOY"
}
