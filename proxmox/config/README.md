# 🖥️ Proxmox Configuration Snapshots

This folder stores redacted configuration snapshots from the Proxmox cluster.

The files here are meant for documentation, comparison, and rebuild reference. They are not intended to be copied blindly onto a new node without reviewing hostnames, IP addresses, interface names, storage IDs, and secrets.

## Contents

- [ceph](ceph): Ceph cluster configuration snapshot.
- [network](network): Proxmox node network interface snapshots.
- [system](system): host-level boot and system tuning snippets.

## Redaction

Public values use example hostnames, example private IP ranges, and placeholder identifiers. Real cluster identifiers, interface names, and secrets should stay in the private repository only.
