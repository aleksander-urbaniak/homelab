# 🖥️ Homepage Exporter

This folder contains a deployment script for a Proxmox exporter setup intended to feed Homepage or similar dashboards.

## File

- [deploy_homepage_exporter.sh](deploy_homepage_exporter.sh): installs `prometheus-pve-exporter`, writes `/etc/prometheus/pve.yml`, creates a systemd service, and performs a simple HTTP health check.

## What It Does

The script:

- expects a Proxmox API token value through `PVE_TOKEN_VALUE`
- optionally ensures the token has `PVEAuditor` permissions
- installs Python venv dependencies
- installs `prometheus-pve-exporter`
- writes a local exporter configuration file with restrictive permissions
- enables and starts `prometheus-pve-exporter`
- tests the `/pve` endpoint on the configured listen address

## Security Notes

Do not commit real token values. Pass them through environment variables or a private secret workflow on the target node.
