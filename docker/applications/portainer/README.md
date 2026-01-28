# 🗂️ Portainer (Docker)

> ✨ **What is Portainer?**
>
> Portainer provides a web UI to manage container environments (Docker and Kubernetes).

---

This folder contains a Docker Compose setup for **Portainer**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `agent`, `portainer`
- Images: `portainer/agent:2.27.3`, `portainer/portainer-ce:2.27.3`
- Published ports: `8000`, `9000`, `9443`

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack

## Configuration notes

- **Storage**: review bind mounts / volume paths and ensure host directories exist with correct permissions.
- **Updates**: image tags are pinned in the compose file; update them when you want to upgrade.

## Deploy 🚀

Run commands from this folder (so relative paths like `./data` work).

### Option A: start the stack

Start the stack:
```bash
docker compose -f compose.yml up -d
```
