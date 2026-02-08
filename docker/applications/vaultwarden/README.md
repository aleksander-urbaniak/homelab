# 🗂️ Vaultwarden (Docker) ✨

> ✨ **What is Vaultwarden?**
>
> Vaultwarden is a lightweight, self-hosted Bitwarden-compatible password manager server.

---

This folder contains a Docker Compose setup for **Vaultwarden**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `vaultwarden`, `vaultwarden-db`
- Images: `vaultwarden/server:1.35.2`, `postgres:16`
- Published ports: `80`
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
