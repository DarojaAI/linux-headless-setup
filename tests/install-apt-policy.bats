#!/usr/bin/env bats
# tests/install-apt-policy.bats
#
# Hermetic regression gate for the L2 apt policy pin written by
# scripts/install-apt-policy.sh. Parses the dropped files' sources (module
# script, unit file, deploy wiring) — no live apt/systemd probes, so the
# suite runs on any host (including the dev box).
#
# Refs:
#   - DarojaAI/linux-headless-setup issue #48 (epic #48, L2 hardening)
#   - scripts/systemd/apt-policy-applied.service (boot-time drift guard)

setup() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
    APT_POLICY="$REPO_ROOT/scripts/install-apt-policy.sh"
    DEPLOY="$REPO_ROOT/deploy-headless.sh"
    UNIT="$REPO_ROOT/scripts/systemd/apt-policy-applied.service"
}

@test "install-apt-policy.sh holds kernel + critical packages via apt-mark hold" {
    # The hold loop must cover the generic kernel meta-packages AND the
    # running kernel's modules-extra package (expanded at run time).
    run grep -Fq 'apt-mark hold "$pkg"' "$APT_POLICY"
    [ "$status" -eq 0 ]
    run grep -Fq 'linux-image-generic' "$APT_POLICY"
    [ "$status" -eq 0 ]
    run grep -Fq 'linux-modules-extra-$(uname -r)' "$APT_POLICY"
    [ "$status" -eq 0 ]
}

@test "install-apt-policy.sh restricts unattended-upgrades to security, no auto-reboot" {
    # Extract the 20-unattended-restrictions heredoc body and assert the
    # literal policy lines (heredoc is quoted, so ${distro_codename} stays
    # literal in the file and is expanded by apt at run time).
    run python3 <<PYEOF
import re, sys
with open("$APT_POLICY") as f:
    raw = f.read()
m = re.search(
    r"cat >/etc/apt/apt\.conf\.d/20-unattended-restrictions <<'EOF'\n(.*?)\nEOF",
    raw, re.DOTALL)
if not m:
    print("FAIL: 20-unattended-restrictions heredoc not found", flush=True)
    raise SystemExit(1)
body = [ln.strip() for ln in m.group(1).splitlines()
        if ln.strip() and not ln.lstrip().startswith("//")]
required = [
    'Unattended-Upgrade::Automatic-Reboot "false";',
    "Unattended-Upgrade::Origins-Pattern {",
    'origin=Ubuntu,archive=\${distro_codename}-security";',
    'origin=Ubuntu,archive=\${distro_codename},label=Ubuntu-Security";',
]
missing = [r for r in required if not any(r in ln for ln in body)]
if missing:
    print(f"MISSING: {missing}", flush=True)
    raise SystemExit(1)
print(f"OK: {len(required)} restriction lines present in heredoc")
PYEOF
    [ "$status" -eq 0 ]
}

@test "deploy-headless.sh wires install-apt-policy.sh after install-runtime-seam-binaries.sh" {
    # The apt-policy call must be $BASH-gated (lib.sh ERR-trap SIGSEGV
    # class) and run after the runtime-seam helper, which stays last of
    # the original gated sequence.
    local gated apt_line seam_line
    gated="$(grep -nE '"\$BASH" "\$SCRIPT_DIR/scripts/[^"]+\.sh"' "$DEPLOY")"
    apt_line="$(printf '%s\n' "$gated" | grep 'install-apt-policy\.sh' | head -n1 | cut -d: -f1)"
    seam_line="$(printf '%s\n' "$gated" | grep 'install-runtime-seam-binaries\.sh' | head -n1 | cut -d: -f1)"
    echo "$gated" | grep -q 'install-apt-policy\.sh'
    [ -n "$apt_line" ]
    [ -n "$seam_line" ]
    [ "$seam_line" -lt "$apt_line" ]
}

@test "apt-policy-applied.service one-shot ships and re-asserts holds on drift" {
    [ -f "$UNIT" ]
    # install-apt-policy.sh must drop the unit into /etc/systemd/system.
    grep -q 'apt-policy-applied\.service' "$APT_POLICY"
    # The unit itself must verify with `apt-mark showhold` (drift guard),
    # not blindly re-hold.
    grep -q 'apt-mark showhold' "$UNIT"
}