# 🗂️ Nextcloud (Docker)

> ✨ **What is Nextcloud?**
>
> Nextcloud is a self-hosted file sync and collaboration platform (files, sharing, calendars, contacts, and more).

---

This folder contains a Docker Compose setup for **Nextcloud** (app + PostgreSQL).

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `nextcloud-postgres`, `nextcloud-app`
- Images: `postgres:17`, `nextcloud:31`
- Published ports: `${NEXTCLOUD_PORT} -> 80`
- Environment: uses `.env` (see `.env.example`)

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack
- `.env.example`: Example environment variables (copy to `.env`)

## Configuration notes

- **Environment**: copy `.env.example` to `.env` and fill in values before starting the stack.
- **Storage**: this stack uses bind mounts under `/mnt/docker/nextcloud/` (`db/` and `html/`).
- **Reverse proxy**: expose the service on `NEXTCLOUD_PORT` and set `NEXTCLOUD_TRUSTED_DOMAINS` for your domain(s).
- **Images**: `compose.yml` is the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

Run commands from this folder (so relative paths work as expected).

### Option A: start the stack

1. Create `.env` from the example:
```bash
cp .env.example .env
```

2. Start the stack:
```bash
docker compose -f compose.yml up -d
```
