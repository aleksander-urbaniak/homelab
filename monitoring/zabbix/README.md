# 📈 Zabbix

Zabbix is used as the broad infrastructure monitoring platform for the homelab.

## Current Role

Zabbix monitors:

- hosts and VMs
- hardware resources
- CPU, memory, disk, and network usage
- network devices and SNMP-capable services
- websites and service availability
- Zabbix agent data from Linux systems
- Proxmox/Ceph-related availability where appropriate

## Runtime

The current Zabbix deployment runs on a separate Oracle Linux 10 VM with Docker.

The Docker source of truth is:

[docker/applications/zabbix](../../docker/applications/zabbix)

## Stack Shape

The Docker Compose stack contains:

- `zabbix-db`: PostgreSQL database backend
- `zabbix-server-pgsql`: Zabbix server using PostgreSQL
- `zabbix-server-web`: web UI served through nginx/PHP
- `zabbix-snmptraps`: SNMP trap receiver

Published service ports include:

- `10051/tcp` for Zabbix server/agent communication
- `162/udp` mapped to the SNMP trap container

## Configuration Practices

- Keep database credentials in `.env`, not in committed compose files.
- Keep SNMP MIBs and trap data on persistent host paths.
- Use Zabbix templates for host resources, services, websites, and network devices.
- Prefer Zabbix for broad availability and infrastructure monitoring, while Prometheus focuses on K3s metrics.

## Redaction

The public docs do not include real Zabbix database passwords, monitored hostnames, SNMP communities, URLs, or internal addresses.
