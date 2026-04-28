# ☸️ Vaultwarden (k3s) ✨

> ✨ **What is Vaultwarden?**
>
> Vaultwarden is a lightweight, self-hosted Bitwarden-compatible password manager server.

---

This folder contains a k3s-ready Kubernetes configuration for **Vaultwarden** (namespace: `vaultwarden`).

## 🎯 Quick facts

- Namespace: `vaultwarden`
- Images: `postgres:18`, `vaultwarden/server:1.34.3`
- Ports (from Services): `5432`, `80`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `vaultwarden-namespace.yml`: Namespace
- `vaultwarden-secrets.yml`: Secret
- `vaultwarden-pvc.yml`: PersistentVolumeClaim (storage)
- `vaultwarden-db-headless-service.yml`: Service
- `vaultwarden-db-service.yml`: Service
- `vaultwarden-service.yml`: Service
- `vaultwarden-deployment.yml`: Deployment
- `vaultwarden-db-statefulset.yml`: StatefulSet
- `vaultwarden-ingress.yml`: Ingress
- `vaultwarden-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `vaultwarden-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-namespace.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-secrets.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-pvc.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-db-headless-service.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-db-service.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-service.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-deployment.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-db-statefulset.yml
kubectl apply -f kubernetes/applications/manifests/vaultwarden/vaultwarden-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
