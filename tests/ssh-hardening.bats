#!/usr/bin/env bats
# tests/ssh-hardening.bats
#
# Hermetic regression gate for the L2 SSH hardening drop-in written by
# scripts/security.sh. Parses the heredoc embedded in the script (no live
# VM required) and asserts the drop-in path is referenced — without touching
# PermitRootLogin / PasswordAuthentication, which are upstream-set by
# Hetzner cloud-init..
#
# Refs:
#   - DarojaAI/linux-headless-setup issue #52 (part of epic #48)

setup() {
	REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
	SCRIPT="$REPO_ROOT/scripts/security.sh"
}

@test "security.sh exists" {
	[ -f "$SCRIPT" ]
}

@test "security.sh passes bash -n" {
	run bash -n "$SCRIPT"
	[ "$status" -eq 0 ]
}

@test "security.sh passes shellcheck (--norc,to bypass repo's .shellcheckrc bug)" {
	command -v shellcheck >/dev/null || skip "shellcheck not installed"
	run shellcheck --norc -S error "$SCRIPT"
	[ "$status" -eq 0 ]
}

@test "security.sh drops the /etc/ssh/sshd_config.d/10-l2.conf heredoc with every L2 SSH key/value line" {
	run python3 <<PYEOF
import re, sys
with open("$SCRIPT", encoding="utf-8") as f:
	raw = f.read()
m = re.search(r"(?:cat > )?/etc/ssh/sshd_config\.d/10-l2\.conf <<'EOF'\n(.*?)\nEOF", raw, re.DOTALL)

if not m:
	print("FAIL: could not locate the 10-l2.conf heredoc", flush=True)
	raise SystemExit(1)
body = [line.strip() for line in m.group(1).splitlines() if line.strip() and not line.startswith("#")]
required = [
	"MaxStartups 3:50:10",
	"ClientAliveInterval 60",
	"ClientAliveCountMax 3",
]
# MaxAuthTries and LoginGraceTime are intentionally NOT overridden — distro
# defaults (6 and 120) are required so CI runners with multiple keys in
# `ssh-add` and fresh post-restart connections reach the right key and
# complete auth before the window closes. See scripts/security.sh comment.
missing = [k for k in required if k not in body]
if missing:
	print(f"MISSING: {missing}", flush=True); raise SystemExit(1)
# Belt-and-suspenders: if a future edit re-introduces MaxAuthTries or
# LoginGraceTime here, fail loud rather than silently regressing the SSH
# wedge fix.
forbidden = ["MaxAuthTries ", "LoginGraceTime "]
present_forbidden = [k for k in forbidden if any(line.startswith(k) for line in body)]
if present_forbidden:
	print(f"FORBIDDEN (re-introduced after deploy wedge fix): {present_forbidden}", flush=True); raise SystemExit(2)
print(f"OK: {len(required)} SSH hardening settings present in heredoc; MaxAuthTries+LoginGraceTime correctly absent")
PYEOF
	[ "$status" -eq 0 ]
}

@test "security.sh references the /etc/ssh/sshd_config.d/10-l2.conf drop-in" {
	run grep -F '/etc/ssh/sshd_config.d/10-l2.conf' "$SCRIPT"
	[ "$status" -eq 0 ]
}

@test "security.sh does not add PermitRootLogin / PasswordAuthentication assignments" {
	run python3 <<PYEOF
import re, sys
raw = open("$SCRIPT", encoding="utf-8").read()
m = re.search(r"install -m 0644 /dev/stdin /etc/ssh/sshd_config\.d/10-l2\.conf <<'EOF'\n(.*?)\nEOF", raw, re.DOTALL)

dropin = m.group(1) if m else ""
lines = [ln.strip() for ln in dropin.splitlines() if ln.strip()]
for tok in ("PermitRootLogin", "PasswordAuthentication"):
	if any(ln.startswith(tok) for ln in lines):
		print(f"FAIL: drop-in contains {tok}", flush=True); raise SystemExit(1)
if re.search(r"(?m)^[ \t]*(PermitRootLogin|PasswordAuthentication)\b", raw):
	print("FAIL: security.sh contains a PermitRootLogin / PasswordAuthentication assignment line", flush=True)
	raise SystemExit(2)
print("OK: no new PermitRootLogin / PasswordAuthentication assignments")
PYEOF
	[ "$status" -eq 0 ]
}
# -- Second-run idempotency (deploy 37321450441, 2026-10-05) -------------
# L2 re-runs on live VMs every deploy. The drop-in write must succeed when
# the target file ALREADY EXISTS (the first run created it). The old
# `install(1)` from /dev/stdin pattern failed only on the second run on
# Ubuntu 24.04 (coreutils 9.4): `install: No such file or directory`.

@test "drop-in write pattern is re-run safe (cat heredoc, not /dev/stdin install)" {
	# security.sh must write the drop-in with a plain `cat >` heredoc —
	# overwriting an existing drop-in must be an ordinary truncating write,
	# not an install(1) from /dev/stdin (coreutils >= 9.4 rejects pipe
	# sources on re-runs).
	run grep -n 'install -m 0644 /dev/stdin .*10-l2.conf' "$SCRIPT"
	[ "$status" -eq 1 ]
}

@test "drop-in heredoc pattern overwrites an existing file twice without error" {
	dir="$(mktemp -d)"
	printf 'MaxStartups 3:50:10\n' > "${dir}/10-l2.conf"
	for run in 1 2; do
		umask 022
		cat > "${dir}/10-l2.conf" <<'EOF'
# L2 SSH hardening — applied each deploy.
MaxStartups 3:50:10
ClientAliveInterval 60
ClientAliveCountMax 3
EOF
		chmod 0644 "${dir}/10-l2.conf"
	done
	run grep -c '^MaxStartups 3:50:10$' "${dir}/10-l2.conf"
	[ "$status" -eq 0 ]
	[[ "$output" == "1" ]]
	rm -rf "$dir"
}
