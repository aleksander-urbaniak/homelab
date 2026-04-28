# 📦 Wazuh (Docker) ✨

This folder contains a Docker Compose setup for a standalone Wazuh stack with an indexer, manager, dashboard, and optional postfix relay.

## Files

- `compose.yml`: Wazuh stack definition
- `.env.example`: Example credentials and relay settings

## Notes

- Copy `.env.example` to `.env` and replace all placeholder values before starting the stack.
- Review all bind mounts under `/mnt/docker/wazuh` and ensure the required host files exist.
- The postfix relay is included because the active private stack uses it for notifications.

## Deploy

Run from this folder:

```bash
cp .env.example .env
docker compose -f compose.yml up -d
```
