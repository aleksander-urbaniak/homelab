# 🗂️ Affine (k3s) ✨

> ✨ **What is Affine?**
>
> **Affine** is a self-hostable collaborative workspace for **notes, documents, and whiteboards** - use it to build a personal/team knowledge base, plan projects, and keep everything in one place.

---

This folder contains a self-hosted **Affine** deployment for a **k3s** Kubernetes cluster. The manifests run Affine plus its required dependencies (**PostgreSQL** + **Redis**) and **persistent storage**.

## 🎯 What you get out of it

- **Team-ready** writing + knowledge base
- **Visual thinking** with whiteboards/canvases
- **Self-hosting** so data stays in your cluster

---

## What gets deployed

- `affine-namespace.yml`: Namespace
- `affine-secrets.yml`: Secret
- `affine-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `affine-storage-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `affine-postgres-service.yml`: Service
- `affine-redis-service.yml`: Service
- `affine-service.yml`: Service
- `affine-deployment.yml`: Deployment
- `affine-redis-deployment.yml`: Deployment
- `affine-postgres-statefulset.yml`: StatefulSet
- `affine-migration-job.yml`: Job
- `affine-ingress.yml`: Ingress
- `affine-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs default to `storageClassName: longhorn`. If you don't use Longhorn, change the storage class (or remove `storageClassName` to use the cluster default).
- **Node placement**: Workloads use `nodeSelector: node-role.kubernetes.io/worker: ""`. Remove or adjust if your nodes don't have that label.
- **External access**: The included Service is `ClusterIP`. Expose it via your preferred Ingress / Gateway / reverse proxy to `affine:3010` and set `AFFINE_SERVER_EXTERNAL_URL` accordingly.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

### Option A: apply the combined manifest

1. Edit `affine-manifest.yml` and replace all `REPLACE_ME` values.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/affine/affine-manifest.yml
```

Note: the combined manifest includes both the migration Job and the Affine Deployment; for first-time installs, prefer Option B so you can run the migration Job before starting the app.

### Option B: apply the split manifests

1. Create secrets (copy `secrets-example.yml` and replace placeholders), then apply resources:

```bash
kubectl apply -f kubernetes/applications/affine/affine-namespace.yml
kubectl apply -f kubernetes/applications/affine/affine-secrets.yml
kubectl apply -f kubernetes/applications/affine/affine-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/affine/affine-storage-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/affine/affine-postgres-service.yml
kubectl apply -f kubernetes/applications/affine/affine-redis-service.yml
kubectl apply -f kubernetes/applications/affine/affine-service.yml
kubectl apply -f kubernetes/applications/affine/affine-deployment.yml
kubectl apply -f kubernetes/applications/affine/affine-redis-deployment.yml
kubectl apply -f kubernetes/applications/affine/affine-postgres-statefulset.yml
kubectl apply -f kubernetes/applications/affine/affine-migration-job.yml
kubectl apply -f kubernetes/applications/affine/affine-ingress.yml
```
