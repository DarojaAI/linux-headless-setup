#!/bin/bash
# check-pinned-runtime-versions.sh — coupling check between
# scripts/runtimes.sh (the L2 install pin) and
# tests/validate-install.sh (the runtime smoke test).
#
# Asserts that every Node major declared in runtimes.sh is
# accepted by the regex in validate-install.sh.
#
# Adding a new Node pin in runtimes.sh without widening the
# regex in validate-install.sh silently breaks the validation,
# as seen in this script's own genesis: runtimes.sh pinned Node 24
# in PR #6, and validate-install.sh's "^v22" check failed the
# integration test for 24.x VMs. This test makes the next pin
# bump a single-file change.
#
# Exits 0 on pass, 1 on fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNTIMES_SH="$REPO_ROOT/scripts/runtimes.sh"
VALIDATE_SH="$REPO_ROOT/tests/validate-install.sh"

# Resolve bash explicitly so the regex inside doesn't expand.
extract_required_majors() {
    # Pull `NODE_MAJOR_REQUIRED=N` lines and emit N. Comma-separated
    # lists (e.g., NODE_MAJOR_REQUIRED=22,24) are also accepted by
    # splitting on `,` after the `=`.
    awk -F= '
        /^[[:space:]]*NODE_MAJOR_REQUIRED[[:space:]]*=/ {
            v = $2
            n = split(v, parts, ",")
            for (i = 1; i <= n; i++) {
                gsub(/[[:space:]]/, "", parts[i])
                if (parts[i] ~ /^[0-9]+$/) print parts[i]
            }
        }
    ' "$RUNTIMES_SH" | sort -u
}

# Match two flavors of the `node installed` check in validate-install.sh:
#   - simple:  ^v22     (single line + single major, the original form)
#   - grouped: ^v(22\.|24\.|...)   (extended form, comma-joined majors)
# Returns one accepted major per match, deduped.
extract_accepted_majors() {
    awk '
        /node installed/ {
            line = $0
            n = split(line, parts, "\"")
            for (i = 1; i <= n; i++) {
                p = parts[i]
                # Grouped form: ^v(22\.|24\.|...)
                if (match(p, /\^v\(/)) {
                    inside = substr(p, RSTART + 3)
                    e = index(inside, ")")
                    if (e > 0) {
                        inside = substr(inside, 1, e - 1)
                        m = split(inside, alts, "|")
                        for (j = 1; j <= m; j++) {
                            gsub(/[\\. ]/, "", alts[j])
                            if (alts[j] ~ /^[0-9]+$/) print alts[j]
                        }
                    }
                }
                # Simple form: ^v22 or ^v22\.
                if (match(p, /\^v[0-9]+/)) {
                    gsub(/\^v/, "", p)
                    sub(/\..*/, "", p)
                    if (p ~ /^[0-9]+$/) print p
                }
            }
        }
    ' "$VALIDATE_SH" | sort -u
}

required="$(extract_required_majors)"
accepted="$(extract_accepted_majors)"

if [ -z "$required" ]; then
    echo "FAIL: $RUNTIMES_SH has no NODE_MAJOR_REQUIRED assignment" >&2
    exit 1
fi
if [ -z "$accepted" ]; then
    echo "FAIL: $VALIDATE_SH has no node version check" >&2
    exit 1
fi

echo "scripts/runtimes.sh  declares: $(printf '%s ' $required)"
echo "tests/validate-install.sh accepts: $(printf '%s ' $accepted)"
echo

fail=0
for major in $required; do
    if printf '%s\n' "$accepted" | grep -qx "$major"; then
        echo "  OK    major $major is pinned by runtimes.sh and accepted by validate-install.sh"
    else
        echo "  MISS  major $major is pinned by runtimes.sh but NOT accepted by validate-install.sh"
        fail=1
    fi
done

echo
if [ "$fail" -eq 0 ]; then
    echo "PASS: every runtimes.sh Node pin is accepted by validate-install.sh"
    exit 0
fi
echo "FAIL: mismatch between runtimes.sh and validate-install.sh. Widen the regex in"
echo "      tests/validate-install.sh to include the missed major(s) above."
exit 1
