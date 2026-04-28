# 🖥️ Proxmox Scripts

This folder contains operational scripts and runbooks for the Proxmox environment.

## Contents

- [homepage-exporter](homepage-exporter): deployment script for a Proxmox exporter instance used by Homepage or similar dashboards.
- [lenovo-m920q-mini-pc-eth-fix](lenovo-m920q-mini-pc-eth-fix): ethernet hang runbook plus the exported `e1000e` auto-heal watcher script.
- [pve-exporter](pve-exporter): Proxmox API token/user helper and Prometheus PVE exporter deployment script.

## Notes

Most scripts are intended to run directly on a Proxmox VE node. Review environment variables, generated files, and systemd unit paths before running them in a live cluster.

Real token values, generated secrets, and host-specific paths should stay outside the public repository.
