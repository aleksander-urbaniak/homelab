# Custom HTML Email Alerts in Prometheus Alertmanager

This guide explains how to configure styled, Prometheus-style HTML email notifications in Alertmanager.

All domains, email addresses, webhook URLs, target IPs, and hostnames below are examples. Replace them with values from your own environment.

## Goal

Create polished HTML email alerts for Prometheus alert groups, including:

- Alert status
- Alert name
- Severity
- Receiver group
- Impacted target count
- Active incident details
- Labels and annotations
- An `Analyze in Prometheus` button

The final flow is:

```text
PrometheusRule -> Prometheus alert evaluation -> Alertmanager receiver -> HTML email
```

## Preview

The final email should look similar to this redacted preview:

![Prometheus Alertmanager HTML alert preview](assets/image.png)

## 1. Define Prometheus Alert Rules

Store alert rules as YAML files in the Prometheus rules directory used by your Helm deployment.

Example:

```yaml
groups:
  - name: Storage
    rules:
      - alert: StorageHealthWarning
        expr: storage_health_status == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: Cluster health is WARNING
          description: Storage reports HEALTH_WARN for more than 10 minutes. Check cluster health detail.
```

Recommended fields:

- `alert`: short alert name
- `expr`: PromQL expression
- `for`: how long the expression must remain true
- `labels.severity`: notification severity
- `annotations.summary`: short human-readable summary
- `annotations.description`: longer diagnostic text

## 2. Configure Alertmanager In Helm Values

In the Prometheus Helm values file, enable Alertmanager and configure a receiver.

Example:

```yaml
alertmanager:
  enabled: true
  config:
    enabled: true
    global:
      resolve_timeout: 5m
      smtp_smarthost: smtp.example.com:587
      smtp_from: alerts@example.com
      smtp_auth_username: alerts@example.com
      smtp_auth_password_file: /etc/alertmanager/secrets/smtp-password
      smtp_require_tls: true
    route:
      group_by:
        - alertname
        - instance
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 9999h
      receiver: email-alerts
    receivers:
      - name: email-alerts
        email_configs:
          - to: recipient@example.com
            send_resolved: true
            require_tls: true
            headers:
              subject: '[{{ .Status }}] {{ .CommonLabels.alertname }}'
            html: |
              <!-- HTML template goes here -->
```

Use a Kubernetes Secret or external secret management for SMTP passwords. Do not commit real SMTP passwords or app passwords.

## 3. Add The HTML Email Template

Paste this into the `html: |` block of the `email_configs` entry.

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#f1f5f9;color:#334155;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f1f5f9;padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="600" cellspacing="0" cellpadding="0" style="width:600px;max-width:calc(100% - 32px);background-color:#ffffff;border:1px solid #e2e8f0;border-radius:16px;box-shadow:0 20px 25px -5px rgba(0,0,0,0.03),0 10px 10px -5px rgba(0,0,0,0.03);overflow:hidden;border-collapse:collapse;">
          <tr>
            <td style="height:8px;background:{{ if eq .Status "firing" }}linear-gradient(135deg, #e11d48 0%, #f97316 100%){{ else }}linear-gradient(135deg, #16a34a 0%, #0ea5e9 100%){{ end }};"></td>
          </tr>
          <tr>
            <td style="padding:36px 36px 24px 36px;text-align:left;">
              <div style="margin-bottom:12px;text-align:left;">
                <span style="display:inline-block;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.08em;padding:4px 12px;border-radius:20px;background-color:{{ if eq .Status "firing" }}#ffe4e6{{ else }}#dcfce7{{ end }};color:{{ if eq .Status "firing" }}#e11d48{{ else }}#16a34a{{ end }};border:1px solid {{ if eq .Status "firing" }}#fecdd3{{ else }}#bbf7d0{{ end }};">{{ if eq .Status "firing" }}Firing Alert{{ else }}Resolved Alert{{ end }}</span>
                <span style="display:inline-block;font-size:11px;font-weight:600;color:#64748b;margin-left:10px;font-family:Consolas,Monaco,monospace;vertical-align:middle;">{{ range .GroupLabels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}</span>
              </div>
              <h1 style="font-size:24px;font-weight:800;color:#0f172a;margin:0;letter-spacing:0;line-height:1.2;text-align:left;">{{ .CommonLabels.alertname }}</h1>
            </td>
          </tr>
          <tr>
            <td style="padding:0 36px 32px 36px;">
              <table role="presentation" cellspacing="0" cellpadding="0" style="width:100%;border-collapse:collapse;">
                <tr>
                  <td style="width:32%;padding:14px 16px;background-color:{{ if eq .CommonLabels.severity "critical" }}#fff1f2{{ else if eq .CommonLabels.severity "warning" }}#fffbeb{{ else }}#f8fafc{{ end }};border:1px solid {{ if eq .CommonLabels.severity "critical" }}#fecdd3{{ else if eq .CommonLabels.severity "warning" }}#fef3c7{{ else }}#e2e8f0{{ end }};border-radius:10px;text-align:left;">
                    <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:{{ if eq .CommonLabels.severity "critical" }}#be123c{{ else if eq .CommonLabels.severity "warning" }}#b45309{{ else }}#475569{{ end }};letter-spacing:0.05em;margin-bottom:4px;">Severity</div>
                    <div style="font-size:13px;font-weight:800;color:{{ if eq .CommonLabels.severity "critical" }}#e11d48{{ else if eq .CommonLabels.severity "warning" }}#d97706{{ else }}#0f172a{{ end }};">{{ .CommonLabels.severity }}</div>
                  </td>
                  <td style="width:2%;"></td>
                  <td style="width:32%;padding:14px 16px;background-color:#f5f3ff;border:1px solid #ede9fe;border-radius:10px;text-align:left;">
                    <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:#6d28d9;letter-spacing:0.05em;margin-bottom:4px;">Targets Impacted</div>
                    <div style="font-size:14px;font-weight:800;color:#5b21b6;">{{ len .Alerts }} {{ .Status }} incident(s)</div>
                  </td>
                  <td style="width:2%;"></td>
                  <td style="width:32%;padding:14px 16px;background-color:#eff6ff;border:1px solid #dbeafe;border-radius:10px;text-align:left;">
                    <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:#1d4ed8;letter-spacing:0.05em;margin-bottom:4px;">Receiver Group</div>
                    <div style="font-size:14px;font-weight:800;color:#1e40af;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;" title="{{ .Receiver }}">{{ .Receiver }}</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 36px;background-color:#f8fafc;border-top:1px solid #f1f5f9;">
              <div style="font-size:11px;font-weight:800;text-transform:uppercase;color:#475569;letter-spacing:0.08em;margin-bottom:18px;text-align:left;">Active Incidents In Group</div>
              {{ range .Alerts }}
              <table role="presentation" cellspacing="0" cellpadding="0" style="width:100%;background-color:#ffffff;border-radius:8px;margin-bottom:16px;border-collapse:collapse;">
                <tr>
                  <td style="padding:24px 28px;text-align:left;">
                    <h2 style="font-size:18px;font-weight:800;color:#0f172a;margin:0 0 14px 0;line-height:1.2;text-align:left;">{{ .Labels.alertname }}</h2>
                    <div style="font-size:12px;color:#64748b;margin-bottom:20px;font-family:Consolas,Monaco,monospace;text-align:left;">
                      Host:
                      <a href="{{ .GeneratorURL }}" style="color:#2563eb;font-weight:700;text-decoration:underline;">{{ .Labels.instance }}</a>
                      <span style="margin-left:10px;">Triggered: {{ .StartsAt }}</span>
                    </div>
                    <div style="padding:14px 16px;background-color:#eff6ff;border:1px solid #dbeafe;border-radius:8px;margin-bottom:16px;text-align:left;">
                      <div style="font-size:10px;font-weight:800;text-transform:uppercase;color:#0369a1;letter-spacing:0.06em;margin-bottom:8px;">Incident Summary</div>
                      <div style="font-size:14px;color:#0369a1;line-height:1.5;">{{ .Annotations.summary }}</div>
                    </div>
                    <div style="padding:14px 16px;background-color:#fffbeb;border:1px solid #fef3c7;border-radius:8px;margin-bottom:20px;text-align:left;">
                      <div style="font-size:10px;font-weight:800;text-transform:uppercase;color:#b45309;letter-spacing:0.06em;margin-bottom:8px;">Diagnostic Description</div>
                      <div style="font-size:13px;color:#92400e;line-height:1.6;">{{ .Annotations.description }}</div>
                    </div>
                    <table role="presentation" cellspacing="0" cellpadding="0" style="margin-bottom:22px;">
                      <tr>
                        <td style="border-radius:8px;background-color:#111827;">
                          <a href="{{ .GeneratorURL }}" style="display:inline-block;padding:12px 18px;font-size:13px;font-weight:800;color:#ffffff;text-decoration:none;border-radius:8px;">Analyze in Prometheus -&gt;</a>
                        </td>
                      </tr>
                    </table>
                    <div style="font-size:11px;font-weight:800;text-transform:uppercase;color:#94a3b8;letter-spacing:0.06em;margin-bottom:10px;">Metadata Tags</div>
                    <div>
                      {{ range .Labels.SortedPairs }}
                      <span style="display:inline-block;font-family:Consolas,Monaco,monospace;font-size:11px;font-weight:700;color:#1d4ed8;background-color:#eff6ff;border:1px solid #bfdbfe;border-radius:5px;padding:5px 9px;margin:0 6px 8px 0;">{{ .Name }}={{ .Value }}</span>
                      {{ end }}
                    </div>
                  </td>
                </tr>
              </table>
              {{ end }}
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

## 4. Configure Routing

Use `group_by` to control how alerts are grouped into one email.

Common grouping:

```yaml
route:
  group_by:
    - alertname
    - instance
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 9999h
  receiver: email-alerts
```

Notes:

- `group_wait` gives related alerts time to arrive before sending the first notification.
- `group_interval` controls how often a changed group can notify again.
- `repeat_interval` controls reminder frequency for unchanged firing alerts.
- `send_resolved: true` sends recovery emails.

## 5. Configure SMTP Secret

If the chart supports `smtp_auth_password_file`, mount a secret containing the SMTP password.

Example secret key:

```text
smtp-password
```

Example mounted path:

```text
/etc/alertmanager/secrets/smtp-password
```

Do not commit the secret value to Git.

## 6. Apply The Helm Values

Update the Prometheus release with the edited values file.

Example:

```bash
helm upgrade prometheus prometheus-community/prometheus \
  --namespace prometheus \
  --values values.yml
```

Use the release name, chart, namespace, and values path from your deployment.

## 7. Validate Alertmanager Config

After applying changes, verify that Alertmanager is running and has loaded its config.

Useful checks:

```bash
kubectl -n prometheus get pods
kubectl -n prometheus logs deploy/prometheus-alertmanager
```

Object names may differ depending on the chart and release name.

## 8. Test An Alert

Create or temporarily modify a low-risk test rule.

Example:

```yaml
groups:
  - name: Test
    rules:
      - alert: AlertmanagerEmailTemplateTest
        expr: vector(1)
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: Test alert for HTML email template
          description: This alert verifies the custom Alertmanager HTML email template.
```

Remove the test rule after confirming that the email renders correctly.

## 9. Troubleshooting

If email is not sent:

- Check Alertmanager logs.
- Confirm SMTP host, username, sender, and password are correct.
- Confirm the receiver is selected by the route.
- Confirm the alert is firing in Prometheus.
- Confirm Alertmanager received the alert.
- Confirm the recipient address is allowed by the mail provider.

If the button does not open Prometheus:

- Confirm Prometheus external URL is configured correctly.
- Confirm `.GeneratorURL` is populated in Alertmanager.
- Confirm the Prometheus UI is reachable from the network where email is opened.

If labels or annotations are missing:

- Add the relevant labels or annotations to the alert rule.
- Use `.CommonLabels` for labels shared by all alerts in the group.
- Use `.Labels` inside `range .Alerts` for labels on each individual alert.

## 10. Notes

- The template uses Alertmanager Go templating.
- `{{ .Status }}` is usually `firing` or `resolved`.
- `{{ len .Alerts }}` gives the number of alerts in the notification group.
- `{{ .Receiver }}` shows the selected Alertmanager receiver.
- `{{ .GeneratorURL }}` links back to the Prometheus expression page for the alert.
- Keep real webhook URLs, SMTP passwords, internal domains, and private target addresses out of public documentation.
