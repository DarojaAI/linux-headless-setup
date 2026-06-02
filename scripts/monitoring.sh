#!/bin/bash
# monitoring.sh — node_exporter, logrotate, journald
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

info "Starting monitoring setup..."

# ── node_exporter (Prometheus) ──
NODE_EXPORTER_VERSION="1.8.1"
NODE_EXPORTER_BIN="/usr/local/bin/node_exporter"

if [ ! -f "$NODE_EXPORTER_BIN" ]; then
	info "Installing node_exporter v${NODE_EXPORTER_VERSION}..."
	cd /tmp
	ARCH=$(dpkg --print-architecture)
	curl -fsSL "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}.tar.gz" \
		-o node_exporter.tar.gz
	tar -xzf node_exporter.tar.gz
	cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-${ARCH}/node_exporter" "$NODE_EXPORTER_BIN"
	chmod +x "$NODE_EXPORTER_BIN"
	rm -rf node_exporter*
else
	info "node_exporter already installed: $(${NODE_EXPORTER_BIN} --version 2>&1 | head -1 || true)"
fi

# Systemd unit
cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=${NODE_EXPORTER_BIN} --path.rootfs=/host
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter || true

# ── Logrotate ──
apt_install logrotate

# ── Journald persistence ──
mkdir -p /var/log/journal
if ! grep -q "Storage=persistent" /etc/systemd/journald.conf 2>/dev/null; then
	info "Enabling journald persistent storage..."
	sed -i 's/^#Storage=.*/Storage=persistent/' /etc/systemd/journald.conf || echo "Storage=persistent" >>/etc/systemd/journald.conf
	systemctl restart systemd-journald || true
fi

info "Monitoring setup complete."
