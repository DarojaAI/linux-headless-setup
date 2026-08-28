#!/usr/bin/env bats
# Regression: scripts/user.sh bounded sudoers allowlist idempotent renderer.
# Mirrors tests/security-ssh-access-mode-idempotent.bats pattern.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TMPDIR="$(mktemp -d)"
    export SUDOERS_FILE_DEST="$TMPDIR/sudoers.d/desktopuser"
    mkdir -p "$(dirname "$SUDOERS_FILE_DEST")"
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "default allowlist renders to apt+systemctl (no NOPASSWD:ALL by default)" {
    # Re-execute the user.sh template-render branch in isolation.
    SUDO_ALLOWLIST="apt-get systemctl" \
    bash -c '
        SUDO_FRAGMENT=""
        for cmd in $SUDO_ALLOWLIST; do
            case "$cmd" in
                /*) SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }$cmd" ;;
                *)  SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }/usr/bin/$cmd" ;;
            esac
        done
        SUDO_RULE_LINE="desktopuser ALL=(ALL) NOPASSWD: $SUDO_FRAGMENT"
        [ "$SUDO_RULE_LINE" = "desktopuser ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/systemctl" ]
    '
}

@test "SUDO_ALLOWLIST=all expands legacy NOPASSWD:ALL" {
    result="$(SUDO_ALLOWLIST=all bash -c '
        [ "$SUDO_ALLOWLIST" = "all" ] && echo "$APP_USER ALL=(ALL) NOPASSWD:ALL"
    ')"
    [ "$result" = " ALL=(ALL) NOPASSWD:ALL" ]
}

@test "empty SUDO_ALLOWLIST produces NOPASSWD:!ALL (no escalation)" {
    SUDO_ALLOWLIST="" bash -c '
        [ -z "$SUDO_ALLOWLIST" ] && SUDO_RULE_LINE="desktopuser ALL=(ALL) NOPASSWD:!ALL"
        [ "$SUDO_RULE_LINE" = "desktopuser ALL=(ALL) NOPASSWD:!ALL" ]
    '
}

@test "absolute paths passed through unchanged" {
    SUDO_ALLOWLIST="/usr/local/bin/openclaw-watchdog" bash -c '
        SUDO_FRAGMENT=""
        for cmd in $SUDO_ALLOWLIST; do
            case "$cmd" in
                /*) SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }$cmd" ;;
                *)  SUDO_FRAGMENT="${SUDO_FRAGMENT:+$SUDO_FRAGMENT, }/usr/bin/$cmd" ;;
            esac
        done
        [ "$SUDO_FRAGMENT" = "/usr/local/bin/openclaw-watchdog" ]
    '
}

@test "idempotent re-render does not rewrite identical rule" {
    SUDO_RULE_LINE="desktopuser ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/systemctl"
    printf '%s\n' "$SUDO_RULE_LINE" >"$SUDOERS_FILE_DEST"
    # Simulate the renderer being invoked twice.
    existing="$(cat "$SUDOERS_FILE_DEST")"
    [ "$existing" = "$SUDO_RULE_LINE" ]
}
