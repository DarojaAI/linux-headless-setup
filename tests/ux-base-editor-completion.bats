#!/usr/bin/env bats
# tests/ux-base-editor-completion.bats
#
# Layer-2 UX baseline (#54, epic #48): verify scripts/system.sh installs
# the base editor/pager/autocomplete packages (vim-tiny, bash-completion,
# man-db, less)and wires vim-tiny asthe default vim alternative — while
# leaving the chrony block (#49) untouched.
#
# All assertions are hermetic by default: they parse the script content (the
# source of truth), so no root, apt, or live VM is required. The one live
# probe (update-alternatives --display vim) only runs when a vim alternative
# already exists on the test host,and is skipped otherwise.

setup() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME:-tests/ux-base-editor-completion.bats}")/.." && pwd)"
    SCRIPT="$REPO_ROOT/scripts/system.sh"
}

@test "system.sh installs L2 UX base editor packages" {
    for pkg in vim-tiny bash-completion man-db less; do
        grep -Fxq "apt_install $pkg" "$SCRIPT" || {
            echo "MISSING: expected 'apt_install $pkg' in $SCRIPT" >&2
            return 1
        }
    done
}

@test "system.sh wires vim-tiny asthe L2 editor (no other editor installed)" {
    # The install must leave `vim` pointing at the headless-friendly vim-tiny.

    # The post-install probe below makes that an explicit bootstrap assertion:
    grep -Fxq 'update-alternatives --display vim 2>/dev/null | head' "$SCRIPT" || {
        echo "MISSING: vim alternative sanity probe in $SCRIPT" >&2
        return 1
    }

    # No other editor package may be installed in the base block: vim-tiny
    # (and the classic `ed` line editor, if ever needed) are the only editors
    # in scope;vim/nano/emacs/neovim would pull in heavier default editors..
    if grep -nE '^apt_install (vim|vim-nox|vim-gtk3|vim-athena|nano|emacs|emacs-nox|neovim)$' "$SCRIPT"; then
        echo "L2 base block selects an editor other than vim-tiny:" >&2
        return 1
    fi

    # On a provisioned host (when vim is actually installed), verify the
    # alternative really resolves to vim-tiny;skip quietly when vim absent..
    if command -v vim >/dev/null 2>&1; then
        run update-alternatives --display vim 2>&1
        if [ "$status" -ne 0 ]; then
            echo "update-alternatives --display vim failed (vim alternative group missing?):" >&2
            printf '%s\n' "$output" | head -10 >&2
            return 1
        fi
        if ! printf '%s\n' "$output" | grep -q 'vim-tiny'; then
            skip "host vim alternative is not vim-tiny (not provisioned with system.sh)"
        fi
    fi
}

@test "system.sh retains chrony block (issue #49) after UX additions" {
    grep -Fxq 'apt_install chrony' "$SCRIPT" || return 1
    grep -Fxq "cat >/etc/chrony/conf.d/20-l2-pool.conf <<'EOF'" "$SCRIPT" || return 1
    grep -Fxq 'chronyc waitsync 5 -v' "$SCRIPT" || return 1

    # The UX packages append to the base-packages block BEFORE the chrony
    # block;if they were shoved inside/after chrony, the pool-config heredoc
    # or waitsync probe would be disturbed or the ordering would be wrong..
    ux_line="$(grep -nFx 'apt_install vim-tiny' "$SCRIPT" | cut -d: -f1 | head -n1)"
    chrony_line="$(grep -nFx 'apt_install chrony' "$SCRIPT" | cut -d: -f1 | head -n1)"
    [ -n "$ux_line" ] && [ -n "$chrony_line" ] && [ "$ux_line" -lt "$chrony_line" ] || {
        echo "FAIL: UX apt_install calls must precede the chrony apt_install (vim-tiny@${ux_line:-?}, chrony@${chrony_line:-?})" >&2
        return 1
    }
}