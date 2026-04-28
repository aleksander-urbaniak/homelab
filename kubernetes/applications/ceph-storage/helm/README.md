# ☸️ Helm-managed Apps ✨

This folder holds the Helm release inventory that GitLab CI deploys alongside the hand-written Kubernetes workload manifests.

## Files

- `releases.txt`: release-to-chart mapping used by `.gitlab-ci.yml`
- `cert-manager/values.yml`
- `traefik/values.yml`
- `portainer/values.yml`
- `prometheus/values.yml`
- `prometheus/*.yml`: extra middleware manifests applied before the chart
- `rancher/values.yml`

## Manual usage

Use the same release metadata as `releases.txt`:

```bash
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace -f applications/helm/cert-manager/values.yml
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace -f applications/helm/traefik/values.yml
helm upgrade --install portainer portainer/portainer --namespace portainer --create-namespace -f applications/helm/portainer/values.yml
helm upgrade --install prometheus prometheus-community/prometheus --namespace prometheus --create-namespace -f applications/helm/prometheus/values.yml
helm upgrade --install rancher rancher-stable/rancher --namespace cattle-system --create-namespace -f applications/helm/rancher/values.yml
```

Alertmanager is configured through the Prometheus chart values file.
