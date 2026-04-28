# 📦 Docker Catalog ✨

This folder contains the public Docker catalog mirrored from the private homelab Docker repo.

## Current active standalone apps

- `flaresolverr`
- `homeassistant`
- `jackett`
- `jellyfin`
- `pihole`
- `portainer-agent`
- `qbittorrent`
- `radarr`
- `sonarr`
- `wazuh`
- `wg-easy`

## Layout

- `applications/<app>/compose.yml`: per-app Docker Compose stack
- `applications/<app>/.env.example`: placeholder environment values when an app needs secrets or local overrides
- `config/`: shared Docker daemon configuration
- `scripts/`: host bootstrap and migration helpers

## Public redaction rules

- Secrets, passwords, API tokens, relay credentials, and emails are replaced with placeholders such as `REPLACE_ME` and `user@example.com`.
- Host-specific deployment targets from the private repo are intentionally not published here.

## Notes

- Some additional app folders in `applications/` are kept as public reference examples even if they are not part of the currently active private Docker deployment set.
- Review bind mounts, ports, and `.env` values before using any stack in another environment.
