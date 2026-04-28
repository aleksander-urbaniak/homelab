# 🖥️ Network Configuration

This folder contains redacted network interface snapshots for the Proxmox nodes.

## File

- [interfaces.txt](interfaces.txt): exported `/etc/network/interfaces` style configuration for three Proxmox nodes.

## What It Does

The layout separates management traffic from Ceph/cluster traffic:

- `vmbr0` is the main Proxmox management bridge.
- `nic0` is the physical bridge uplink.
- A dedicated secondary interface is used for Ceph backend traffic.
- Each node has a management IP and a separate Ceph/cluster IP.

## Practices Captured

- Keep Proxmox management on a bridge so VMs and host services can share the uplink cleanly.
- Keep storage replication on a separate subnet/interface to reduce contention.
- Keep the exported file as a reference snapshot, not as a universal template.

The interface names and IP ranges are public-safe examples.
