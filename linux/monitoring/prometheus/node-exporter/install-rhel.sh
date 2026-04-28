dnf makecache; dnf install -y wget tar

wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
tar -xzvf node_exporter-1.9.1.linux-amd64.tar.gz
sudo useradd -rs /bin/false nodeusr
sudo mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter

sudo cat > /etc/systemd/system/node_exporter.service << 'EOF'
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

chmod 0755 /usr/local/bin/node_exporter
chown root:root    /usr/local/bin/node_exporter

#on rhel
restorecon -v /usr/local/bin/node_exporter

sudo systemctl daemon-reload
sudo systemctl enable node_exporter --now

sudo firewall-cmd --add-port=9100/tcp --permanent
sudo firewall-cmd --reload

sudo systemctl status node_exporter
