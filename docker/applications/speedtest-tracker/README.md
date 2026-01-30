# 🗂️ Speedtest Tracker (Docker)

> ✨ **What is Speedtest Tracker?**
>
> Speedtest Tracker runs scheduled speed tests and stores results for history and graphs.

---

This folder contains a Docker Compose setup for **Speedtest Tracker**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `speedtest-tracker`, `speedtest-tracker-db`
- Images: `lscr.io/linuxserver/speedtest-tracker:1.13.5`, `postgres:15`
- Published ports: none (likely exposed via reverse proxy or host networking)
- Environment: uses `.env` (see `.env.example`)

---

## 🧱 What gets deployed

- `compose.yml`: Docker Compose stack
- `.env.example`: Example environment variables (copy to `.env`)

## Configuration notes

- **Environment**: copy `.env.example` to `.env` and fill in values before starting the stack.
- **Storage**: review bind mounts / volume paths and ensure host directories exist with correct permissions.
- **Updates**: image tags are pinned in the compose file; update them when you want to upgrade.

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
