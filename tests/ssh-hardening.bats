#!/usr/bin/env bats
# tests/ssh-hardening.bats
#
# Hermetic regression gate for the L2 SSH drop-in retirement
# (scripts/security.sh + scripts/ssh-hardening.sh). L2 used to write
# /etc/ssh/sshd_config.d/10-l2.conf with `MaxStartups 3:50:10`, which
# dropped unauthenticated connections once three scanners filled the queue
# (CI runners: `kex_exchange_identification: read: Connection reset by
# peer`; 54 drops in 6 h on the test VM, 2026-10-31). Ownership of sshd
# limits moved to L1 (terraform-hcloud-linux-vm#9 → 09-sshd-limits.conf):
# L2 must NOT write the drop-in and must retire any existing one — renaming
# it to `10-l2.conf.retired-<UTC ts>` (never silently deleting), reloading
# only when a file actually existed, and failing loud if the effective
# MaxStartups is still 3:50:10 (i.e. something re-created the drop-in).
#
# Static tests cover scripts/security.sh; the execution tests source
# scripts/ssh-hardening.sh and run the retirement with fake sshd/systemctl
# on PATH and SSHD_CONFIG_DIR/temp dirs — this box's real /etc/ssh is
# never touched (this workstation is production).
#
# Refs:
#   - DarojaAI/linux-headless-setup issue #52 (part of epic #48)
#   - terraform-hcloud-linux-vm issue #9 (L1 owns sshd limits)

# Minimal logging shims so the sourced helper needs no live system state.
info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
error() { printf '[ERROR] %s\n' "$*"; }

setup() {
	REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
	SCRIPT="$REPO_ROOT/scripts/security.sh"
	HELPER="$REPO_ROOT/scripts/ssh-hardening.sh"
	FIXTURE="$(mktemp -d)"
	FAKE_SSHD_DIR="$FIXTURE/ssh"
	FAKE_BIN="$FIXTURE/bin"
	mkdir -p "$FAKE_BIN"
	mkdir -p "$FAKE_SSHD_DIR/sshd_config.d"

	# Fake sshd: `-t` validates, `-T` reports the effective MaxStartups.
	# Override FAKE_SSHD_MAXSTARTUPS to simulate a re-created drop-in.
	# Every invocation is logged so tests can assert validation (sshd -t)
	# ran before/after the rename.
	cat > "$FAKE_BIN/sshd" <<'FAKESSHD'
#!/bin/bash
echo "$*" >> "${SSHD_LOG:?}"
case "$1" in
	-t) exit 0 ;;
	-T) printf 'maxstartups %s\n' "${FAKE_SSHD_MAXSTARTUPS:-10:30:100}"; exit 0 ;;
esac
exit 0
FAKESSHD
	chmod +x "$FAKE_BIN/sshd"

	# Fake systemctl: logs every invocation so tests can assert reload only
	# happens when a drop-in actually existed.
	cat > "$FAKE_BIN/systemctl" <<'FAKESYSTEMCTL'
#!/bin/bash
echo "$*" >> "${SYSTEMCTL_LOG:?}"
exit 0
FAKESYSTEMCTL
	chmod +x "$FAKE_BIN/systemctl"

	ssh_dir() { printf '%s/sshd_config.d' "$FAKE_SSHD_DIR"; }
	export PATH="$FAKE_BIN:$PATH"
	export SSHD_LOG="$FIXTURE/sshd.log"
	export SYSTEMCTL_LOG="$FIXTURE/systemctl.log"
	: > "$SSHD_LOG"
	: > "$SYSTEMCTL_LOG"
	: > "$(ssh_dir)/marker"

	# The retirement step lives in ssh-hardening.sh (sourced library), so
	# the hermetic suite can execute it without running security.sh's full
	# firewall/fail2ban/upgrades flow.
	# shellcheck disable=SC1091
	source "$HELPER"
}

teardown() {
	rm -rf "$FIXTURE"
}

# run_retire executes the retirement step with the hermetic fixtures.
run_retire() {
	run l2_retire_sshd_dropin "ssh.service" "$(ssh_dir)"
}

# retired_files lists the preserved drop-ins (one per retirement run).
retired_files() {
	shopt -s nullglob
	local retired=( "$(ssh_dir)"/10-l2.conf.retired-* )
	shopt -u nullglob
	printf '%s\n' "${retired[@]}"
}

@test "security.sh exists" {
	[ -f "$SCRIPT" ]
}

@test "security.sh and ssh-hardening.sh pass bash -n" {
	run bash -n "$SCRIPT"
	[ "$status" -eq 0 ]
	run bash -n "$HELPER"
	[ "$status" -eq 0 ]
}

@test "security.sh and ssh-hardening.sh pass shellcheck (--norc -S error)" {
	command -v shellcheck >/dev/null || skip "shellcheck not installed"
	run shellcheck --norc -S error "$SCRIPT"
	[ "$status" -eq 0 ]
	run shellcheck --norc -S error "$HELPER"
	[ "$status" -eq 0 ]
}

@test "security.sh no longer writes the 10-l2.conf drop-in (would fail on the old heredoc write)" {
	# Old code created /etc/ssh/sshd_config.d/10-l2.conf via a `cat >`
	# heredoc; L2 must now only read/rename it (issue #52).
	run grep -nE '(^|[^[:alnum:]_])cat[[:space:]]+>[[:space:]]+.*10-l2\.conf|install[[:space:]].*10-l2\.conf' "$SCRIPT"
	[ "$status" -eq 1 ]
}

@test "retirement introduces no sshd setting of its own (MaxStartups/keepalives/auth-limits assignments)" {
	# L2 must not assert any sshd setting — those live in L1's
	# 09-sshd-limits.conf (issue #52). Settings may only appear in
	# prose/comments, never as assignment lines.
	run grep -nE '^[[:space:]]*(MaxStartups|ClientAliveInterval|ClientAliveCountMax|MaxAuthTries|LoginGraceTime)[[:space:]]' "$SCRIPT" "$HELPER"
	[ "$status" -eq 1 ]
}

@test "security.sh sources the helper and calls the retirement step" {
	run grep -F 'source "$SCRIPT_DIR/ssh-hardening.sh"' "$SCRIPT"
	[ "$status" -eq 0 ]
	run grep -F 'l2_retire_sshd_dropin "$SSHD_SERVICE"' "$SCRIPT"
	[ "$status" -eq 0 ]
}

@test "retirement renames (mv) and never deletes (rm) the drop-in" {
	run grep -nE 'rm[[:space:]]+.*10-l2\.conf' "$HELPER" "$SCRIPT"
	[ "$status" -eq 1 ]
	run grep -F 'mv "$dropin" "$retired"' "$HELPER"
	[ "$status" -eq 0 ]
}

@test "security.sh does not add PermitRootLogin / PasswordAuthentication assignments" {
	run python3 <<PYEOF
import re
raw = open("$SCRIPT", encoding="utf-8").read()
if re.search(r"(?m)^[ \t]*(PermitRootLogin|PasswordAuthentication)\b", raw):
	print("FAIL: security.sh contains a PermitRootLogin / PasswordAuthentication assignment line")
	raise SystemExit(1)
print("OK: no PermitRootLogin / PasswordAuthentication assignments")
PYEOF
	[ "$status" -eq 0 ]
}

@test "retires an existing 10-l2.conf: renames, preserves content, reloads, and never writes a new one" {
	printf 'MaxStartups 3:50:10\nClientAliveInterval 60\nClientAliveCountMax 3\n' > "$(ssh_dir)/10-l2.conf"
	run_retire
	[ "$status" -eq 0 ]

	# Original drop-in is gone, preserved exactly under .retired-<UTC ts>.
	[ ! -e "$(ssh_dir)/10-l2.conf" ]
	local retired
	retired="$(retired_files)"
	[ -n "$retired" ]
	[[ "$retired" == *"10-l2.conf.retired-"* ]]
	[[ "$(cat "$retired")" == *"MaxStartups 3:50:10"* ]]

	# Loud WARN names the file and points at L1 issue #9; before/after
	# effective-value logging is preserved.
	[[ "$output" == *"before drop-in retirement"* ]]
	[[ "$output" == *"after drop-in retirement"* ]]
	[[ "$output" == *"Retired"* ]]
	[[ "$output" == *"terraform-hcloud-linux-vm issue #9"* ]]
	[[ "$output" == *"maxstartups 10:30:100"* ]]

	# `sshd -t` validation ran before AND after the rename, and the service
	# was reloaded (the file existed).
	run grep -c '^-t$' "$SSHD_LOG"
	[[ "$output" == "2" ]]
	grep -q 'reload ssh.service' "$SYSTEMCTL_LOG"
}

@test "a pre-existing 10-l2.conf with other content is still retired (the file is L2's by name)" {
	printf 'MaxStartups 40:30:100\nClientAliveInterval 300\n' > "$(ssh_dir)/10-l2.conf"
	run_retire
	[ "$status" -eq 0 ]
	[ ! -e "$(ssh_dir)/10-l2.conf" ]
	local retired
	retired="$(retired_files)"
	[ -n "$retired" ]
	[[ "$(cat "$retired")" == *"MaxStartups 40:30:100"* ]]
}

@test "no 10-l2.conf present: succeeds, creates nothing, and does not reload/restart ssh" {
	run_retire
	[ "$status" -eq 0 ]
	[ ! -e "$(ssh_dir)/10-l2.conf" ]
	[ -z "$(retired_files)" ]
	! grep -q 'reload ssh' "$SYSTEMCTL_LOG"
	! grep -q '^-t$' "$SSHD_LOG"
}

@test "retirement is idempotent across repeated runs (second run has nothing to retire)" {
	printf 'MaxStartups 3:50:10\n' > "$(ssh_dir)/10-l2.conf"
	run_retire
	[ "$status" -eq 0 ]
	run_retire
	[ "$status" -eq 0 ]
	[ ! -e "$(ssh_dir)/10-l2.conf" ]
	[ -n "$(retired_files)" ]
	# Exactly one file preserved and exactly one reload + one -t pair (only
	# the first run had a drop-in to retire).
	run bash -c "printf '%s\n' '$(retired_files)' | wc -l"
	[[ "$output" == "1" ]]
	run grep -c 'reload ssh.service' "$SYSTEMCTL_LOG"
	[[ "$output" == "1" ]]
	run grep -c '^-t$' "$SSHD_LOG"
	[[ "$output" == "2" ]]
}

@test "fails loud if the effective MaxStartups is still 3:50:10 after retirement (drop-in re-created)" {
	export FAKE_SSHD_MAXSTARTUPS="3:50:10"
	printf 'MaxStartups 3:50:10\n' > "$(ssh_dir)/10-l2.conf"
	run_retire
	[ "$status" -ne 0 ]
	[[ "$output" == *"still 3:50:10"* ]]
	[[ "$output" == *"re-created"* ]]
}
