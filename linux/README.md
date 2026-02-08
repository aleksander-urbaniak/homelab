# 🐧 Linux ✨

![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black) ![Status](https://img.shields.io/badge/Status-Work_in_Progress-yellow?style=flat-square)

Linux-focused runbooks and helper scripts used for day-2 ops (new VM prep, disk operations, monitoring/logging agents, and Authentik LDAP integration).

---

## 📌 At-a-Glance

| Area | What's here | Where |
|---|---|---|
| Runbooks | Step-by-step docs (manual procedures) | `docs/` |
| Scripts | Helpers you can run on hosts | `scripts/` |
| Automation | Many steps mirrored in Ansible | `../ansible/` |

---

## 📚 Table of Contents
- [📁 Layout](#-layout)
- [📖 Docs (Runbooks)](#-docs-runbooks)
- [🧰 Scripts](#-scripts)
- [⚠️ Safety Notes](#-safety-notes)

---

## 📁 Layout

```text
linux/
  docs/                     # Runbooks and how-tos
  scripts/                  # Shell scripts for common tasks
```

---

## 📖 Docs (Runbooks)

- `docs/new-vm-preparation.md` - manual baseline steps for a fresh VM (mirrors `../ansible/playbooks/ultimate-linux-setup.yml`)
- `docs/how-to-add-new-disk.md` - partition + format + persistent mount (XFS/ext4)
- `docs/how-to-expand-existing-disk.md` - online partition + filesystem expansion (ext4/XFS)
- `docs/generate-ssh-keys.md` - generate SSH keys for host access
- `docs/node_exporter_install.md` - Node Exporter install notes
- `docs/authentik-ldap-integration.md` - Authentik LDAP + SSSD integration

---

## 🧰 Scripts

- `scripts/check_system_info.sh` - generate a system info report file
- `scripts/check_update.sh` - detect distro, list updates, optionally apply updates
- `scripts/install-promtail.sh` - install/configure Promtail + systemd service
- `scripts/node_exporter_install.sh` - Node Exporter install script
- `scripts/authentik-ldap-intergration.sh` - SSSD setup against Authentik LDAP (supports `--help`)
- `scripts/replace-local-user.sh` - local user migration script (review and adjust variables before running)

Examples:

```bash
# From repo root
bash linux/scripts/check_system_info.sh

# Promtail install (requires sudo)
sudo bash linux/scripts/install-promtail.sh
```

---

## ⚠️ Safety Notes

- Always read scripts before running them; some are intentionally "ops sharp tools".
- `scripts/replace-local-user.sh` is destructive by design (user deletion/migration) - verify the config section first.
- Prefer Ansible (`../ansible/`) for repeatable changes; use these runbooks/scripts when you need a manual/one-off procedure.
