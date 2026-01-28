# 🗂️ Homepage (k3s)

> ✨ **What is Homepage?**
>
> Homepage is a self-hosted dashboard for links, widgets, and status panels.

---

This folder contains a k3s-ready Kubernetes configuration for **Homepage** (namespace: `homepage`).

## 🎯 Quick facts

- Namespace: `homepage`
- Images: `ghcr.io/gethomepage/homepage:v1.8.0`
- Ports (from Services): `3000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `homepage-app-service.yml`: Service
- `homepage-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `homepage-deployment.yml`: Deployment
- `homepage-manifest-example.yml`: Example combined manifest (with placeholders)
- `homepage-manifest.yml`: Combined multi-document manifest
- `homepage-namespace.yml`: Namespace

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `homepage-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/homepage/homepage-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/homepage/homepage-namespace.yml
kubectl apply -f kubernetes/applications/homepage/homepage-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/homepage/homepage-app-service.yml
kubectl apply -f kubernetes/applications/homepage/homepage-deployment.yml
```
