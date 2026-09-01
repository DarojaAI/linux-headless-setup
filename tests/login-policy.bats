#!/usr/bin/env bats
# tests/login-policy.bats
#
# Regression gate for the L2 git-identity append in scripts/user.sh and the
# login-policy drop-in installed by scripts/install-login-policy.sh (issue #F
# (git identity), issue #M (PASS_MAX_DAYS), epic #48).
#
# The git-identity fix stops deploy scripts that call `git commit` inside the
# VM from falling back to the operator name when the agent committer-email is
# unset; the guard makes re-runs silent. The login-policy module drops
# /etc/login.defs.d/99-l2-policy.conf (PASS_MAX_DAYS/PASS_MIN_DAYS/
# PASS_WARN_AGE/UMASK) instead of rewriting /etc/login.defs itself.
#
# All assertions are hermetic: they validate the exact bytes embedded in the
# scripts, not a live VM — no root, systemd, or PAM required.

setup() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/login-policy.bats}")/.." && pwd)"
    USER_SCRIPT="$REPO_ROOT/scripts/user.sh"
    POLICY_SCRIPT="$REPO_ROOT/scripts/install-login-policy.sh"
    DEPLOY="$REPO_ROOT/deploy-headless.sh"
}

@test "user.sh sets the agent git identity email" {
    # The committer-email line must pin the agent identity so in-VM `git
    # commit` never falls back to the operator name.
    grep -qF 'git config --global user.email "agent@daroja.ai"' "$USER_SCRIPT"
}

@test "user.sh git identity is wrapped in an idempotent guard" {
    # Re-deploys must not blindly re-assert the identity: the email line
    # must sit inside an `if` that only sets it when it differs, and the
    # else branch must be a quiet "already set" info.
    grep -qF 'if [ "$(sudo -u "$APP_USER" git config --global user.email 2>/dev/null || echo)" != "agent@daroja.ai" ]; then' "$USER_SCRIPT"
    grep -qF 'git identity already set' "$USER_SCRIPT"
}

@test "install-login-policy.sh drops the documented login policy keys" {
    # The drop-in heredoc must contain the exact PASS_* policy lines (and
    # the L2 tight UMASK). Anchored to full lines so the leading-comment
    # prose does not satisfy the assertion.
    grep -q '^PASS_MAX_DAYS 365$' "$POLICY_SCRIPT"
    grep -q '^PASS_MIN_DAYS 1$' "$POLICY_SCRIPT"
    grep -q '^PASS_WARN_AGE 14$' "$POLICY_SCRIPT"
    grep -q '^UMASK 027$' "$POLICY_SCRIPT"
    # The policy must be dropped via heredoc into the drop-in, not sed-
    # flipped into /etc/login.defs itself.
    grep -qF 'cat >/etc/login.defs.d/99-l2-policy.conf <<'"'"'EOF'"'"'' "$POLICY_SCRIPT"
}

@test "deploy-headless.sh wires install-login-policy.sh as the last step" {
    grep -qF 'echo "→ install-login-policy.sh"' "$DEPLOY"
    grep -qF '"$BASH" "$SCRIPT_DIR/scripts/install-login-policy.sh"' "$DEPLOY"
    # Must run after the runtime-seam step, which previously was last.
    runtime_line="$(awk '/scripts\/install-runtime-seam-binaries\.sh/{ln=NR} END{print ln+0}' "$DEPLOY")"
    policy_line="$(awk '/scripts\/install-login-policy\.sh/{ln=NR} END{print ln+0}' "$DEPLOY")"
    [ "$policy_line" -gt "$runtime_line" ]
}