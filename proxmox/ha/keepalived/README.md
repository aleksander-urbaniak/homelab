# 🖥️ Keepalived

This folder contains the Keepalived pieces used for Proxmox management VIP failover.

## Files

- [keepalived.txt](keepalived.txt): redacted per-node Keepalived VRRP configuration.
- [check-pve.sh](check-pve.sh): health-check script used by Keepalived to adjust node priority.

## What It Does

Keepalived runs the same VRRP instance on each Proxmox node. The nodes share a virtual IP on the management bridge, with different priorities so one node is normally preferred.

The `check-pve.sh` script verifies:

- `pve-cluster` is active.
- `pvecm status` reports quorum.
- the Proxmox API port `8006` is reachable locally.
- the Ceph manager service and port `8003` are healthy when a Ceph manager is present on the node.

If a check fails, the script exits non-zero. Keepalived then lowers that node's priority, allowing a healthier peer to take over the VIP.

## Notes

`CHANGE_ME_KEEPALIVED_PASS` is a placeholder. Replace it with a real VRRP authentication value in private configuration only.
