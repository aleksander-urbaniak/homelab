# 🗂️ Homepage (k3s) ✨

> ✨ **What is Homepage?**
>
> Homepage is a self-hosted dashboard for links, widgets, and status panels.

---

This folder contains a k3s-ready Kubernetes configuration for **Homepage** (namespace: `homepage`).

## 🎯 Quick facts

- Namespace: `homepage`
- Image: `ghcr.io/gethomepage/homepage:v1.9.0`
- Ports (from Services): `3000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `homepage-namespace.yml`: Namespace
- `homepage-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `homepage-app-service.yml`: Service
- `homepage-deployment.yml`: Deployment
- `homepage-ingress.yml`: Ingress
- `homepage-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `homepage-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-namespace.yml
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-app-service.yml
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-deployment.yml
kubectl apply -f kubernetes/applications/manifests/homepage/homepage-ingress.yml
```
