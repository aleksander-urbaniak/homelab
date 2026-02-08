# 🗂️ Nginx Proxy Manager (k3s) ✨

> ✨ **What is Nginx Proxy Manager?**
>
> Nginx Proxy Manager provides a web UI for managing Nginx reverse-proxy hosts and certificates.

---

This folder contains a k3s-ready Kubernetes configuration for **Nginx Proxy Manager** (namespace: `nginx-proxy-manager`).

## 🎯 Quick facts

- Namespace: `nginx-proxy-manager`
- Images: `jc21/mariadb-aria:10.11.5`, `jc21/nginx-proxy-manager:2.13.6`
- Ports (from Services): `3306`, `80`, `81`, `443`, `389`, `636`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `nginx-proxy-manager-namespace.yml`: Namespace
- `nginx-proxy-manager-secrets.yml`: Secret
- `npm-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `npm-letsencrypt-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `mariadb-headless-service.yml`: Service
- `mariadb-service.yml`: Service
- `nginx-proxy-manager-service.yml`: Service
- `nginx-proxy-manager-deployment.yml`: Deployment
- `mariadb-statefulset.yml`: StatefulSet
- `nginx-proxy-manager-ingress.yml`: Ingress
- `nginx-proxy-manager-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `nginx-proxy-manager-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-manifest.yml
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
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-deployment.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/mariadb-statefulset.yml
kubectl apply -f kubernetes/applications/nginx-proxy-manager/nginx-proxy-manager-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
