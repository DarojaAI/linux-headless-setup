#!/bin/bash
# shellcheck disable=SC2148
# ssh-hardening.sh — L2 SSH drop-in retirement (sourced by scripts/security.sh)
#
# L2 used to write /etc/ssh/sshd_config.d/10-l2.conf with `MaxStartups
# 3:50:10` (plus keepalives), which dropped unauthenticated connections
# once three scanners filled the queue — CI runners hit
# `kex_exchange_identification: read: Connection reset by peer`; 54 such
# drops were measured in 6 h on the test VM (2026-10-31). Ownership of
# sshd limits moved to L1 (terraform-hcloud-linux-vm issue #9, which writes
# 09-sshd-limits.conf with `MaxStartups 40:30:100`). sshd keeps the FIRST
# value it reads and `Include` sits at the top of sshd_config, so an L2
# 10- drop-in would shadow L1's 09- file.
#
# L2 therefore retires any drop-in it used to own — the file is L2's by
# name, so even one with other content is renamed, never silently deleted;
# evidence is preserved under a `.retired-<UTC ts>` suffix. MUST NOT
# introduce any other sshd setting here (keepalives included) — those
# belong in L1's 09-sshd-limits.conf.
#
# This is a sourced library (like lib.sh), not a standalone script, so the
# hermetic bats suite can unit-test it with fake sshd/systemctl on PATH and
# temp dirs — never touching this box's real /etc/ssh (production).

# l2_retire_sshd_dropin — idempotent, loud retirement of the L2 sshd drop-in.
#
# Args:
#   $1  ssh service unit name (default $SSHD_SERVICE; empty = no reload)
#   $2  sshd_config.d directory (default $SSHD_CONFIG_DIR or
#       /etc/ssh/sshd_config.d)
#
# Behavior (issue #52):
#   - logs the effective MaxStartups (via `sshd -T | grep -i '^maxstartups'`)
#     before and after so operators see the transition;
#   - if the drop-in exists: `sshd -t` before the rename, rename to
#     10-l2.conf.retired-<UTC ts>, WARN naming the file and pointing at L1
#     issue #9, `sshd -t` after the rename, reload the service (only when
#     the file actually existed);
#   - does NOT assert a specific MaxStartups (L1 owns it) but fails loud
#     (returns 1) if the effective value is still 3:50:10 — that means
#     something re-created the file.
l2_retire_sshd_dropin() {
	local service="${1:-${SSHD_SERVICE:-}}"
	local dropin_dir="${2:-${SSHD_CONFIG_DIR:-/etc/ssh/sshd_config.d}}"
	local dropin="$dropin_dir/10-l2.conf"
	local sshd_bin ssh_before ssh_after ts retired

	sshd_bin="$(command -v sshd || true)"
	if [ -n "$sshd_bin" ]; then
		ssh_before="$("$sshd_bin" -T 2>&1 | grep -iE '^maxstartups' || true)"
	else
		ssh_before=""
	fi
	info "L2 SSH hardening effective value before drop-in retirement: $(echo "$ssh_before" | tr '\n' '; ')"
	if [ -f "$dropin" ]; then
		# `sshd -t` before the rename: validate the config as deployed
		# (drop-in still in place).
		if [ -n "$sshd_bin" ]; then
			"$sshd_bin" -t
		fi
		ts="$(date -u +%Y%m%dT%H%M%SZ)"
		retired="$dropin.retired-$ts"
		mv "$dropin" "$retired"
		warn "Retired $dropin -> $retired — L2 no longer writes an sshd drop-in; L1 owns sshd limits (terraform-hcloud-linux-vm issue #9); see issue #52"
		# `sshd -t` after the rename: validate the config without it.
		if [ -n "$sshd_bin" ]; then
			"$sshd_bin" -t
		fi
		if [ -n "$service" ]; then
			systemctl reload "$service" || true
		fi
	fi
	if [ -n "$sshd_bin" ]; then
		ssh_after="$("$sshd_bin" -T 2>&1 | grep -iE '^maxstartups' || true)"
	else
		ssh_after=""
	fi
	info "L2 SSH hardening effective value after drop-in retirement: $(echo "$ssh_after" | tr '\n' '; ')"
	# L1 owns the MaxStartups value, so we do not assert a specific number —
	# but if the effective value is STILL 3:50:10, something re-created the
	# L2 drop-in; fail loud rather than shipping a flaky SSH layer.
	if grep -qiE '^maxstartups[[:space:]]+3:50:10([[:space:]]|$)' <<<"$ssh_after"; then
		error "Effective MaxStartups is still 3:50:10 after retiring $dropin — an L2 drop-in was re-created (issue #52)"
		return 1
	fi
}
