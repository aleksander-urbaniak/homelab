# Proxmox PVE Exporter Setup Guide

This guide describes how to set up the Prometheus PVE Exporter on Proxmox VE for monitoring.

---

## 1. Add a read-only user for Prometheus
```bash
pveum user add prometheus@pam --comment "Prometheus read-only user"
```

## 2. Grant full audit rights
```bash
pveum acl modify / --user prometheus@pam --role PVEAuditor
pveum acl modify / \
  --roles PVEAuditor \
  --tokens 'prometheus@pam!exporter'
```

## 3. Create a token for that user
```bash
pveum user token add prometheus@pam exporter --comment "Prometheus Exporter Token"
# Note the 'value' (e.g. xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
```

## 4. Install dependencies
```bash
apt update
apt install -y python3-venv python3-pip
```

## 5. Create and activate a Python virtual environment
```bash
python3 -m venv /opt/prometheus-pve-exporter-venv
source /opt/prometheus-pve-exporter-venv/bin/activate
```

## 6. Install the exporter
```bash
pip install prometheus-pve-exporter
```

## 7. Deactivate the virtual environment
```bash
deactivate
```

## 8. Create the configuration file `/etc/prometheus/pve.yml`
```yaml
default:
  user: prometheus@pam
  token_name: "exporter"
  token_value: "<TOKEN_FROM_STEP_1c>"
  verify_ssl: false
```
```bash
chmod 600 /etc/prometheus/pve.yml
```

## 9. Create the systemd service file `/etc/systemd/system/prometheus-pve-exporter.service`
```ini
[Unit]
Description=Prometheus Proxmox VE Exporter
After=network.target

[Service]
Type=simple
ExecStart=/opt/prometheus-pve-exporter-venv/bin/pve_exporter \
  --config.file=/etc/prometheus/pve.yml \
  --web.listen-address=0.0.0.0:9221
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## 10. Enable and start the exporter
```bash
systemctl daemon-reload
systemctl enable --now prometheus-pve-exporter
```

## 11. Prometheus scrape config example
```yaml
- job_name: 'proxmox'
  scrape_interval: 15s
  metrics_path: /pve
  params:
    module: [default]
  static_configs:
    - targets:
      - proxmox-node-1.example.com:9221  # your nodes
      - proxmox-node-2.example.com:9221
```
