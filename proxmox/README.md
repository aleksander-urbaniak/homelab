# 🖥️ Proxmox Homelab

This repository documents a redacted Proxmox homelab cluster, including node networking, Ceph configuration, firewall rules, boot tuning, and supporting monitoring/security integrations.

The values in this public copy use example hostnames, example private address ranges, and placeholder secrets. They preserve the shape of the setup without exposing the private environment.

## Hardware

The cluster consists of three compact Lenovo micro-nodes, offering a balance of power and efficiency. The nodes share the same CPU, memory, storage, and network layout, but one node uses a Lenovo ThinkCentre M720q chassis instead of M920q.

| Node | Model | CPU | RAM | Storage | Networking |
| --- | --- | --- | --- | --- | --- |
| `pve-node01` | Lenovo ThinkCentre M920q | Intel Core i5-8500T (6 cores) | 32GB DDR4 SODIMM @ 2666MHz | 256GB NVMe (OS) + 1TB SATA SSD (Data) | 1Gbps Ethernet (internal mobo) + USB 1GbE NIC LANBERG NC-1000-01 |
| `pve-node02` | Lenovo ThinkCentre M720q | Intel Core i5-8500T (6 cores) | 32GB DDR4 SODIMM @ 2666MHz | 256GB NVMe (OS) + 1TB SATA SSD (Data) | 1Gbps Ethernet (internal mobo) + USB 1GbE NIC LANBERG NC-1000-01 |
| `pve-node03` | Lenovo ThinkCentre M920q | Intel Core i5-8500T (6 cores) | 32GB DDR4 SODIMM @ 2666MHz | 256GB NVMe (OS) + 1TB SATA SSD (Data) | 1Gbps Ethernet (internal mobo) + USB 1GbE NIC LANBERG NC-1000-01 |

## Cluster Overview

The Proxmox cluster is made up of three nodes and uses separate networks for management traffic and Ceph backend traffic.

| Item | Details |
| --- | --- |
| Platform | Proxmox VE |
| Nodes | `pve-node01`, `pve-node02`, `pve-node03` |
| Management network | `192.0.2.0/24` |
| Ceph / cluster network | `198.51.100.0/24` |
| Default gateway | `192.0.2.1` |

### Node Addressing

| Node | Management IP | Ceph / Cluster IP |
| --- | --- | --- |
| `pve-node01` | `192.0.2.11` | `198.51.100.11` |
| `pve-node02` | `192.0.2.12` | `198.51.100.12` |
| `pve-node03` | `192.0.2.13` | `198.51.100.13` |

## Networking

Each node uses a simple and consistent network layout:

- `vmbr0` is the main Proxmox bridge on the management network
- `nic0` is used as the bridge uplink
- a dedicated secondary interface is assigned to the `198.51.100.0/24` Ceph network

Network interface snapshots for all three nodes are stored in [interfaces.txt](config/network/interfaces.txt).

## Storage and Ceph

The cluster uses a 3-node Ceph deployment for distributed storage.

| Ceph Setting | Value |
| --- | --- |
| Public network | `192.0.2.0/24` |
| Cluster network | `198.51.100.0/24` |
| Authentication | `cephx` |
| Replica size | `3` |
| Minimum replica count | `2` |
| MON placement | all 3 Proxmox nodes |
| MDS standby entries | all 3 Proxmox nodes |

The current redacted Ceph configuration snapshot is stored in [ceph.conf](config/ceph/ceph.conf).

## High Availability

The management HA approach is based on a virtual IP managed by Keepalived and fronted by HAProxy-style service routing.

At a high level:

- Keepalived owns the floating Proxmox management VIP on the management bridge.
- Each Proxmox node participates in the same VRRP instance with descending priorities, so there is a preferred node but any healthy peer can take over.
- Unicast VRRP peers are used instead of relying on multicast behavior.
- The VRRP password is stored as a placeholder in this public copy and must be replaced before use.
- HAProxy is expected to bind or route traffic through the floating endpoint, giving clients a stable address even when the active node changes.

The repo includes a redacted Keepalived node configuration in [keepalived.txt](ha/keepalived/keepalived.txt) and a health-check script in [check-pve.sh](ha/keepalived/check-pve.sh).

That script verifies:

- `pve-cluster` service status
- quorum health through `pvecm status`
- Proxmox API availability on port `8006`
- Ceph manager health on port `8003` when `ceph-mgr` is running on the node

If those checks fail, Keepalived lowers the node priority, which lets the VIP move away from a node that is online but not healthy enough to serve management traffic. This is useful for partial failures where the host is reachable but Proxmox, quorum, or Ceph manager health is degraded.

## Security and Firewall

Firewall policy is documented through the Proxmox firewall notes stored in [firewall](firewall).

The intended cluster-wide policy is restrictive by default:

- inbound policy: `DROP`
- outbound policy: `DROP`

The ruleset uses aliases, IPSets, and reusable groups to keep cluster access explicit and segmented.

The overall firewall practice is:

- Define reusable aliases for major networks and infrastructure services instead of repeating raw addresses throughout rules.
- Group related nodes into IPSets such as Proxmox, Pi-hole, and K3s so rules follow service intent instead of individual host placement.
- Keep VM-level firewall exports separate from shared cluster policy when raw firewall snapshots are included.
- Allow management, monitoring, DNS, backup, and ingress traffic only from known source groups.
- Permit broad east-west traffic only where a platform needs it, such as traffic between K3s nodes, pods, and services.
- Leave disabled or experimental rules visibly commented/disabled where they document an intentional future path.
- Redact hostnames, workstation names, network ranges, and comments in the public copy while keeping the structure readable.

### Allowed Infrastructure Access

| Service | Port | Purpose |
| --- | --- | --- |
| Proxmox GUI / API | `8006` | management and API access |
| Ceph manager / API | `8003` | Ceph monitoring and health access |
| Proxmox Backup Server | `8007` | backup traffic |
| `pve-exporter` | `9221` | Prometheus / Grafana metrics |
| Ceph metrics | `9283` | Prometheus scraping |
| Zabbix agent | `10050` | agent-based monitoring |

### Workloads Visible in Firewall Definitions

Based on the firewall practices and previously exported VM-level rules, this Proxmox environment hosts or supports:

- K3s cluster nodes
- Pi-hole
- Proxmox Backup Server
- Wazuh
- GitLab Runner
- Jellyfin
- Sonarr
- Radarr
- qBittorrent
- Home Assistant
- WireGuard
- Portainer Agent
- Traefik-exposed web workloads

## Monitoring and Observability

This Proxmox setup is integrated with several monitoring tools and exporters:

| Tool | Purpose |
| --- | --- |
| Wazuh agent | security monitoring |
| `pve-exporter` | metrics source for Grafana dashboards |
| Zabbix agent | Ceph monitoring |
| Zabbix via Proxmox API | Proxmox monitoring |

Based on the firewall and service access rules, the monitoring stack currently relies on:

- port `9221` for `pve-exporter`
- port `9283` for Ceph metrics
- port `10050` for Zabbix agent
- port `8006` for Proxmox API access
- port `8003` for Ceph manager access

Exporter-related files live under [scripts](scripts):

- [create-pve-exporter-user.sh](scripts/pve-exporter/create-pve-exporter-user.sh) creates a read-only Proxmox user/token and stores the token secret locally on the target host.
- [deploy_proxmox_pve_exporter.sh](scripts/pve-exporter/deploy_proxmox_pve_exporter.sh) deploys the exporter into a Python virtual environment, writes the exporter config, installs a systemd service, and checks the `/pve` endpoint.
- [deploy_homepage_exporter.sh](scripts/homepage-exporter/deploy_homepage_exporter.sh) follows the same deployment pattern for a Homepage-facing exporter setup.

The exporter practice is to use API tokens with read-only/auditor permissions, keep token values out of git, and expose metrics through stable ports that are explicitly allowed by the Proxmox firewall.

## Boot and Stability Tuning

The GRUB snapshot in [grub.cfg](config/system/grub.cfg) includes a few hardware-focused kernel parameters:

- `usbcore.autosuspend=-1`
- `pcie_aspm=off`
- `e1000e.SmartPowerDownEnable=0`

These settings are aimed at reducing power-management side effects on compact Lenovo nodes and USB/network adapters:

- `usbcore.autosuspend=-1` disables USB autosuspend, useful for USB NIC stability.
- `pcie_aspm=off` disables PCIe Active State Power Management, reducing link power-state transitions.
- `e1000e.SmartPowerDownEnable=0` disables Intel e1000e smart power-down behavior, which can help avoid NIC hangs on affected hardware.

The GRUB file is a snapshot of the relevant kernel command-line configuration rather than a full bootloader management workflow. Changes like these require `update-grub` and a reboot on the target Proxmox node.

## Hardware Fixes and Runbooks

The folder [scripts/lenovo-m920q-mini-pc-eth-fix](scripts/lenovo-m920q-mini-pc-eth-fix) contains a runbook and exported watcher script for the Lenovo ThinkCentre M920q/M720q class nodes with Intel `e1000e` network hardware.

The runbook covers:

- triage commands for kernel logs and NIC statistics
- emergency link renegotiation when a node loses network access
- driver reload and optional PCI function reset steps
- persistent mitigations such as disabling Energy Efficient Ethernet
- GRUB kernel flags that reduce PCIe/NIC power-management issues
- an optional watchdog-style auto-heal script and systemd service pattern
- a standalone [e1000e-hang-watch.sh](scripts/lenovo-m920q-mini-pc-eth-fix/e1000e-hang-watch.sh) script extracted from the runbook

The general operational practice is to pause or account for HA before disruptive NIC recovery, restore connectivity, verify cluster health with `pvecm status`, and then resume normal HA behavior.

## Repository Structure

| Path | Description |
| --- | --- |
| [config/ceph/ceph.conf](config/ceph/ceph.conf) | redacted Ceph cluster configuration snapshot |
| [config/network/interfaces.txt](config/network/interfaces.txt) | redacted network interface configs for the 3 Proxmox nodes |
| [config/system/grub.cfg](config/system/grub.cfg) | GRUB kernel boot parameters |
| [ha/keepalived/check-pve.sh](ha/keepalived/check-pve.sh) | Keepalived health-check script |
| [ha/keepalived/keepalived.txt](ha/keepalived/keepalived.txt) | redacted per-node Keepalived VRRP configuration |
| [firewall](firewall) | Proxmox firewall practices and redaction notes |
| [scripts/pve-exporter](scripts/pve-exporter) | Proxmox Prometheus exporter setup scripts and notes |
| [scripts/homepage-exporter](scripts/homepage-exporter) | Homepage exporter deployment script |
| [scripts/lenovo-m920q-mini-pc-eth-fix](scripts/lenovo-m920q-mini-pc-eth-fix) | ethernet hang fix runbook and exported watcher script |

### Layout

```text
proxmox/
|-- config/
|   |-- ceph/
|   |-- network/
|   `-- system/
|-- firewall/
|   `-- README.md
|-- ha/
|   `-- keepalived/
|-- scripts/
|   |-- homepage-exporter/
|   |-- lenovo-m920q-mini-pc-eth-fix/
|   `-- pve-exporter/
`-- README.md
```

## Purpose

The point of this repo is to keep the Proxmox environment documented in one place so it is easier to rebuild, audit, troubleshoot, and extend over time, while keeping sensitive deployment details out of the public repository.
