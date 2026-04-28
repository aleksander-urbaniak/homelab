# 💻 Linux Homelab

This folder collects Linux-focused homelab notes, install guides, helper scripts, and configuration snippets used across Debian-family and RHEL-family systems.

The public copy is redacted. Domains, usernames, IP addresses, generated tokens, and passwords are represented with examples or placeholders.

## Scope

| Area | Contents |
| --- | --- |
| Storage | disk mounting and online disk expansion guides |
| Identity | Authentik LDAP + SSSD integration for Debian/Ubuntu and RHEL/Oracle Linux |
| Monitoring | Node Exporter, Promtail, Proxmox `pve-exporter`, and Uptime Kuma helper scripts |
| System | RHEL SSH daemon configuration examples |

## Repository Structure

| Path | Description |
| --- | --- |
| [docs/storage](docs/storage) | operational docs for disk setup and resizing |
| [identity/ldap/debian](identity/ldap/debian) | Debian/Ubuntu LDAP + SSSD integration files |
| [identity/ldap/rhel](identity/ldap/rhel) | RHEL/Oracle/Rocky/Alma LDAP + SSSD integration files |
| [monitoring/prometheus/node-exporter](monitoring/prometheus/node-exporter) | Node Exporter docs and install scripts |
| [monitoring/proxmox/pve-exporter](monitoring/proxmox/pve-exporter) | Proxmox exporter docs and helper scripts |
| [monitoring/loki/promtail](monitoring/loki/promtail) | Promtail install helper |
| [system/ssh/rhel](system/ssh/rhel) | SSH config examples and notes for RHEL |
| [scripts/monitoring](scripts/monitoring) | monitoring-related helper scripts |

## Layout

```text
linux/
|-- docs/
|   `-- storage/
|-- identity/
|   `-- ldap/
|       |-- debian/
|       `-- rhel/
|-- monitoring/
|   |-- loki/
|   |   `-- promtail/
|   |-- prometheus/
|   |   `-- node-exporter/
|   `-- proxmox/
|       `-- pve-exporter/
|-- scripts/
|   `-- monitoring/
|-- system/
|   `-- ssh/
|       `-- rhel/
`-- README.md
```

## Storage Docs

| File | Description |
| --- | --- |
| [add-disk-mount.md](docs/storage/add-disk-mount.md) | guide for preparing a new disk and mounting it persistently |
| [expand-disk-online.md](docs/storage/expand-disk-online.md) | step-by-step guide for online disk and filesystem expansion |

## Identity And LDAP

LDAP-related configuration is grouped by operating system family under [identity/ldap](identity/ldap).

### Debian-Based

| File | Description |
| --- | --- |
| [README.md](identity/ldap/debian/README.md) | Debian/Ubuntu Authentik LDAP + SSSD usage notes |
| [authentik-ldap-integration.sh](identity/ldap/debian/authentik-ldap-integration.sh) | integration script for Debian-based systems |
| [remove-user.sh](identity/ldap/debian/remove-user.sh) | local user migration/cleanup helper; requires private `NEW_PASS` at runtime |

### RHEL-Based

| File | Description |
| --- | --- |
| [README.md](identity/ldap/rhel/README.md) | RHEL/Oracle Linux Authentik LDAP + SSSD usage notes |
| [authentik-ldap-integration.sh](identity/ldap/rhel/authentik-ldap-integration.sh) | integration script for RHEL-based systems |

## Monitoring

Monitoring resources are grouped by stack and target under [monitoring](monitoring).

### Prometheus

| File | Description |
| --- | --- |
| [README.md](monitoring/prometheus/node-exporter/README.md) | Node Exporter installation guide |
| [install-debian.sh](monitoring/prometheus/node-exporter/install-debian.sh) | Node Exporter install script for Debian-based systems |
| [install-rhel.sh](monitoring/prometheus/node-exporter/install-rhel.sh) | Node Exporter install script for RHEL-based systems |

### Proxmox

| File | Description |
| --- | --- |
| [README.md](monitoring/proxmox/pve-exporter/README.md) | Proxmox `pve-exporter` setup guide |
| [create-user.sh](monitoring/proxmox/pve-exporter/create-user.sh) | helper for creating the exporter user/token |
| [deploy.sh](monitoring/proxmox/pve-exporter/deploy.sh) | deployment helper for `pve-exporter` |

### Loki

| File | Description |
| --- | --- |
| [install.sh](monitoring/loki/promtail/install.sh) | Promtail installation helper |

### Uptime Kuma

| File | Description |
| --- | --- |
| [uptime-kuma-push-monitor-tui.sh](scripts/monitoring/uptime-kuma-push-monitor-tui.sh) | interactive helper for creating an Uptime Kuma push monitor and local checker |

## System

| File | Description |
| --- | --- |
| [change-sshd-config.txt](system/ssh/rhel/change-sshd-config.txt) | SSH daemon configuration notes |
| [generate-ssh-keys.txt](system/ssh/rhel/generate-ssh-keys.txt) | SSH key generation notes |
| [sshd_config](system/ssh/rhel/sshd_config) | example SSH daemon config |

## Redaction Notes

Do not commit:

- real LDAP bind secrets
- real user passwords or generated migration passwords
- private domains, private IPs, or internal hostnames
- API tokens for Proxmox, Uptime Kuma, Loki, or other monitoring services
- private SSH keys generated from examples in this folder

## Purpose

The goal of this folder is to keep Linux operational knowledge for the homelab in one place: install notes, configuration examples, and reusable scripts that can be applied quickly when building or maintaining servers.
