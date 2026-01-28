# 🗂️ Vaultwarden (k3s)

> ✨ **What is Vaultwarden?**
>
> Vaultwarden is a lightweight, self-hosted Bitwarden-compatible password manager server.

---

This folder contains a k3s-ready Kubernetes configuration for **Vaultwarden** (namespace: `vaultwarden`).

## 🎯 Quick facts

- Namespace: `vaultwarden`
- Images: `postgres:18`, `vaultwarden/server:1.34.3`
- Ports (from Services): `80`, `5432`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `secrets-example.yml`: Example secrets (placeholders)
- `vaultwarden-db-headless-service.yml`: Service
- `vaultwarden-db-service.yml`: Service
- `vaultwarden-db-statefulset.yml`: StatefulSet
- `vaultwarden-deployment.yml`: Deployment
- `vaultwarden-manifest-example.yml`: Example combined manifest (with placeholders)
- `vaultwarden-manifest.yml`: Combined multi-document manifest
- `vaultwarden-namespace.yml`: Namespace
- `vaultwarden-pvc.yml`: PersistentVolumeClaim (storage)
- `vaultwarden-secrets.yml`: Secrets
- `vaultwarden-service.yml`: Service

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `vaultwarden-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-namespace.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-secrets.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-pvc.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-db-headless-service.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-db-service.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-service.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-db-statefulset.yml
kubectl apply -f kubernetes/applications/vaultwarden/vaultwarden-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
