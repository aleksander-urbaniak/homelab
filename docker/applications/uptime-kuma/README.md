# 🗂️ Uptime Kuma (Docker)

> ✨ **What is Uptime Kuma?**
>
> Uptime Kuma is a self-hosted uptime monitoring and status dashboard.

---

This folder contains a Docker Compose setup for **Uptime Kuma**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `uptime-kuma`
- Image: `louislam/uptime-kuma:2.0.2`
- Published ports: `3001`

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack

## Configuration notes

- **Storage**: review bind mounts / volume paths and ensure host directories exist with correct permissions.
- **Updates**: image tags are pinned in the compose file; update them when you want to upgrade.
- **Images**: `compose.yml` is the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

Run commands from this folder (so relative paths like `./data` work).

### Option A: start the stack

Start the stack:
```bash
docker compose -f compose.yml up -d
```
