#!/bin/bash
# validate-python.sh — Smoke tests for Python 3.14 via pyenv
set -euo pipefail

PASS=0
FAIL=0

check() {
	local name="$1"
	shift
	if "$@" >/dev/null 2>&1; then
		echo "[PASS] $name"
		((PASS++)) || true
	else
		echo "[FAIL] $name"
		((FAIL++)) || true
	fi
}

echo "=== Python 3.14 Validation ==="

# ── pyenv ──
check "pyenv installed" command -v pyenv
check "pyenv versions contains 3.14" bash -c 'pyenv versions | grep -qE "^3\.14"'

# ── Python 3.14 ──
check "python3.14 installed" command -v python3.14
check "python3.14 --version exits 0" bash -c 'python3.14 --version'

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
	exit 1
fi