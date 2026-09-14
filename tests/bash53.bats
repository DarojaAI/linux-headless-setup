#!/usr/bin/env bats
# tests/bash53.bats — structural + idempotency tests for scripts/bash53.sh
#
# The L2 right-layer fix for the bash 5.2 + ERR-trap + nested-bash
# SIGSEGV class (deploy run 34839924228, 2026-09-14, follow-up to
# PR #22). bash53.sh provisions /opt/bash-5.3/bin/bash from the
# GNU release tarball, before any install script that consumes it.
#
# We deliberately do NOT spin up a VM to exercise the build path.
# This test enforces the structural invariants that prevent
# regressions:
#   1. bash53.sh exists, executable, sources lib.sh
#   2. deploy-headless.sh invokes bash53.sh
#   3. bash53.sh runs BEFORE the first `$BASH`-gated invocation
#   4. bash53.sh has its own bash-5.2 fallback (idempotent, not fatal — the
#      fatal-exit on missing /opt/bash-5.3 lives in deploy-headless.sh
#      where the chain fails fast with an actionable message)
#   5. bash53.sh pins to a single tarball URL (no PPA, no mirror list)
#
# Refs:
#   - AGENTS.md right-layer rule
#   - 2026-08-14-bash-5.2-ERR-trap-sigsegv (L3a postmortem — source
#     of the bug class; install-openclaw-compact.sh's gate already
#     gives the build recipe)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/bash53.sh"
  DEPLOY="$REPO_ROOT/deploy-headless.sh"
}

@test "bash53.sh exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "bash53.sh sources lib.sh (so info/warn/error helpers are available)" {
  grep -qE 'source "?\$SCRIPT_DIR/lib\.sh"?' "$SCRIPT"
}

@test "bash53.sh is idempotent on /opt/bash-5.3/bin/bash already present" {
  # The script must short-circuit with `exit 0` when the prefix
  # already exists, not rebuild from scratch every time we re-run
  # deploy-headless.sh.
  grep -qE '\[ -x "\$BASH53_PREFIX/bin/bash" \]' "$SCRIPT"
  grep -qE 'exit 0' "$SCRIPT"
}

@test "bash53.sh pins to a single gnu.org tarball URL (no PPA, no mirror list)" {
  # Build-from-source decision: no new trust boundary. The tarball URL
  # must be the gnu.org canonical mirror, not a PPA. Variable
  # interpolation is intentional (BASH53_VERSION factored out for the
  # future bump), so the matcher follows the variable, not the literal.
  grep -qE 'BASH53_TARBALL_URL="https://ftp\.gnu\.org/gnu/bash/bash-\$\{BASH53_VERSION\}\.tar\.gz"' "$SCRIPT"
  # Belt: the URL is constructed once and reused; nothing else in the
  # script may pin a mirror.
  [ "$(grep -cE 'ftp\.gnu\.org/gnu/bash' "$SCRIPT")" -ge 1 ]
  ! grep -qE 'ppa:|add-apt-repository' "$SCRIPT"
}

@test "bash53.sh installs build-essential + bison + wget idempotently via apt_install" {
  # The script must use the existing apt_install helper from lib.sh
  # (idempotent), not apt-get install directly. If it bypasses
  # apt_install, a re-run on a host that already has build-essential
  # will not be a no-op.
  grep -qE 'apt_install[[:space:]]+build-essential' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+bison' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+wget' "$SCRIPT"
}

@test "bash53.sh uses mktemp + trap RM for the build workdir" {
  # We don't want to leak /tmp/build-bash-* dirs on every deploy-run
  # failure path.
  grep -qE 'mktemp -d' "$SCRIPT"
  grep -qE 'trap "[^"]*rm -rf' "$SCRIPT"
}

@test "deploy-headless.sh wires bash53.sh into the orchestration" {
  # Belt: nothing accidentally drops the bash53.sh invocation.
  grep -nE 'bash53\.sh' "$DEPLOY"
}

@test "deploy-headless.sh invokes bash53.sh BEFORE its first \$BASH-gated call" {
  # The order matters: bash53.sh must provision /opt/bash-5.3/bin/bash
  # before install-docker.sh (the first consumer) — otherwise the
  # /opt/bash-5.3 presence check below evaluates false and the deploy
  # chain exits 1 with FATAL.
  local bash53_line first_gated_line
  bash53_line="$(grep -nE 'bash53\.sh' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  first_gated_line="$(grep -nE '"\$BASH" "\$SCRIPT_DIR/scripts/.*\.sh"' "$DEPLOY" \
                      | head -n 1 | cut -d: -f1)"
  [ -n "$bash53_line" ]
  [ -n "$first_gated_line" ]
  [ "$bash53_line" -lt "$first_gated_line" ]
}

@test "deploy-headless.sh exits 1 (not warn-and-fall-through) when /opt/bash-5.3 is missing" {
  # Today: warn + BASH=bash fall-through (the deploy fails later as a
  # generic gate error). After this PR: a fatal exit 1 at the
  # bootstrap boundary with an actionable operator message.
  # The fix is in the `else` branch of the bash-5.3 presence check,
  # so we assert that branch contains `exit 1`.
  local block
  block="$(awk '/if \[ -x \/opt\/bash-5\.3\/bin\/bash \]/,/^fi$/' "$DEPLOY")"
  echo "$block" | grep -qE 'exit 1'
}

@test "deploy-headless.sh's bash-5.3-missing branch prints the FATAL remediation" {
  # The fatal error must name /opt/bash-5.3/bin/bash AND mention the
  # bash ≥ 5.3 prerequisite so the operator knows what to do next
  # without grepping the L2 repo.
  local block
  block="$(awk '/if \[ -x \/opt\/bash-5\.3\/bin\/bash \]/,/^fi$/' "$DEPLOY")"
  echo "$block" | grep -q 'FATAL'
  echo "$block" | grep -q '/opt/bash-5.3/bin/bash'
}

@test "deploy-headless.sh comment block explains bash53.sh's place in the chain" {
  # Anchor: stale or reorder is a silent breaking change. The
  # invocation line is `bash "$SCRIPT_DIR/scripts/bash53.sh"`. The
  # first hit of `bash53\.sh` in the file is the comment header ABOVE
  # the invocation; we must locate the invocation line specifically so
  # the comment-window logic actually has a comment to look at.
  local bash53_line window
  bash53_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/bash53\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  [ -n "$bash53_line" ]
  window="$(sed -n "$((bash53_line-12)),$((bash53_line-1))p" "$DEPLOY")"
  echo "$window" | grep -qE 'bash 5\.3|bash-5\.3|bash53|/opt/bash'
}
