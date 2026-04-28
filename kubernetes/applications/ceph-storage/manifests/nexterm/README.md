# ☸️ Nexterm (k3s) ✨

Nexterm is a self-hosted web terminal and remote access UI.

This folder contains a k3s-ready Kubernetes configuration for Nexterm (namespace: `nexterm`).

## Quick facts

- Namespace: `nexterm`
- Image: `germannewsmaker/nexterm:1.2.0-BETA`
- Ports (from Services): `6989`
- StorageClass: `example-rbd-rbd`

## What gets deployed

- `nexterm-namespace.yml`: Namespace
- `nexterm-secrets.yml`: Secret
- `nexterm-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `nexterm-service.yml`: Service
- `nexterm-deployment.yml`: Deployment
- `nexterm-ingress.yml`: Ingress

## Configuration notes (k3s)

- Storage: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- External access: service is `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- Security: set `NEXTERM_ENCRYPTION_KEY` in `nexterm-secrets.yml` (or copy from `secrets-example.yml`).
- Images: the split manifest files in this folder are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy

Apply the split manifests in order:

```bash
kubectl apply -f kubernetes/deployments/nexterm/nexterm-namespace.yml
kubectl apply -f kubernetes/deployments/nexterm/nexterm-secrets.yml
kubectl apply -f kubernetes/deployments/nexterm/nexterm-data-pvc-pvc.yml
kubectl apply -f kubernetes/deployments/nexterm/nexterm-service.yml
kubectl apply -f kubernetes/deployments/nexterm/nexterm-deployment.yml
kubectl apply -f kubernetes/deployments/nexterm/nexterm-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` before applying.
