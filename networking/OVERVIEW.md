# Networking Overview 🌐

This homelab uses a simple, reliable network layout that prioritizes:

- **Redundant DNS** (multiple resolvers)
- **Centralized, human-friendly routing** (reverse proxy)
- **Separation of concerns** (LAN DNS vs in-cluster DNS)

## Pi-hole DNS 🧩

### Topology

There are **3 Pi-hole instances**:

- **2× Proxmox VMs**
- **1× instance on a Raspberry Pi NAS**

All three instances are kept consistent using **Nebula-sync**, so blocklists, local records, and settings stay aligned.

### Why 3 instances?

- **High availability**: if one node is down (maintenance/reboot), clients can still resolve DNS.
- **Load sharing**: clients naturally spread queries across resolvers.
- **Independence**: one Pi-hole can be upgraded or restarted without taking DNS down.

### Client configuration (recommended)

- Point your LAN clients / DHCP to **multiple DNS servers** (all Pi-hole instances).
- Keep at least one Pi-hole outside the Kubernetes cluster so DNS keeps working even during cluster maintenance.

### Upstream DNS

Pi-hole forwards queries upstream. Typical options:

- A trusted recursive resolver (Unbound)
- Public resolvers (if you accept the trade-offs)
- DNS over HTTPS / DNS over TLS (where supported)

## Kubernetes DNS (K3s) ☸️

Inside the cluster, Kubernetes uses **CoreDNS** for service discovery (e.g. `service.namespace.svc.<cluster-domain>`).

Best practice:

- Let in-cluster apps use **CoreDNS** for service discovery.
- Use **Pi-hole** for LAN/client DNS and for resolving your homelab public domain (if you use split-horizon DNS).

## High Availability VIPs (keepalived) 🛟

For stable access to critical endpoints, you can use **keepalived** (VRRP) to provide a **Virtual IP (VIP)** that floats between nodes.

### K3s control-plane VIP

On **K3s master/control-plane nodes**, keepalived can manage a VIP used for:

- The Kubernetes API endpoint (`:6443`)
- A stable address for management tools (kubectl, GitOps tooling, CI runners, etc.)

> Note: some setups use **kube-vip** for the Kubernetes control-plane VIP. keepalived is a solid alternative when you prefer a host-level VRRP VIP.

### Proxmox cluster VIP

On **Proxmox nodes**, keepalived can provide a VIP for:

- A single, stable URL/IP for the Proxmox UI/API (`:8006`)
- “Always the same endpoint” access during node maintenance/reboots

### Networking notes

- VRRP uses **IP protocol 112** (not TCP/UDP) and the VRRP multicast group (`224.0.0.18` on IPv4).
- If you enforce strict firewalling, make sure VRRP is allowed between participating nodes.
- Use distinct `virtual_router_id` values per VIP, and prefer `auth_pass` (or stronger designs if required).

## Reverse Proxy 🔁

For HTTP(S) access to services, this homelab uses:

- **Nginx Proxy Manager (NPM)** as the reverse proxy
- **Let’s Encrypt certificates** for TLS

Benefits:

- Central place for routing rules and SSL termination
- Consistent URLs across services
- Easy to publish internal-only services or expose selected ones externally (see below)

## External Access (optional) 🚪

If you want to expose services without opening inbound ports on your router, this repo also includes **Cloudflared (Cloudflare Tunnel)** patterns.

Common approach:

- Public entry: Cloudflare Tunnel → NPM → internal service
- Keep origin services private on the LAN/VPN

## Load Balancing on Bare Metal ⚖️

For Kubernetes Services of type `LoadBalancer`, the lab uses **MetalLB** to allocate LAN addresses (or example ranges in this repo).

This is useful for:

- Exposing NPM, Pi-hole, and other edge services on stable IPs
- Avoiding NodePort complexity for “infrastructure” services

## Firewall Notes 🛡️

The Proxmox cluster firewall is documented in:

- `proxmox/firewall/cluster.fw`
- `proxmox/firewall/cluster.fw.md`

The intent is to allow only the required ports between:

- LAN clients ↔ Pi-hole (DNS + optional UI)
- LAN/servers ↔ reverse proxy (HTTP/HTTPS)
- Monitoring systems ↔ exporters
- Kubernetes nodes ↔ each other
