# 📦 Nginx Proxy Manager (Docker) ✨

> ✨ **What is Nginx Proxy Manager?**
>
> Nginx Proxy Manager provides a web UI for managing Nginx reverse-proxy hosts and certificates.

---

This folder contains a Docker Compose setup for **Nginx Proxy Manager**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `nginx-proxy-manager`, `nginx-proxy-manager-db`
- Images: `jc21/nginx-proxy-manager:jc21/nginx-proxy-manager:2.13.6`, `jc21/mariadb-aria:10.11.5-innodb`
- Published ports: `80`, `443`, `8888 -> 81`
- Environment: uses `.env` (see `.env.example`)

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack
- `.env.example`: Example environment variables (copy to `.env`)

## Configuration notes

- **Environment**: copy `.env.example` to `.env` and fill in values before starting the stack.
- **Storage**: review bind mounts / volume paths and ensure host directories exist with correct permissions.
- **Updates**: image tags are pinned in the compose file; update them when you want to upgrade.
- **Images**: `compose.yml` is the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

Run commands from this folder (so relative paths like `./data` work).

### Option A: start the stack

1. Create `.env` from the example:
```bash
cp .env.example .env
```

2. Start the stack:
```bash
docker compose -f compose.yml up -d
```
