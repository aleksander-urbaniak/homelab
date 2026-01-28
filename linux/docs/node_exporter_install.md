# Node Exporter Installation Guide

This guide describes how to install and configure Prometheus Node Exporter on a Linux system.

---

## 1. Download and extract Node Exporter
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
tar -xzvf node_exporter-1.9.1.linux-amd64.tar.gz
```

## 2. Create a dedicated user
```bash
sudo useradd -rs /bin/false nodeusr
```

## 3. Move the binary to the correct location
```bash
sudo mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
```

## 4. Create the systemd service file
```ini
# /etc/systemd/system/node_exporter.service
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
```

## 5. Set permissions
```bash
chmod 0755 /usr/local/bin/node_exporter
chown root:root /usr/local/bin/node_exporter
```

## 6. (RHEL only) Restore SELinux context
```bash
restorecon -v /usr/local/bin/node_exporter
```

## 7. Enable and start the service
```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter --now
```

## 8. Open firewall port 9100
```bash
sudo firewall-cmd --add-port=9100/tcp --permanent
sudo firewall-cmd --reload
```

## 9. Check Node Exporter status
```bash
sudo systemctl status node_exporter
```
