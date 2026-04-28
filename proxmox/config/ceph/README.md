# 🖥️ Ceph Configuration

This folder contains a redacted Ceph configuration snapshot for the Proxmox cluster.

## File

- [ceph.conf](ceph.conf): documents the public network, cluster network, monitor placement, MDS placement, Ceph authentication mode, and selected OSD/MDS tuning values.

## What It Does

The configuration describes a three-node Ceph deployment integrated with Proxmox VE:

- `public_network` is used for client and monitor-facing Ceph traffic.
- `cluster_network` is used for backend replication and recovery traffic.
- `mon_host` lists the monitor addresses.
- `[mds.*]` sections describe metadata server placement.
- `[mon.*]` sections describe monitor public addresses.
- `osd_pool_default_size` and `osd_pool_default_min_size` define the default replication behavior.

## Notes

The FSID and addresses are redacted placeholders in this public copy. Do not reuse the placeholder FSID in a real Ceph cluster.
