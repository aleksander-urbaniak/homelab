# 🗂️ Semaphore (k3s)

> ✨ **What is Semaphore?**
>
> Semaphore is a web UI for running Ansible playbooks and managing inventories.

---

This folder contains a k3s-ready Kubernetes configuration for **Semaphore** (namespace: `semaphore`).

## 🎯 Quick facts

- Namespace: `semaphore`
- Images: `mysql:9`, `semaphoreui/semaphore:v2.16.51`
- Ports (from Services): `3306`, `3000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `semaphore-namespace.yml`: Namespace
- `semaphore-db-init-configmap.yml`: ConfigMap
- `semaphore-app-service.yml`: Service
- `semaphore-db-service.yml`: Service
- `semaphore-db-statefulset.yml`: StatefulSet
- `semaphore-statefulset.yml`: StatefulSet
- `semaphore-ingress.yml`: Ingress
- `semaphore-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `semaphore-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/semaphore/semaphore-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/semaphore/semaphore-namespace.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-init-configmap.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-app-service.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-service.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-db-statefulset.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-statefulset.yml
kubectl apply -f kubernetes/applications/semaphore/semaphore-ingress.yml
```
