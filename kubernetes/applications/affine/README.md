# 🗂️ Affine (k3s)

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

- `affine-namespace.yml`: Namespace `affine`
- `affine-secrets.yml` / `secrets-example.yml`: App + database + Redis secrets (edit before applying)
- `affine-config-pvc-persistentvolumeclaim.yml`: PVC for `/root/.affine/config` (default: `512Mi`)
- `affine-storage-pvc-persistentvolumeclaim.yml`: PVC for `/root/.affine/storage` (default: `5Gi`)
- `affine-postgres-statefulset.yml` + `affine-postgres-service.yml`: PostgreSQL (pgvector image) + Service
- `affine-redis-deployment.yml` + `affine-redis-service.yml`: Redis (password protected) + Service
- `affine-migration-job.yml`: Pre-deploy migration job (`node ./scripts/self-host-predeploy.js`)
- `affine-deployment.yml` + `affine-service.yml`: Affine Deployment + ClusterIP Service (port `3010`)

There is also an "all-in-one" manifest:

- `affine-manifest.yml`: Combined multi-document YAML for the resources above
- `affine-manifest-example.yml`: Same as above but with `REPLACE_ME` placeholders for secrets

## Configuration notes (k3s)

- **Storage**: PVCs default to `storageClassName: longhorn`. If you don't use Longhorn, change the storage class (or remove `storageClassName` to use the cluster default).
- **Node placement**: Workloads use `nodeSelector: node-role.kubernetes.io/worker: ""`. Remove or adjust if your nodes don't have that label.
- **External access**: The included Service is `ClusterIP`. Expose it via your preferred Ingress / Gateway / reverse proxy to `affine:3010` and set `AFFINE_SERVER_EXTERNAL_URL` accordingly.

## Deploy 🚀

### Option A: apply the combined manifest

1. Edit `affine-manifest-example.yml` and replace all `REPLACE_ME` values.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/affine/affine-manifest-example.yml
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
kubectl apply -f kubernetes/applications/affine/affine-postgres-statefulset.yml
kubectl apply -f kubernetes/applications/affine/affine-redis-service.yml
kubectl apply -f kubernetes/applications/affine/affine-redis-deployment.yml
kubectl apply -f kubernetes/applications/affine/affine-migration-job.yml
kubectl -n affine wait --for=condition=complete job/affine-migration --timeout=10m
kubectl apply -f kubernetes/applications/affine/affine-service.yml
kubectl apply -f kubernetes/applications/affine/affine-deployment.yml
```
