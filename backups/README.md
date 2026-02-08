# 🖥️ Homelab Backup Strategy ✨

> **Goal:** Keep backups **simple**, **predictable**, and **tested** — for two workload types:  
> **Proxmox VMs** + **K3s (Longhorn) persistent volumes**

---

## 🧭 At-a-Glance

| Area | Tooling | Target | Schedule |
|---|---|---|---|
| 🖥️ Proxmox VMs | Proxmox Backup Server (PBS) | Raspberry Pi NAS datastore | Weekly + monthly jobs |
| ☸️ K3s Volumes | Longhorn RecurringJob | NFS share (Raspberry Pi NAS) | 3× daily |
| ☁️ Offsite Backup| `rclone sync` | Google Drive folder | Weekly |

---

## 1) 🖥️ Proxmox VM Backups (PBS)

### ✅ Overview
- **Method:** Backups are managed by a dedicated **Proxmox Backup Server (PBS)** instance.
- **Target datastore:** All backups are stored in local NAS.

---

### ⏱️ Backup Jobs & Schedules

| Job Name | Schedule |
|---|---|
| K3S Master Nodes Backup | **Sunday** at **01:00** |
| K3S Worker Nodes Backup | **Sunday** at **02:00** |
| K3S Storage Nodes Backup | **Sunday** at **03:00** |
| Docker Standalone Backup | **Every 3rd day** of the month at **22:00** |
| PiHole DNS Backup | **Sunday** at **23:00** |

---

### 🧹 Datastore Retention Policy (Prune)

> The datastore is pruned on an **hourly schedule** to enforce retention.

**Retention rules**
- **Keep Last:** 3  
- **Keep Daily:** 14  
- **Keep Weekly:** 8  
- **Keep Monthly:** 6  

---

## 2) ☸️ K3s Cluster Backups (Longhorn)

### ✅ Overview
- **Recurring Job:** `longhorn-backup-3x-06-23-full`
- **Method:** Longhorn **native integrated backup**
- **What is backed up:** All persistent volumes assigned to the **`global-backup-3x`** group
- **Backup target:** Central **NFS share** on the **Raspberry Pi NAS**

---

### 🕒 Schedule & Behavior

- **Backup schedule:** **06:00**, **14:00**, **23:00** (daily)
- **Full backups:** every **21 incremental backups** *(~ weekly)*
- **Concurrency:** max **2** backups running simultaneously
- **Retention:** retain the **last 90 backups**

---

## 3) ☁️ Offsite Backup (Google Drive)

### ✅ Overview
> Protects against **total loss of local backup storage** (fire, theft, catastrophic hardware failure).

- **Method:** `rclone sync` to Google Drive
- **Source:** Primary backup storage directories on the local NAS
- **Destination:** Dedicated folder in **Google Drive**
- **Schedule:** **Once per week**
