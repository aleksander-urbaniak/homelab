# 🗂️ Nginx Proxy Manager (k3s)

> ✨ **What is Nginx Proxy Manager?**
>
> Nginx Proxy Manager provides a web UI for managing Nginx reverse-proxy hosts and certificates.

---

This folder contains a k3s-ready Kubernetes configuration for **Nginx Proxy Manager** (namespace: `nginx-proxy-manager`).

## 🎯 Quick facts

- Namespace: `nginx-proxy-manager`
- Images: `jc21/mariadb-aria:latest`, `jc21/nginx-proxy-manager:2.13.5`
- Ports (from Services): `80`, `81`, `389`, `443`, `636`, `3306`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `mariadb-headless-service.yml`: Service
- `mariadb-service.yml`: Service
- `mariadb-statefulset.yml`: StatefulSet
- `nginx-proxy-manager-deployment.yml`: Deployment
- `nginx-proxy-manager-manifest-example.yml`: Example combined manifest (with placeholders)
- `nginx-proxy-manager-manifest.yml`: Combined multi-document manifest
- `nginx-proxy-manager-namespace.yml`: Namespace
- `nginx-proxy-manager-secrets.yml`: Secrets
- `nginx-proxy-manager-service.yml`: Service
- `npm-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `npm-letsencrypt-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `nginx-proxy-manager-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-namespace.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-secrets.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/npm-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/npm-letsencrypt-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/mariadb-headless-service.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/mariadb-service.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-service.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/mariadb-statefulset.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
