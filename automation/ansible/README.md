# 🛠️ Ansible

![Tool](https://img.shields.io/badge/Tool-Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white) ![Status](https://img.shields.io/badge/Status-Work_in_Progress-yellow?style=flat-square)

Inventory + playbooks used to bootstrap and manage homelab hosts (VMs, LXCs, and bare-metal nodes).

---

## 📌 At-a-Glance

| Area | What's here | Where |
|---|---|---|
| Inventory | Host groups + connection vars | `inventory/prod-hosts` |
| Playbooks | Linux bootstrap + common agents | `playbooks/` |
| Secrets | Guidance (no real keys) | `../secrets/README.md` |

---

## 📚 Table of Contents
- [📁 Layout](#-layout)
- [✅ Prerequisites](#-prerequisites)
- [⚙️ Inventory Setup](#-inventory-setup)
- [🚀 Running Playbooks](#-running-playbooks)
- [🧰 Playbooks](#-playbooks)
- [🔐 Secrets](#-secrets)

---

## 📁 Layout

```text
ansible/
  inventory/
    prod-hosts              # Main inventory (edit hostnames/IPs/user)
  playbooks/                # One-off and bootstrap playbooks
```

---

## ✅ Prerequisites

- Ansible installed on your control machine
- SSH access to managed hosts (SSH keys recommended)

Optional:
- Python venv to isolate Ansible dependencies

---

## ⚙️ Inventory Setup

1) Edit `inventory/prod-hosts`:
- Set `ansible_user`
- Replace each `ansible_host: REPLACE_ME` with an IP/DNS name
- Adjust groups as needed (`k3s_cluster`, `docker_hosts`, `lxc_hosts`, `pihole_hosts`, etc.)

2) Quick connectivity check:

```bash
ansible -i inventory/prod-hosts all -m ping
```

---

## 🚀 Running Playbooks

```bash
# Run against a group
ansible-playbook -i inventory/prod-hosts playbooks/linux-check-os-info.yml --limit k3s_cluster

# Run against a single host
ansible-playbook -i inventory/prod-hosts playbooks/linux-update-rhel.yml --limit lxc-host-1

# Dry-run (where supported) + show diffs
ansible-playbook -i inventory/prod-hosts playbooks/linux-fresh-system-configuration-ubuntu-debian.yml --check --diff
```

Useful flags:
- `--limit <host_or_group>`: target a subset
- `--check --diff`: preview changes (not every task supports check mode)
- `--become`: run tasks with sudo where required
- `-K`: prompt for sudo password (if needed)

---

## 🧰 Playbooks

| Playbook | Purpose |
|---|---|
| `ultimate-linux-setup.yml` | Umbrella playbook / bootstrap runbook |
| `linux-fresh-system-configuration-ubuntu-debian.yml` | Baseline config for Ubuntu/Debian |
| `linux-fresh-system-configuration-rhel.yml` | Baseline config for RHEL-family |
| `linux-install-promtail.yml` | Promtail agent install/config |
| `linux-install-wazuh-agent-*.yml` | Wazuh agent install/config |
| `linux-install-zabbix-agent2-*.yml` | Zabbix Agent2 install/config |
| `linux-check-os-info.yml` | Basic host inspection |
| `linux-update-rhel.yml` | RHEL-family update |
| `linux-set-warsaw-timezone.yml` | Timezone helper |
| `linux-generate-ssh-ecdsa-keys.yml` | SSH key generation helper |
| `linux-change-password.yml` | Password rotation (use with care) |

---

## 🔐 Secrets

Do not commit secrets. If a playbook needs credentials, use an encrypted secret store and keep decryption keys out of git (see `../secrets/README.md`).
