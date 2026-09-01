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
m = re.search(r"install -m 0644 /dev/stdin /etc/ssh/sshd_config\.d/10-l2\.conf <<'EOF'\n(.*?)\nEOF", raw, re.DOTALL)

if not m:
	print("FAIL: could not locate the 10-l2.conf heredoc", flush=True)
	raise SystemExit(1)
body = [line.strip() for line in m.group(1).splitlines() if line.strip() and not line.startswith("#")]
required = [
	"MaxAuthTries 3",
	"LoginGraceTime 30",
	"MaxStartups 3:50:10",
	"ClientAliveInterval 60",
	"ClientAliveCountMax 3",
]
missing = [k for k in required if k not in body]
if missing:
	print(f"MISSING: {missing}", flush=True); raise SystemExit(1)
print(f"OK: {len(required)} SSH hardening settings present in heredoc")
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