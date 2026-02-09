# Nexterm (Docker)

Nexterm is a self-hosted web terminal and remote access UI.

This folder contains a Docker Compose setup for Nexterm.

## Quick facts

- Compose file(s): `compose.yml`
- Service: `nexterm`
- Image: `germannewsmaker/nexterm:latest`
- Published ports: `${NEXTERM_PORT} -> 6989`
- Environment: uses `.env` (see `.env.example`)

## What gets deployed

- `compose.yml`: Docker Compose stack
- `.env.example`: Example environment variables (copy to `.env`)

## Configuration notes

- Environment: copy `.env.example` to `.env` and set a unique `NEXTERM_ENCRYPTION_KEY`.
- Security: generate a strong 64-hex encryption key, for example: `openssl rand -hex 32`.
- Storage: app data is persisted in the named Docker volume `nexterm-data`.
- Networking: this setup uses bridge networking and publishes `NEXTERM_PORT`.

## Deploy

Run commands from this folder.

1. Create `.env` from the example:

```bash
cp .env.example .env
```

2. Start the stack:

```bash
docker compose -f compose.yml up -d
```
