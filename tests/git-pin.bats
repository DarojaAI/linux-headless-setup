#!/usr/bin/env bats
# tests/git-pin.bats — structural + idempotency tests for scripts/git-pin.sh
#
# git-pin.sh provisions /opt/git-2.56.0/bin/git from the kernel.org
# release tarball, shadowing Ubuntu's floating git 2.43.x. Same
# build-from-source rationale as bash53.sh (no PPA trust boundary,
# reproducible across Hetzner / GitHub-runner / dev-VM images).
#
# We deliberately do NOT spin up a VM to exercise the full build (that
# is what the deploy's integration run does). This test enforces the
# structural invariants that prevent regressions:
#   1. git-pin.sh exists, executable, sources lib.sh
#   2. deploy-headless.sh invokes git-pin.sh
#   3. git-pin.sh runs AFTER bash53.sh and BEFORE user.sh (toolchain
#      guaranteed before the pin; git identity + later git calls see
#      the pinned binary)
#   4. git-pin.sh is idempotent on /opt/git-2.56.0/bin/git already present
#   5. git-pin.sh pins to a single kernel.org tarball URL (no PPA,
#      no mirror list)
#   6. git-pin.sh shadows the distro binary via /usr/local/bin symlinks
#
# Refs:
#   - AGENTS.md right-layer rule
#   - bash53.sh precedent (same build-from-source pattern)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/git-pin.sh"
  DEPLOY="$REPO_ROOT/deploy-headless.sh"
}

@test "git-pin.sh exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "git-pin.sh sources lib.sh (so info/warn/error helpers are available)" {
  grep -qE 'source "?\$SCRIPT_DIR/lib\.sh"?' "$SCRIPT"
}

@test "git-pin.sh is idempotent on /opt/git-2.56.0/bin/git already present" {
  grep -qE '\[ -x "\$GIT_PREFIX/bin/git" \]' "$SCRIPT"
  grep -qE 'exit 0' "$SCRIPT"
}

@test "git-pin.sh pins to a single kernel.org tarball URL (no PPA, no mirror list)" {
  grep -qE 'GIT_TARBALL_URL="https://www\.kernel\.org/pub/software/scm/git/git-\$\{GIT_VERSION\}\.tar\.gz"' "$SCRIPT"
  [ "$(grep -cE 'kernel\.org/pub/software/scm/git' "$SCRIPT")" -ge 1 ]
  ! grep -qE 'ppa:|add-apt-repository' "$SCRIPT"
}

@test "git-pin.sh installs build toolchain idempotently via apt_install" {
  grep -qE 'apt_install[[:space:]]+build-essential' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+libcurl4-openssl-dev' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+libssl-dev' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+libexpat1-dev' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+gettext' "$SCRIPT"
  grep -qE 'apt_install[[:space:]]+zlib1g-dev' "$SCRIPT"
}

@test "git-pin.sh uses mktemp + trap RM for the build workdir" {
  grep -qE 'mktemp -d' "$SCRIPT"
  grep -qE 'trap "[^"]*rm -rf' "$SCRIPT"
}

@test "git-pin.sh shadows distro git via /usr/local/bin symlinks" {
  grep -qE 'ln -sf "\$bin" "/usr/local/bin/\$\(basename "\$bin"\)"' "$SCRIPT"
}

@test "deploy-headless.sh wires git-pin.sh into the orchestration" {
  grep -nE 'git-pin\.sh' "$DEPLOY"
}

@test "deploy-headless.sh runs git-pin.sh AFTER bash53.sh and BEFORE user.sh" {
  local bash53_line git_line user_line
  bash53_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/bash53\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  git_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/git-pin\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  user_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/user\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  [ -n "$bash53_line" ]
  [ -n "$git_line" ]
  [ -n "$user_line" ]
  [ "$bash53_line" -lt "$git_line" ]
  [ "$git_line" -lt "$user_line" ]
}

@test "deploy-headless.sh comment block explains git-pin.sh's place in the chain" {
  local git_line window
  git_line="$(grep -nE 'bash "\$SCRIPT_DIR/scripts/git-pin\.sh"' "$DEPLOY" | head -n 1 | cut -d: -f1)"
  [ -n "$git_line" ]
  window="$(sed -n "$((git_line-13)),$((git_line-1))p" "$DEPLOY")"
  echo "$window" | grep -qE 'git-pin\.sh|2\.56|kernel\.org'
}
