# 📦 wg-easy (Docker) ✨

This folder contains a Docker Compose setup for `wg-easy`, a lightweight WireGuard VPN server with a web UI.

## Files

- `compose.yml`: WireGuard and UI stack

## Notes

- Review published ports before deployment.
- Ensure the host allows the required kernel capabilities and sysctls.

## Deploy

Run from this folder:

```bash
docker compose -f compose.yml up -d
```
