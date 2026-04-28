# 📦 Zabbix (Docker) ✨

> ✨ **What is Zabbix?**
>
> Zabbix is a full-featured monitoring platform for infrastructure and applications.

---

This folder contains a Docker Compose setup for **Zabbix**.

## 🎯 Quick facts

- Compose file(s): `compose.yml`
- Services: `zabbix-db`, `zabbix-snmptraps`, `zabbix-server-pgsql`, `zabbix-server-web`
- Images: `postgres:16`, `zabbix/zabbix-snmptraps:alpine-trunk`, `zabbix/zabbix-server-pgsql:alpine-trunk`, `zabbix/zabbix-web-nginx-pgsql:alpine-trunk`
- Published ports: `162 -> 1162/udp`, `10051`
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
