# 📈 Monitoring

This folder documents the homelab monitoring and security-observability split.

The public copy is intentionally descriptive instead of a full raw export. The live configuration is spread across Docker and Kubernetes application folders, and some source files contain runtime secrets or environment-specific endpoints that must stay out of this public area.

## Stack Overview

| Area | Tooling | Primary Purpose | Runtime |
| --- | --- | --- | --- |
| Infrastructure monitoring | Zabbix | hosts, hardware resources, network checks, websites, SNMP, service availability | Oracle Linux 10 VM with Docker |
| Kubernetes observability | Prometheus, Grafana, Loki, Alertmanager, node exporter | K3s metrics, dashboards, logs, alerting | K3s cluster |
| Security monitoring | Wazuh | endpoint/security events, agent enrollment, manager/indexer/dashboard | Docker |

## Source Of Truth

- Zabbix Docker stack: [docker/applications/zabbix](../docker/applications/zabbix)
- Wazuh Docker stack: [docker/applications/wazuh](../docker/applications/wazuh)
- Prometheus Helm values and rules: [kubernetes/applications/ceph-storage/helm/prometheus](../kubernetes/applications/ceph-storage/helm/prometheus)
- Grafana manifests: [kubernetes/applications/ceph-storage/manifests/grafana](../kubernetes/applications/ceph-storage/manifests/grafana)
- Loki manifests: [kubernetes/applications/ceph-storage/manifests/loki](../kubernetes/applications/ceph-storage/manifests/loki)

## Responsibility Boundaries

Zabbix is the broad infrastructure monitor. It is used for physical/virtual hosts, operating-system resources, hardware and network visibility, website checks, SNMP traps, and general service availability.

Prometheus is the Kubernetes metrics stack. It watches the K3s cluster, Kubernetes objects, exporters, Prometheus itself, Alertmanager, Proxmox exporter targets, and Ceph metrics.

Grafana is the dashboard layer for Prometheus and Loki. It runs in Kubernetes with persistent storage and ingress through Traefik.

Loki is the log store for Kubernetes-focused log exploration. It runs as a single-replica StatefulSet with filesystem storage and retention enabled.

Alertmanager handles Prometheus alerts and forwards notifications through a redacted receiver configuration.

Wazuh is the security monitoring stack. It handles endpoint/security telemetry, manager/API functions, indexing, dashboard access, and notification relay integration.

## Redaction Rules

Do not copy these values into this public folder:

- Grafana OAuth client secrets
- Wazuh indexer/API/dashboard passwords
- Zabbix database passwords
- Alertmanager webhooks
- real hostnames, domains, public endpoints, or private IPs
- TLS private keys, generated certificates, agent enrollment secrets, or peer/client configs

Use placeholders such as `example.com`, `192.0.2.10`, `REPLACE_ME`, or environment variable names when documenting public examples.

## Folder Layout

```text
monitoring/
|-- prometheus-stack/
|-- wazuh/
|-- zabbix/
`-- README.md
```
