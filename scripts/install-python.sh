#!/bin/bash
# install-python.sh — Install Python 3.14 via pyenv for desktopuser
#
# Part of the linux-headless-setup L2 provisioning pipeline.
# Wired into deploy-headless.sh after runtimes.sh and before openclaw-prep.sh.
#
# Idempotent: safe to re-run. Existing pyenv + 3.14 install is a no-op.
#
# Requires pyenv's official installer (https://pyenv.run).
# Targets Ubuntu 24.04 (PEP 668 applies; --break-system-packages
# is only used as a last resort for pip operations).
#
# Runs as desktopuser. If executed as root, re-invokes itself under
# sudo -u desktopuser.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "=== install-python.sh starting ==="

# ── Re-exec as desktopuser if running as root ──
if [ "$EUID" -eq 0 ]; then
	info "Running as root — re-executing as $APP_USER"
	exec sudo -u "$APP_USER" -H bash -c "export PATH=\"$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH\"; $0 $*"
fi

# ── Idempotency: skip if pyenv is already installed ──
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

if [ -d "$PYENV_ROOT" ] && command -v pyenv &>/dev/null; then
	info "pyenv already installed at $PYENV_ROOT — skipping install"
else
	info "Installing pyenv via official installer..."
	curl -fsSL https://pyenv.run | bash
fi

# ── Ensure pyenv is on PATH (for this script) ──
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# ── Idempotency: skip if Python 3.14 is already installed ──
if pyenv versions 2>/dev/null | grep -qE '^3\.14'; then
	info "Python 3.14 already installed via pyenv — skipping build"
else
	info "Installing Python 3.14 via pyenv..."
	pyenv install 3.14.0
fi

# ── Set global Python version ──
info "Setting pyenv global to 3.14"
pyenv global 3.14

# ── Ensure pyenv is in PATH for future shell sessions ──
if ! grep -qF '$HOME/.pyenv/shims' "$HOME/.bashrc" 2>/dev/null; then
	info "Adding pyenv to PATH in ~/.bashrc"
	{
		echo ''
		echo '# pyenv (added by install-python.sh)'
		echo 'export PATH="$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH"'
		echo 'eval "$(pyenv init --path)"'
		echo 'eval "$(pyenv init -)"'
	} >>"$HOME/.bashrc"
fi

# ── Smoke check ──
info "Verifying pyenv Python 3.14..."
pyenv which python3.14
python3.14 --version

info "=== install-python.sh complete ==="