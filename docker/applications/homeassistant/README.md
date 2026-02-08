# 🗂️ Home Assistant (Docker) ✨

> ✨ **What is Home Assistant?**
>
> Home Assistant is a home automation platform for smart devices, dashboards, and automations.

---

This folder contains a Docker Compose setup for **Home Assistant**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `homeassistant`
- Image: `homeassistant/home-assistant:2025.12`
- Networking: at least one service uses `network_mode: host`
- Published ports: `8123`

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

