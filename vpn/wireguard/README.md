# 📘 WireGuard (wg-easy) on Proxmox LXC (Host Networking + Double NAT) ✨

This guide describes a stable WireGuard setup using the `wg-easy` Docker image inside a Proxmox LXC container with `network_mode: host`. It is tuned for a double-NAT LAN environment and avoids Docker bridge complexity.

All domains and IPs below are examples. Replace them with your environment.

## Environment

- Host: Proxmox VE (LXC container).
- OS: RHEL 9 (RHEL-based).
- Networking: `network_mode: host` so WireGuard can manage `wg0` directly.
- Runtime: Docker (or a Docker-compatible runtime) is required to run `wg-easy`.

## Variables (Example Values)

```
VPN_FQDN=vpn.example.com
WG_PORT=51820
UI_PORT=80
LAN_DNS_IP=192.0.2.53
WG_SUBNET=10.20.30.0/24
WAN_ROUTER_IP=203.0.113.1
LAN_ROUTER_IP=192.0.2.254
LXC_IP=192.0.2.12
```

## Docker Compose

`docker-compose.yml`

```yaml
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:15
    container_name: wg-easy
    network_mode: host
    environment:
      - WG_HOST=vpn.example.com
      - WG_DEFAULT_DNS=192.0.2.53
      - WG_MTU=1280
      - PORT=80
      - WG_PORT=51820
    volumes:
      - /mnt/docker/wg-easy/etc:/etc/wireguard
      - /lib/modules:/lib/modules:ro
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
```

## Port Forwarding Chain

If you have two routers, the UDP "knock" must reach the LXC through both.

- Router 1 (WAN/public): forward UDP `51820` to Router 2 (`LAN_ROUTER_IP`).
- Router 2: forward UDP `51820` to the LXC IP (`LXC_IP`).
- Proxmox firewalls: allow UDP `51820` and TCP `80` on Datacenter, Node, and LXC levels.

## Linux Networking and Persistence

### 1) Enable IP forwarding (permanent)

Edit `/etc/sysctl.conf` and add:

```bash
net.ipv4.ip_forward = 1
```

Apply it:

```bash
sudo sysctl -p
```

### 2) iptables rules (insert at top)

Using `-I` inserts rules at the top so they are not blocked by default reject rules.

```bash
# Allow WireGuard handshake
iptables -I INPUT 1 -p udp --dport 51820 -j ACCEPT
# Allow wg-easy web UI
iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
# NAT: VPN subnet to LAN/WAN
iptables -t nat -I POSTROUTING 1 -s 10.20.30.0/24 -o eth0 -j MASQUERADE
# Allow forwarding between VPN and LAN/WAN
iptables -I FORWARD 1 -i wg0 -j ACCEPT
iptables -I FORWARD 1 -o wg0 -j ACCEPT
# Fix MSS for double NAT
iptables -I FORWARD 1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
```

Note: replace `eth0` with the correct interface name on your host.

### 3) Persist rules on RHEL

```bash
sudo dnf install -y iptables-services
sudo systemctl enable iptables
sudo iptables-save > /etc/sysconfig/iptables
```

## Final Adjustments

- MTU: set `WG_MTU=1280` (and on clients) to avoid large packets getting stuck in double NAT.
- DNS: if using Pi-hole or another LAN DNS, allow queries from the VPN subnet.

## Verification

```bash
# WireGuard interface is up
ip addr show wg0

# WireGuard peers and handshakes
wg show
```

## Result

After applying this setup:
- WireGuard connects reliably through double NAT.
- VPN clients reach LAN and internet.
- Rules survive reboot.
