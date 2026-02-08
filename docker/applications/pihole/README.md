# 🗂️ Pi-hole (Docker) ✨

> ✨ **What is Pi-hole?**
>
> Pi-hole is a network-wide ad blocker and DNS sinkhole.

---

This folder contains a Docker Compose setup for **Pi-hole**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `pihole`
- Image: `pihole/pihole:2025.11.1`
- Published ports: `53/tcp`, `53/udp`, `${PIHOLE_WEB_PORT} -> 80/tcp`
- Environment: uses `.env` (see `.env.example`)

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack
- `.env.example`: Example environment variables (copy to `.env`)

## Configuration notes

- **Environment**: copy `.env.example` to `.env` and fill in values before starting the stack.
- **DNS port**: this container binds host port `53`; ensure nothing else on the host is using it.
- **Storage**: this stack uses bind mounts under `/mnt/docker/pihole/` for persistence.
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
