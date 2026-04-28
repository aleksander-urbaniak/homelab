# 🌐 WireGuard VPN with wg-easy

This folder documents the current WireGuard VPN setup using `wg-easy` on an Oracle Linux 10 VM running Docker.

The public copy keeps the service shape, ports, Linux capabilities, sysctls, and volume layout visible, but avoids publishing real hostnames, public IPs, peer configs, keys, passwords, or environment-specific routing details.

## Environment

| Item | Value |
| --- | --- |
| Host type | VM |
| OS | Oracle Linux 10 |
| Runtime | Docker / Docker Compose |
| VPN service | `wg-easy` |
| VPN UDP port | `51820/udp` |
| Web UI port | `80/tcp` |
| Persistent config path | `/mnt/docker/wg-easy/etc` |

## Files

- [compose.yml](compose.yml): redacted Docker Compose definition for the `wg-easy` container.

## What The Compose File Does

The compose file runs `ghcr.io/wg-easy/wg-easy` with:

- UDP `51820` published for WireGuard clients.
- TCP `80` published for the wg-easy web UI.
- `/etc/wireguard` persisted to a host-mounted data directory.
- `/lib/modules` mounted read-only so the container can access host kernel modules when needed.
- `NET_ADMIN` and `SYS_MODULE` capabilities for WireGuard/network management.
- IPv4 forwarding and `src_valid_mark` sysctls enabled for VPN routing.
- `restart: unless-stopped` so the VPN service returns after reboots or Docker restarts.

## Docker Compose

```yaml
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:15.2.2
    container_name: wg-easy
    ports:
      - "51820:51820/udp"
      - "80:80/tcp"
    volumes:
      - /mnt/docker/wg-easy/etc:/etc/wireguard
      - /lib/modules:/lib/modules:ro
    environment:
      - PORT=80
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
```

## Operational Notes

- Keep the wg-easy data directory private; it can contain generated WireGuard configuration, keys, and peer data.
- Protect the web UI behind trusted network access, a reverse proxy with authentication, firewall rules, or another access-control layer.
- Forward UDP `51820` from the edge router/firewall to the VM if clients need to connect from outside the LAN.
- Allow TCP `80` only from trusted administrative networks if the UI is exposed beyond localhost.
- Keep real `WG_HOST`, password/hash, DNS, and peer-specific settings out of the public repository if they are added later.

## Oracle Linux 10 Host Notes

On the VM, Docker must be installed and running before starting the stack. The host also needs kernel support for WireGuard and packet forwarding.

Typical checks:

```bash
docker version
docker compose version
sysctl net.ipv4.ip_forward
lsmod | grep wireguard || true
```

## Start and Update

From this folder on the target VM:

```bash
docker compose up -d
docker compose ps
docker logs wg-easy --tail=100
```

To update the image:

```bash
docker compose pull
docker compose up -d
```

## Verification

```bash
# Container status
docker compose ps

# Published ports
ss -tulpen | grep -E '(:80|:51820)'

# WireGuard state from inside the container
docker exec wg-easy wg show
```

## Redaction Notes

The public compose intentionally omits real public endpoints, UI credentials, peer names, keys, and client configuration. Treat anything under `/mnt/docker/wg-easy/etc` as private runtime state.
