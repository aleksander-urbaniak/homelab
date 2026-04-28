# ☸️ Rancher (Helm / k3s) ✨

This folder contains Helm-based Rancher configuration for k3s.

## Quick facts

- Namespace: `cattle-system`
- Install method: Helm chart `rancher-latest/rancher`
- Chart version: `2.13.3` (pinned via `--version`)
- Values file: `values.yml.example`
- Rancher will also install Fleet as part of the platform

## Files

- `README.md`: Deployment notes for Rancher
- `values.yml.example`: Redacted example Helm values, including a pinned chart version reference

## Chart version

This README pins a chart version so installs stay reproducible while still allowing Renovate to keep the version current.

```bash
# renovate: datasource=helm depName=rancher versioning=helm registryUrl=https://releases.rancher.com/server-charts/latest
export RANCHER_CHART_VERSION=2.14.0
```

## Configuration notes

- `bootstrapPassword` is redacted as `REPLACE_ME`. Use a strong, unique initial admin password.
- `hostname` is redacted as `rancher.example.com`. Replace it with the FQDN you will use for Rancher.
- `rancherChartVersion` in `values.yml.example` is a repo-side reference for the pinned chart version. Helm does not read it automatically from the values file; the install command still uses `--version`.
- Keep real secrets and environment-specific values out of git. Create a local `values.yml` before installing.
- Rancher expects a working ingress path and certificate management. In k3s setups that typically means your ingress controller and `cert-manager` are already available.

## Deploy

### 1. Set the chart version

Use the pinned chart version from this README:

```bash
export RANCHER_CHART_VERSION=2.13.3
```

### 2. Prepare your values file

Recommended flow:

1. Copy `values.yml.example` to a local `values.yml`.
2. Replace all placeholders.

```bash
cp kubernetes/applications/helm/rancher/values.yml.example kubernetes/applications/helm/rancher/values.yml
```

If you do not want to create a separate file, you can also use `values.yml.example` directly after editing it.

### 3. Install cert-manager

Per the official Rancher install docs, install `cert-manager` before Rancher unless you are bringing your own certificate files (`ingress.tls.source=secret`) or terminating TLS on an external load balancer.

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
```

Verify that `cert-manager` is running:

```bash
kubectl get pods --namespace cert-manager
```

### 4. Install or upgrade Rancher

Using a local `values.yml`:

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --values kubernetes/applications/helm/rancher/values.yml \
  --version="${RANCHER_CHART_VERSION}"
```

Using `values.yml.example` directly after editing it:

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --values kubernetes/applications/helm/rancher/values.yml.example \
  --version="${RANCHER_CHART_VERSION}"
```

Tip: the shortest direct command after creating `values.yml` is:

```bash
helm upgrade --install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --values kubernetes/applications/helm/rancher/values.yml \
  --version="${RANCHER_CHART_VERSION}"
```

### 5. Verify the initial rollout

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

## Update

### 1. Update your Helm repositories

Refresh your local Helm repository cache before checking or installing newer Rancher chart versions.

```bash
helm repo update
```

Check which Rancher versions are currently available:

```bash
helm search repo rancher-latest/rancher
```

Renovate can update `RANCHER_CHART_VERSION` automatically when a newer chart is published.

### 2. Save your current configuration

Export the values from the currently installed Rancher release before upgrading. This avoids accidentally overwriting settings such as hostname, replica counts, or TLS-related configuration.

```bash
helm get values rancher -n cattle-system -o yaml > current-rancher-values.yaml
```

Note: review `current-rancher-values.yaml` and confirm it contains your expected setup before continuing.

### 3. Perform the upgrade

Upgrade Rancher using the exported values file and the pinned chart version defined above.

```bash
helm upgrade rancher rancher-latest/rancher \
  --namespace cattle-system \
  -f current-rancher-values.yaml \
  --version="${RANCHER_CHART_VERSION}"
```

Tip: pin `--version` to a specific release instead of floating to whatever is latest in the repository.

### 4. Verify the rollout

Watch the Rancher deployment and confirm the new pods become ready:

```bash
kubectl -n cattle-system rollout status deploy/rancher
```
