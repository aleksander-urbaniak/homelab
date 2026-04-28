# 🏠 Homelab

![Virtualization](https://img.shields.io/badge/Virtualization-Proxmox-E57000?logo=proxmox&logoColor=white) ![Orchestration](https://img.shields.io/badge/Orchestration-k3s-FFC61C?logo=k3s&logoColor=white) ![Containerization](https://img.shields.io/badge/Containerization-Docker-2496ED?logo=docker&logoColor=white) ![Monitoring](https://img.shields.io/badge/Monitoring-Zabbix%20%2B%20Prometheus%20%2B%20Wazuh-blue) ![Status](https://img.shields.io/badge/Status-Work_in_Progress-yellow) ![License](https://img.shields.io/badge/License-MIT-green)

## 🏠 My Homelab Infrastructure ✨

A public, redacted infrastructure-as-code reference for my homelab. It documents the shape of the environment, the deployment patterns, and the operational runbooks without publishing private hostnames, public IP addresses, credentials, tokens, or full production secrets.

The lab is built around Proxmox, K3s, Docker, Linux automation, layered monitoring, and a small set of practical operational scripts.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Repository Layout](#-repository-layout)
- [Hardware](#-hardware)
- [Platform](#-platform)
- [Applications](#-applications)
- [Monitoring](#-monitoring)
- [Automation](#-automation)
- [Networking and VPN](#-networking-and-vpn)
- [Linux and Proxmox Operations](#-linux-and-proxmox-operations)
- [Redaction Model](#-redaction-model)
- [Security](#-security)
- [License](#-license)

---

## 📖 Overview

This repo is the public documentation and sanitized configuration mirror for a home infrastructure environment.

- 🖥️ **Proxmox**: cluster notes, firewall practices, network/system config examples, HA overview, exporters, and hardware fixes.
- ☸️ **Kubernetes / K3s**: application manifests, Helm values, DNS setup, and storage-backed deployment layouts.
- 📦 **Docker**: standalone Compose workloads for services that run outside the K3s cluster.
- 📈 **Monitoring**: Zabbix for hosts/services, Prometheus stack for K3s, and Wazuh for security monitoring.
- 🛠️ **Automation**: Ansible, Terraform, n8n automation notes, and update workflows.
- 💻 **Linux**: host setup, identity integration, monitoring agents, SSH, storage, and operational scripts.
- 🌐 **VPN and networking**: Cloudflare Tunnel/WARP notes and WireGuard using `wg-easy` on Oracle Linux 10 with Docker.

## 📂 Repository Layout

```text
├── .github/          # GitHub workflows and repository metadata
├── automation/       # Ansible, Terraform, n8n, and automation workflows
├── backups/          # Backup strategy and runbooks
├── diy-rpi5-nas/     # Raspberry Pi 5 NAS build notes
├── docker/           # Docker Compose catalog and app documentation
│   ├── applications/
│   ├── config/
│   └── scripts/
├── img/              # Images and diagrams used by docs
├── kubernetes/       # K3s setup, DNS notes, Helm values, and manifests
│   ├── applications/
│   │   ├── ceph-storage/
│   │   └── longhorn-storage (archived)/
│   ├── k3s-dns-setup/
│   └── k3s-setup/
├── linux/            # Linux docs, scripts, monitoring, identity, and system config
├── monitoring/       # Zabbix, Prometheus stack, and Wazuh overview
├── networking/       # Network documentation and notes
├── proxmox/          # Proxmox config examples, firewall, HA, and scripts
├── secrets/          # Secret handling guidance and public-safe examples
├── vpn/              # Cloudflare Tunnel and WireGuard documentation
└── windows/          # Windows helper scripts and notes
```

> [!NOTE]
> Public examples use placeholders such as `REPLACE_ME`, `example.com`, `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`. Real environment-specific values are intentionally omitted.

## 🖥️ Hardware

The Proxmox cluster uses three Lenovo micro nodes with similar specs.

| Node | Model | CPU | RAM | Storage | Notes |
| --- | --- | --- | --- | --- | --- |
| `pve-node-01` | Lenovo ThinkCentre M920q | Intel Core i5-8500T | 32GB DDR4 | 256GB NVMe + 1TB SATA SSD | Proxmox node |
| `pve-node-02` | Lenovo ThinkCentre M720q | Intel Core i5-8500T | 32GB DDR4 | 256GB NVMe + 1TB SATA SSD | Same class/specs as M920q nodes |
| `pve-node-03` | Lenovo ThinkCentre M920q | Intel Core i5-8500T | 32GB DDR4 | 256GB NVMe + 1TB SATA SSD | Proxmox node |

<img src="img/proxmox-nodes.png" alt="Proxmox Nodes" width="700">

## 🧱 Platform

| Area | Current Approach |
| --- | --- |
| Virtualization | Proxmox VE cluster with documented firewall, networking, system, Ceph, and HA practices |
| Kubernetes | K3s cluster with app manifests and Helm-managed components |
| Storage | Active Kubernetes app catalog under `kubernetes/applications/ceph-storage/`; older Longhorn layout archived under `kubernetes/applications/longhorn-storage (archived)/` |
| Containers | Docker Compose catalog for standalone workloads and VM-based services |
| Identity | Authentik/LDAP integration notes for Linux hosts and application access patterns |
| Edge access | Cloudflare Tunnel, reverse proxy patterns, and WireGuard VPN |

## 📦 Applications

### ☸️ K3s Applications

Active public K3s manifests live under `kubernetes/applications/ceph-storage/`.

| Category | Apps |
| --- | --- |
| Platform and storage | Ceph CSI, MetalLB, Rancher, Traefik |
| Identity and access | Authentik, Nexterm, Vaultwarden |
| Monitoring and automation | Flarewatcher, GitLab Runner, Grafana, InfluxDB, Loki, Pi-hole Exporter, Prometheus, Pulze Dashboard, Renovate, Semaphore, Speedtest Tracker |
| Productivity | Affine, Apprise, Homepage, n8n, Pastefy |

### 📦 Docker Applications

Standalone Docker Compose apps live under `docker/applications/`.

| Category | Apps |
| --- | --- |
| Networking and access | cloudflared, Guacamole, Nginx Proxy Manager, Pi-hole, wg-easy |
| Dashboards and tools | Homepage, MkDocs, Nexterm, Pastefy, Portainer, Portainer Agent, Pulze Dashboard, Uptime Kuma, Wallos |
| Media and downloads | FlareSolverr, Jackett, Jellyfin, qBittorrent, Radarr, Sonarr |
| Monitoring and security | Flarewatcher, Speedtest Tracker, Wazuh, Zabbix |
| Storage and productivity | Home Assistant, Nextcloud, Vaultwarden |

## 📈 Monitoring

Monitoring is split by responsibility instead of forcing one tool to do everything.

| Stack | Purpose | Location |
| --- | --- | --- |
| Zabbix | Host resources, network checks, website checks, infrastructure availability | `monitoring/zabbix/` |
| Prometheus stack | K3s metrics, Grafana dashboards, Loki logs, node exporters, Alertmanager | `monitoring/prometheus-stack/` |
| Wazuh | Security monitoring and endpoint visibility | `monitoring/wazuh/` |
| Linux exporters | Node exporter, Promtail, and Proxmox exporter helpers | `linux/monitoring/`, `proxmox/scripts/` |

Zabbix runs on a separate Oracle Linux 10 VM. The Prometheus stack is focused on the K3s cluster. Wazuh is kept as the security monitoring layer.

## 🛠️ Automation

| Area | What It Does |
| --- | --- |
| `automation/ansible/` | Inventory and playbooks for Linux/bootstrap style tasks |
| `automation/terraform/proxmox/` | Proxmox-oriented Terraform examples, including LXC provisioning |
| `automation/n8n/docker-images-auto-update/` | n8n workflow documentation for reviewing dependency/image update merge requests and auto-merging low-risk updates |
| `renovate.json` | Renovate configuration for automated dependency updates |

## 🌐 Networking and VPN

| Area | Current State |
| --- | --- |
| Cloudflare Tunnel | Documented under `vpn/cloudlfare-tunnel/` for private access patterns |
| WireGuard | `wg-easy` runs on an Oracle Linux 10 VM with Docker; the public Compose file is redacted |
| Proxmox networking | Public-safe examples live in `proxmox/config/network/` |
| Reverse proxy | Docker and Kubernetes examples include reverse proxy/ingress patterns with placeholder domains |

## 🖥️ Linux and Proxmox Operations

### 🖥️ Proxmox

The `proxmox/` folder documents the public-safe operational view of the cluster:

- Firewall practices and rule intent, without publishing the full private policy.
- HA approach using HAProxy and Keepalived concepts.
- Keepalived config overview and health-check script examples.
- GRUB/system configuration notes.
- Ceph and network configuration examples.
- PVE exporter and Homepage exporter scripts.
- Lenovo M920q/M720q class `e1000e` Ethernet hang mitigation script.

### 💻 Linux

The `linux/` folder documents reusable host-side practices:

- Storage expansion and disk runbooks.
- LDAP/Auth integration patterns.
- SSH hardening and RHEL-oriented SSH examples.
- Prometheus node exporter, Loki/Promtail, and Proxmox monitoring helpers.
- Monitoring scripts and system preparation notes.

## 🔐 Redaction Model

This repository is intentionally public-safe. It keeps the structure and operational patterns while redacting sensitive details.

| Sensitive Value | Public Replacement |
| --- | --- |
| Real domains | `example.com` or service-specific placeholder names |
| Real IP addresses | RFC 5737 documentation ranges such as `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` |
| Passwords, tokens, API keys | `REPLACE_ME` |
| Private hostnames | Generic names such as `pve-node-01` |
| Full private policies | Summaries and examples instead of complete production rules |

## 🔐 Security

> [!WARNING]
> This repo is a public documentation/configuration mirror. Do not commit real secrets, API tokens, private keys, production `.env` files, or unredacted service exports.

If a secret is committed by mistake:

1. Rotate the secret immediately.
2. Remove it from the repository.
3. Rewrite history if the repository was pushed publicly.
4. Audit any downstream systems that used the exposed value.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
