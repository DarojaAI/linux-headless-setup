#!/bin/bash
# check-pinned-runtime-versions.sh — coupling check between
# scripts/runtimes.sh (the L2 install pin) and
# tests/validate-install.sh (the runtime smoke test).
#
# Asserts that every Node major declared in runtimes.sh is
# accepted by the version regex in validate-install.sh.
#
# Adding a new Node pin in runtimes.sh without widening the
# regex in validate-install.sh silently breaks the validation,
# as seen in this script's own genesis: runtimes.sh pinned Node 24
# in PR #6, and validate-install.sh's "^v22" check failed the
# integration test for 24.x VMs. This test makes the next pin
# bump a single-file change.
#
# Ported 2026-09-26 from master (PR #8) during the master/main
# alignment. The original extracted literal majors (22, 24) from
# the check's regex; main's check evolved to a character-class
# range (^v(2[0-9]|[3-9][0-9]) = v20-v99, "node present and
# LTS-class"), which literal parsing cannot read. This version
# extracts the regex and evaluates it semantically — works for
# exact-major, grouped-alternative, and character-class shapes.
#
# Exits 0 on pass, 1 on fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNTIMES_SH="$REPO_ROOT/scripts/runtimes.sh"
VALIDATE_SH="$REPO_ROOT/tests/validate-install.sh"

# Pull NODE_MAJOR_REQUIRED=N (comma-separated lists also accepted)
# and emit one major per line.
extract_required_majors() {
    awk -F= '
        /^ *NODE_MAJOR_REQUIRED=/ {
            n = split($2, parts, ",")
            for (i = 1; i <= n; i++) {
                if (parts[i] ~ /^[0-9]+$/) print parts[i]
            }
        }
    ' "$RUNTIMES_SH" | sort -u
}

# Extract the node-version regex from validate-install.sh's
# "node installed" check line: the `grep -qE "<regex>"` payload.
extract_node_regex() {
    grep -m1 'node installed' "$VALIDATE_SH" \
        | sed -n 's/.*grep -qE "\(\^v[^"]*\)".*/\1/p'
}

# Is <major> accepted by the extracted regex? Evaluate it against
# a representative version string.
major_accepted() {
    local major="$1" regex
    regex="$(extract_node_regex)"
    [ -n "$regex" ] || return 2
    printf 'v%s.0.0\n' "$major" | grep -qE "$regex"
}

required="$(extract_required_majors)"
if [ -z "$required" ]; then
    echo "FAIL: $RUNTIMES_SH has no NODE_MAJOR_REQUIRED assignment" >&2
    exit 1
fi

regex="$(extract_node_regex)"
if [ -z "$regex" ]; then
    echo "FAIL: $VALIDATE_SH has no node version check" >&2
    exit 1
fi

echo "scripts/runtimes.sh  declares: $(printf '%s ' $required)"
echo "tests/validate-install.sh accepts: ${regex}"

failed=0
for major in $required; do
    if major_accepted "$major"; then
        echo "OK: v${major}.x satisfies the check"
    else
        echo "FAIL: v${major}.x is NOT accepted by the check" >&2
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    echo "" >&2
    echo "Coupling drift: widen the regex in tests/validate-install.sh" >&2
    echo "(or the check) to cover the pinned major." >&2
    exit 1
fi

echo "Coupling OK."
