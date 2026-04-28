# 📦 Jellyfin (Docker) ✨

> ✨ **What is Jellyfin?**
>
> Jellyfin is a self-hosted media server for streaming your movies, shows, and music.

---

This folder contains a Docker Compose setup for **Jellyfin**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `jellyfin`
- Image: `jellyfin/jellyfin:10.11.6`
- Published ports: `8096`, `8920`

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

