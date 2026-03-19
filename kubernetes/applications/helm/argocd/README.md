# Argo CD (Helm / k3s)

This folder contains Helm-based Argo CD configuration for k3s.

## Quick facts

- Namespace: `argocd`
- Install method: Helm chart `argo/argo-cd`
- Chart version: `9.4.7` (pinned via `--version`)
- Values file: `values.yml.example`

## Files

- `README.md`: Deployment notes for Argo CD
- `values.yml.example`: Redacted example Helm values, including a pinned chart version reference

## Chart version

This README pins a chart version so installs stay reproducible while still allowing Renovate to keep the version current.

```bash
# renovate: datasource=helm depName=argo-cd versioning=helm registryUrl=https://argoproj.github.io/argo-helm
export ARGOCD_CHART_VERSION=9.4.15
```

## Configuration notes

- `global.domain` and `server.ingress.hostname` are redacted as `argocd.example.com`. Replace them with your FQDN.
- `configs.secret.argocdServerAdminPassword` is redacted as `REPLACE_ME_BCRYPT_HASH` and must be a bcrypt hash.
- `configs.secret.argocdServerAdminPasswordMtime` should be updated whenever you rotate the admin password hash.
- `argoCdChartVersion` in `values.yml.example` is a repo-side reference for the pinned chart version. Helm does not read it automatically from the values file; the install command still uses `--version`.
- Keep real secrets and environment-specific values out of git. Create a local `values.yml` before installing.

Generate a bcrypt hash for the admin password:

```bash
argocd account bcrypt --password 'REPLACE_ME'
```

## Deploy

### 1. Set the chart version

Use the pinned chart version from this README:

```bash
export ARGOCD_CHART_VERSION=9.4.7
```

### 2. Prepare your values file

Recommended flow:

1. Copy `values.yml.example` to a local `values.yml`.
2. Replace all placeholders.

```bash
cp kubernetes/applications/helm/argocd/values.yml.example kubernetes/applications/helm/argocd/values.yml
```

If you do not want to create a separate file, you can also use `values.yml.example` directly after editing it.

### 3. Install or upgrade Argo CD

Using a local `values.yml`:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --values kubernetes/applications/helm/argocd/values.yml \
  --version="${ARGOCD_CHART_VERSION}"
```

Using `values.yml.example` directly after editing it:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --values kubernetes/applications/helm/argocd/values.yml.example \
  --version="${ARGOCD_CHART_VERSION}"
```

### 4. Verify the rollout

```bash
kubectl -n argocd rollout status deploy/argocd-server
```

## Update

### 1. Update your Helm repositories

Refresh your local Helm repository cache before checking or installing newer Argo CD chart versions.

```bash
helm repo update
```

Check which Argo CD versions are currently available:

```bash
helm search repo argo/argo-cd
```

Renovate can update `ARGOCD_CHART_VERSION` automatically when a newer chart is published.

### 2. Save your current configuration

Export the values from the currently installed Argo CD release before upgrading.

```bash
helm get values argocd -n argocd -o yaml > current-argocd-values.yaml
```

### 3. Perform the upgrade

Upgrade Argo CD using the exported values file and the pinned chart version defined above.

```bash
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  -f current-argocd-values.yaml \
  --version="${ARGOCD_CHART_VERSION}"
```

### 4. Verify the rollout

```bash
kubectl -n argocd rollout status deploy/argocd-server
```
