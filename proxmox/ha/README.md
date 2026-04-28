# 🖥️ High Availability

This folder stores HA-related configuration and health checks for the Proxmox management layer.

## Contents

- [keepalived](keepalived): Keepalived VRRP configuration and health-check script.

## What It Does

The HA design uses a floating management VIP so clients and automation can target one stable address even if the preferred Proxmox node changes.

Keepalived manages the VIP and uses node health to decide where it should live. HAProxy-style routing can then sit behind or alongside that VIP to present stable service access for Proxmox management endpoints.

## Practices Captured

- Prefer health-aware failover instead of simple host-up checks.
- Use descending node priorities so there is a normal preferred owner.
- Use unicast VRRP peers for predictable behavior on networks where multicast may not be available.
- Keep authentication values out of the public repository.
