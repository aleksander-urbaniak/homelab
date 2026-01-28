# 🗂️ Semaphore (k3s)

> ✨ **What is Semaphore?**
>
> Semaphore is a web UI for running Ansible playbooks and managing inventories.

---

This folder contains a k3s-ready Kubernetes configuration for **Semaphore** (namespace: `semaphore`).

## 🎯 Quick facts

- Namespace: `semaphore`
- Images: `mysql:9`, `semaphoreui/semaphore:v2.16.50`
- Ports (from Services): `3000`, `3306`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `semaphore-app-service.yml`: Service
- `semaphore-db-init-configmap.yml`: ConfigMap
- `semaphore-db-service.yml`: Service
- `semaphore-db-statefulset.yml`: StatefulSet
- `semaphore-manifest-example.yml`: Example combined manifest (with placeholders)
- `semaphore-manifest.yml`: Combined multi-document manifest
- `semaphore-namespace.yml`: Namespace
- `semaphore-statefulset.yml`: StatefulSet

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `semaphore-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/semaphore/semaphore-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/semaphore/semaphore-namespace.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-init-configmap.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-app-service.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-service.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-statefulset.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-statefulset.yml
```
