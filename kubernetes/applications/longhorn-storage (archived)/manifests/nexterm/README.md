# ☸️ Nexterm (k3s) ✨

Nexterm is a self-hosted web terminal and remote access UI.

This folder contains a k3s-ready Kubernetes configuration for Nexterm (namespace: `nexterm`).

## Quick facts

- Namespace: `nexterm`
- Image: `germannewsmaker/nexterm:1.2.0-BETA`
- Ports (from Services): `6989`
- StorageClass: `longhorn`

## What gets deployed

- `nexterm-namespace.yml`: Namespace
- `nexterm-secrets.yml`: Secret
- `nexterm-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `nexterm-service.yml`: Service
- `nexterm-deployment.yml`: Deployment
- `nexterm-ingress.yml`: Ingress
- `nexterm-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- Storage: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- External access: service is `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- Security: set `NEXTERM_ENCRYPTION_KEY` in `nexterm-secrets.yml` (or copy from `secrets-example.yml`).
- Images: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy

This folder includes both combined manifests (`*-manifest*.yml`) and split manifests (the other files).

### Option A: apply the combined manifest

1. Edit `nexterm-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-namespace.yml
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-secrets.yml
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-service.yml
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-deployment.yml
kubectl apply -f kubernetes/applications/manifests/nexterm/nexterm-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` before applying.
