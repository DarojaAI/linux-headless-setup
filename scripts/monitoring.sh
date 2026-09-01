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

# ── Journald persistence + size/rate caps ──
mkdir -p /var/log/journal
info "Installing journald size/rate cap drop-in..."
mkdir -p /etc/systemd/journald.conf.d
cat >/etc/systemd/journald.conf.d/99-l2-caps.conf <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=2G
SystemKeepFree=500M
MaxRetentionSec=30day
RateLimitIntervalSec=10s
RateLimitBurst=200
ForwardToSyslog=no
ForwardToWall=no
EOF
chmod 0644 /etc/systemd/journald.conf.d/99-l2-caps.conf
systemctl restart systemd-journald
systemctl is-active systemd-journald

info "Monitoring setup complete."
