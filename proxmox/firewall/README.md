# 🖥️ Proxmox Firewall

This folder documents the Proxmox firewall approach for the cluster.

In the private repository this area can include exported cluster-level and VM-level firewall files. In this public copy, raw firewall exports may be omitted or redacted to avoid publishing environment topology.

## What The Firewall Does

The firewall is designed around a default-deny posture:

- Inbound traffic is allowed only from known source groups.
- Outbound traffic is kept explicit where the platform allows it.
- Management access is limited to administrative hosts and trusted infrastructure.
- Monitoring access is limited to Prometheus, Zabbix, and other observability components.
- DNS, ingress, backup, Ceph, and exporter traffic are allowed through named service groups rather than scattered one-off rules.

## Configuration Practices

- Use aliases for important hosts and subnets, such as gateways, admin workstations, monitoring servers, backup targets, and ingress controllers.
- Use IPSets for groups of related nodes, such as Proxmox nodes, Pi-hole nodes, and K3s cluster members.
- Use reusable rule groups for common access patterns like SSH, DNS, node exporter, Proxmox API, Ceph metrics, and web ingress.
- Keep shared policy at cluster level and workload-specific rules at VM level when raw exports are included.
- Keep comments focused on service intent so future changes are easier to audit.

## Redaction Notes

- Private hostnames should be replaced with names like `pve-node01`, `k3s-worker01`, and `admin-workstation`.
- Private IPs should be replaced with example private ranges.
- Firewall comments should not reveal real users, sites, domains, workstation names, or service endpoints.
- Secrets and unique identifiers should never be stored in firewall exports.
