# 🌐 Networking (Homelab) ✨

> ✨ **What is this?**
>
> A concise overview of how networking, segmentation, and access are handled in this homelab.

---

This folder documents the network model used across Proxmox, K3s, and standalone Docker apps.

## 🧭 Quick facts

- **Firewalling is Proxmox-first**: rules live at the hypervisor using aliases, IP sets, and groups.
- **No host-level firewalls**: OS firewalls are kept minimal; policy is centralized in Proxmox.
- **Cloudflare Tunnel is the only ingress** for public exposure and VPN-style access.
- **Nginx Proxy Manager is the front door** for HTTP(S) services (including K3s apps).
- **Segmentation by VLAN**: separate networks for IoT, K3s nodes, Proxmox nodes, and trusted clients.

---

## 🗺️ Topology overview

- **Proxmox** hosts VMs/LXC and enforces inter-VLAN policy.
- **K3s** runs internal services; none are exposed directly on node IPs.
- **Docker apps** live on separate hosts/VMs and are reachable only through NPM.

## 🔒 Firewall model (Proxmox)

Centralizing rules at the Proxmox layer keeps policies consistent and easy to audit.
Aliases and IP sets group hosts, roles, and services so rules stay readable.

Reference files:

- `proxmox/firewall/cluster.fw`
- `proxmox/firewall/cluster.fw.md`

## 🧩 VLAN segmentation

Typical segments in this lab:

- **Proxmox nodes** (management + VM/LXC networks)
- **K3s node network**
- **IoT devices** (restricted egress and minimal lateral access)
- **General LAN / trusted clients**
- **Optional segments** (storage/backup or a DMZ-style network)

Inter-VLAN routing is allow-listed and enforced by the Proxmox firewall.

## 🧠 Pi-hole DNS

- **Multiple Pi-hole resolvers** provide redundancy (VMs and/or a small NAS node).
- **Nebula Sync keeps them aligned** (blocklists, local records, and settings).
- **Clients use Pi-hole for LAN DNS**, while K3s keeps its own CoreDNS for in-cluster names.

## 🌍 Remote & public access

- **Cloudflare Tunnel is the only ingress** from the Internet.
- **Public services are published via cloudflared** with no direct inbound port forwards.
- Services remain private on the LAN/VLANs and are accessed through tunnel policies.

## 🔁 Service routing pattern

Typical flows:

- **K3s service**: `Cloudflare Tunnel -> Nginx Proxy Manager (K3s) -> K3s service`
- **External service (Docker/VM)**: `Cloudflare Tunnel -> Nginx Proxy Manager (K3s) -> External service`

Notes:

- **Public DNS points to the tunnel**: Cloudflare DNS records resolve to the Tunnel endpoint.
- **NPM routes by hostname** and forwards to the internal IP/hostname of the target service.
- If the target is **inside K3s**, NPM points at the **cluster DNS service name** (e.g., `service.namespace.svc.cluster.local`).
- If the target is **outside K3s**, NPM points at the **standalone host IP and port** for that Docker/VM service.
- **All K3s services are hidden behind Nginx Proxy Manager**.
- **Docker apps allow ingress only from the K3s NPM endpoints** via firewall rules.
