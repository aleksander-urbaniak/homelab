# 📈 Wazuh

Wazuh is used for security monitoring and endpoint/security telemetry.

## Current Role

Wazuh covers:

- security event collection
- endpoint agent telemetry
- manager/API functions
- indexing and search
- dashboard access
- notification relay integration

## Runtime

The current Wazuh stack is Docker-based.

The Docker source of truth is:

[docker/applications/wazuh](../../docker/applications/wazuh)

## Stack Shape

The Docker Compose stack contains:

- `wazuh.indexer`: Wazuh indexer / OpenSearch-compatible storage
- `wazuh.manager`: Wazuh manager, API, agent communication, Filebeat integration
- `wazuh.dashboard`: Wazuh dashboard
- `postfix`: optional notification relay

Published ports include:

- `9200/tcp` for indexer access
- `1514/tcp` and `1515/tcp` for agent/event communication and enrollment workflows
- `514/udp` for syslog-style ingestion
- `55000/tcp` for the Wazuh API
- `4443/tcp` mapped to the dashboard service

## Configuration Practices

- Store all passwords in `.env` or private secret management.
- Keep TLS certificates and private keys under private runtime storage.
- Keep Wazuh manager, dashboard, and indexer configuration files outside public docs when they include environment-specific values.
- Use the postfix relay only with private relay credentials and allowed sender/domain settings.

## Custom HTML Alerts

Custom HTML email alerts using the Wazuh integrator are documented in:

[custom-html-email-alerts.md](custom-html-email-alerts.md)

Preview of the styled Wazuh notification:

![Wazuh HTML alert preview](assets/image.png)

## Redaction

The public docs do not include Wazuh indexer passwords, API passwords, dashboard credentials, relay credentials, generated certificates, private keys, agent keys, real hostnames, or private IPs.
