# 🗂️ n8n (k3s)

> ✨ **What is n8n?**
>
> n8n is a workflow automation platform to connect apps and automate tasks.

---

This folder contains a k3s-ready Kubernetes configuration for **n8n** (namespace: `n8n`).

## 🎯 Quick facts

- Namespace: `n8n`
- Images: `busybox:1.37`, `n8nio/n8n:2.3.2`, `postgres:18`
- Ports (from Services): `5432`, `5678`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `n8n-app-service.yml`: Service
- `n8n-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `n8n-deployment.yml`: Deployment
- `n8n-manifest-example.yml`: Example combined manifest (with placeholders)
- `n8n-manifest.yml`: Combined multi-document manifest
- `n8n-namespace.yml`: Namespace
- `n8n-postgres-db-service.yml`: Service
- `postgres-statefulset-statefulset.yml`: StatefulSet

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `n8n-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/n8n/n8n-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/n8n/n8n-namespace.yml
kubectl apply -f kubernetes/applications/n8n/n8n-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/n8n/n8n-app-service.yml
kubectl apply -f kubernetes/applications/n8n/n8n-postgres-db-service.yml
kubectl apply -f kubernetes/applications/n8n/postgres-statefulset-statefulset.yml
kubectl apply -f kubernetes/applications/n8n/n8n-deployment.yml
```
