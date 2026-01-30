![Virtualization](https://img.shields.io/badge/Virtualization-Proxmox-E57000?logo=proxmox&logoColor=white) ![Orchestration](https://img.shields.io/badge/Orchestration-k3s-FFC61C?logo=k3s&logoColor=white) ![Containerization](https://img.shields.io/badge/Containerization-Docker-2496ED?logo=docker&logoColor=white) ![Status](https://img.shields.io/badge/Status-Work_in_Progress-yellow) ![License](https://img.shields.io/badge/License-MIT-Green)


## 🏠My Homelab Infrastructure

##### A practical, "batteries-included" Infrastructure-as-Code repository.
##### Built with Proxmox, Kubernetes, and GitOps principles.

## 📖 Overview

This repository serves as the central brain for a homelab. It is designed to be forked and adapted, providing a solid foundation for:

- ☁️ **Virtualization**: Proxmox configuration snippets and firewall rules
- ☸️ **Orchestration**: a K3s cluster with apps deployed via plain manifests
- 🐳 **Containerization**: a Docker Compose catalog for standalone services
- 🤖 **Automation**: Ansible playbooks, n8n workflows and GitLab CI/CD pipelines

## 📂 Repo Layout

```text
├── .github/          # GitHub workflows/templates
├── ansible/          # Inventory + playbooks (bootstrap, agents, monitoring)
├── backups/          # Backup strategies, scripts, runbooks
|   └──  README.md
├── diy-rpi5-nas/     # DIY Raspberry Pi 5 NAS setup
|   └──  README.md
├── docker/           # Docker compose files and scripts
├── img/              # Diagrams and screenshots
├── kubernetes/       # K3s docs and manifests
├── linux/            # Linux scripts and docs
├── networking/       # DNS, reverse proxy, and network notes
|   └──  README.md
├── proxmox/          # Cluster config, firewall rules, scripts
├── secrets/          # Secrets handling guidance (no real keys)
|   └──  README.md      
└── windows/          # Windows notes/scripts
```







> NOTE: Each application folder under `kubernetes/applications/` and `docker/applications/` includes its own `README.md` with deployment commands and specific notes.

## 🖥️ Hardware

The cluster consists of three identical micro-nodes, offering a balance of power and efficiency.

| Node Specs | Details |
| --- | --- |
| Model | Lenovo ThinkCentre M920q |
| CPU | Intel Core i5-8500T (6 cores) |
| RAM | 32GB DDR4 SODIMM @ 2666MHz |
| Storage | 256GB NVMe (OS) + 1TB SATA SSD (Data) |
| Networking | 1Gbps Ethernet |

<img src="img/proxmox-nodes.png" alt="Proxmox Nodes" width="700">

## 🛠️ Core applications / services

This lab leverages a modern, cloud-native stack adapted for home use.

<table>
  <tr>
    <th>Logo</th>
    <th>Name</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><img width="28" src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/proxmox.webp" alt="Proxmox"></td>
    <td><a href="https://www.proxmox.com/en/proxmox-virtual-environment/overview">Proxmox</a></td>
    <td>Hypervisor and virtual environment management</td>
  </tr>
  <tr>
    <td><img width="28" src="https://logo.svgcdn.com/devicon/k3s-original.svg" alt="K3s"></td>
    <td><a href="https://k3s.io/">Kubernetes (K3s)</a></td>
    <td>Lightweight Kubernetes distribution</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Docker_%28container_engine%29_logo.svg" alt="Docker"></td>
    <td><a href="https://www.docker.com/">Docker</a></td>
    <td>Container runtime + Docker Compose for standalone workloads</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/2/24/Ansible_logo.svg" alt="Ansible"></td>
    <td><a href="https://www.ansible.com/">Ansible</a></td>
    <td>Infrastructure-as-Code for provisioning and configuration</td>
  </tr>
  <tr>
    <td><img width="28" src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/nginx-proxy-manager.webp" alt="Nginx Proxy Manager"></td>
    <td><a href="https://nginxproxymanager.com/">Nginx Proxy Manager</a></td>
    <td>Ingress / reverse proxy with GUI-managed routing and TLS</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/4/4b/Cloudflare_Logo.svg" alt="Cloudflare"></td>
    <td><a href="https://www.cloudflare.com/products/tunnel/">Cloudflared (Cloudflare Tunnel)</a></td>
    <td>Securely expose services without opening inbound ports</td>
  </tr>
  <tr>
    <td><img width="28" src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/webp/authentik.webp" alt="Authentik"></td>
    <td><a href="https://goauthentik.io/">Authentik</a></td>
    <td>SSO / IAM provider (OIDC/SAML/LDAP)</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/3/38/Prometheus_software_logo.svg" alt="Prometheus"></td>
    <td><a href="https://prometheus.io/">Prometheus</a></td>
    <td>Metrics collection and alerting foundation</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Grafana_logo.svg/960px-Grafana_logo.svg.png" alt="Grafana"></td>
    <td><a href="https://grafana.com/">Grafana</a></td>
    <td>Dashboards and observability UI</td>
  </tr>
  <tr>
    <td><img width="28" src="https://gist.githubusercontent.com/aslafy-z/97271013882ed61a4c3f83e161284402/raw/grafana-loki.svg" alt="Loki"></td>
    <td><a href="https://grafana.com/oss/loki/">Loki</a></td>
    <td>Log aggregation (Grafana stack)</td>
  </tr>
  <tr>
    <td><img width="28" src="https://longhorn.io/img/logos/longhorn-icon-color.png" alt="Longhorn"></td>
    <td><a href="https://longhorn.io/">Longhorn</a></td>
    <td>Distributed block storage for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="28" src="https://avatars.githubusercontent.com/u/60239468?s=280&v=4" alt="MetalLB"></td>
    <td><a href="https://metallb.universe.tf/">MetalLB</a></td>
    <td>Bare-metal LoadBalancer for Kubernetes Services</td>
  </tr>
  <tr>
    <td><img width="28" src="https://cdn.jsdelivr.net/npm/simple-icons@v11/icons/renovatebot.svg" alt="Renovate"></td>
    <td><a href="https://docs.renovatebot.com/">Renovate</a></td>
    <td>Automated dependency and image updates</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/c/c3/Wazuh-Logo-2022.png" alt="Wazuh"></td>
    <td><a href="https://wazuh.com/">Wazuh</a></td>
    <td>SIEM / XDR security stack (Docker)</td>
  </tr>
  <tr>
    <td><img width="28" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Zabbix_logo.svg/1280px-Zabbix_logo.svg.png" alt="Zabbix"></td>
    <td><a href="https://www.zabbix.com/">Zabbix</a></td>
    <td>Monitoring for networks, hosts, and services</td>
  </tr>
</table>

## 📦 Applications

Services are divided between Kubernetes (HA/in-cluster) and Docker (standalone).

### 🛡️ Infrastructure & Networking

| App | Description | Stack |
| --- | --- | --- |
| Authentik | SSO + LDAP outpost for Linux and apps | K8s |
| cert-manager | Automated certificate management | K8s |
| Cloudflared | Secure tunneling without open ports | K8s |
| MetalLB | Bare-metal LoadBalancer | K8s |
| Nginx Proxy Manager | GUI-managed reverse proxy | K8s |
| Pi-hole | DNS sinkhole / ad-blocking | K8s |
| Nebula-sync | Sync Pi-hole configuration between instances | K8s |
| Rancher / Fleet | Cluster management + GitOps-style deployments | K8s |
| Renovate | Automated updates | K8s |
| Portainer | Container management UI | K8s / Docker |

### 📊 Observability & Monitoring

| App | Description | Stack |
| --- | --- | --- |
| Grafana | Dashboards and UI | K8s |
| Prometheus | Metrics collection | K8s |
| Loki | Log aggregation | K8s |
| Alertmanager | Alert routing & grouping | K8s |
| Karma | UI for Alertmanager | K8s |
| InfluxDB | Time-series database | K8s |
| Exporters | Node, Pi-hole, and kube-state metrics | K8s |
| Wazuh | SIEM / XDR security stack | Docker |
| Zabbix | Network & host monitoring | Docker |
| Uptime Kuma | Website / endpoint uptime monitoring | Docker |

### 🍿 Media & Automation (*Arr Stack)

| App | Description | Stack |
| --- | --- | --- |
| Jellyfin | Media server | Docker |
| Sonarr | TV show automation | Docker |
| Radarr | Movie automation | Docker |
| Jackett | Indexer proxy for the *arr stack | Docker |
| qBittorrent | Download client | Docker |
| FlareSolverr | Anti-bot bypass helper | Docker |

### 💼 Productivity & Tools

| App | Description | Stack |
| --- | --- | --- |
| Affine | Knowledge base (Notion alternative) | K8s |
| Homepage | Static dashboard start page | K8s |
| n8n | Workflow automation | K8s |
| Apprise | Notification gateway for multi-channel alerts | K8s |
| Pastefy | Self-hosted pastebin | K8s |
| Vaultwarden | Password manager | K8s |
| Guacamole | Clientless remote desktop gateway | K8s |
| Nextcloud | File sync + collaboration | Docker |
| Home Assistant | Home automation platform | Docker |
| Nexterm | Web terminal / remote access UI | Docker |
| Postfix relay | SMTP relay for outbound mail | Docker |


## ✨ Features

### 🧱 Platform

- [x] Proxmox cluster firewall configuration (`proxmox/firewall/cluster.fw`)
- [x] Human-friendly firewall markdown view (`proxmox/firewall/cluster.fw.md`)
- [x] HA-style K3s install guide (`kubernetes/k3s/k3s-install-rhel.md`)

### ☸️ Kubernetes & Apps

- [x] App manifests organized per namespace/app (`kubernetes/applications/*`)
- [x] Per-app docs with deploy commands and split-manifest notes
- [x] Kubernetes-first services (SSO, monitoring, storage, automation, dashboards)

### 🐳 Docker & Apps

- [x] Docker Compose catalog (`docker/applications/*`)
- [x] Per-app `.env.example` patterns with `REPLACE_ME` placeholders
- [x] Standalone workloads (media stack, SIEM, utilities)

### 📈 Observability & Security

- [x] Monitoring stack (Prometheus + Alertmanager + Grafana + Loki)
- [x] Infrastructure monitoring (Zabbix)
- [x] Security monitoring (Wazuh)
- [x] Exporters and probes (node-exporter, kube-state-metrics, blackbox, etc.)

### 🤖 Automation & Runbooks

- [x] Ansible playbooks and inventory (`ansible/`)
- [x] Distro-aware node exporter installer (`linux/monitoring/node_exporter_install.sh`)
- [x] Promtail deployment playbook (`ansible/playbooks/linux-install-promtail.yml`)
- [x] Authentik LDAP + SSSD guide (`linux/docs/README-authentik-ldap.md`)
- [x] Backup strategy document (`backups/BACKUP-STRATEGY.md`)

### 🔐 Git Hygiene

- [x] Universal placeholders (`example.com`, `REPLACE_ME`) instead of personal details and secrets
- [x] Repo-wide cleanup of obvious tokens/credentials in examples and manifests

## 🔐 Security

> [!WARNING]
> Operational security notice:
>
> - This repo contains placeholders (e.g., `REPLACE_ME`, `example.com`).
> - Never commit real tokens, passwords, private keys, or `.env` files to git history.
> - If you committed a secret, rotate it immediately and consider rewriting git history.

## 📄 License

This project is licensed under the MIT License — see `LICENSE`.
