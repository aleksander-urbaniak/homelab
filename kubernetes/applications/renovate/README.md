# 🗂️ Renovate (k3s)

> ✨ **What is Renovate?**
>
> Renovate automates dependency update PRs across your repositories.

---

This folder contains a k3s-ready Kubernetes configuration for **Renovate** (namespace: `renovate`).

## 🎯 Quick facts

- Namespace: `renovate`
- Image: `ghcr.io/mend/renovate-ce:13.4.0`
- Ports (from Services): `80`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `renovate-namespace.yml`: Namespace
- `renovate-secrets.yml`: Secret
- `renovate-db-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `renovate-logs-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `renovate-service.yml`: Service
- `renovate-deployment.yml`: Deployment
- `renovate-ingress.yml`: Ingress
- `renovate-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `renovate-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/renovate/renovate-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/renovate/renovate-namespace.yml
kubectl apply -f kubernetes/applications/renovate/renovate-secrets.yml
kubectl apply -f kubernetes/applications/renovate/renovate-db-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/renovate/renovate-logs-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/renovate/renovate-service.yml
kubectl apply -f kubernetes/applications/renovate/renovate-deployment.yml
kubectl apply -f kubernetes/applications/renovate/renovate-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
