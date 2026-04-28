sudo apt-get install -y wget tar
# Download & install node_exporter
VER=1.9.1
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VER}/node_exporter-${VER}.linux-amd64.tar.gz
tar -xzf node_exporter-${VER}.linux-amd64.tar.gz
sudo mv node_exporter-${VER}.linux-amd64/node_exporter /usr/local/bin/node_exporter
# Create a dedicated system user (no login, no home)
sudo useradd --system --no-create-home --user-group --shell /usr/sbin/nologin nodeusr
# Permissions
sudo chown root:root /usr/local/bin/node_exporter
sudo chmod 0755 /usr/local/bin/node_exporter
# Systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
After=network.target
[Service]
User=nodeusr
Group=nodeusr
Type=simple
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=multi-user.target
EOF
# Start on boot
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
# Open firewall (only if UFW is in use)
if command -v ufw >/dev/null; then   sudo ufw allow 9100/tcp; fi
# Check status
systemctl --no-pager status node_exporter
/usr/local/bin/node_exporter --version