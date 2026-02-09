# 🗂️ Pulze Dashboard (k3s) ✨

> ✨ **What is Pulze Dashboard?**
>
> Pulze Dashboard is a self-hosted dashboard application for displaying and organizing homelab information.

---

This folder contains a k3s-ready Kubernetes configuration for **Pulze Dashboard** (namespace: `pulze-dashboard`).

## 🎯 Quick facts

- Namespace: `pulze-dashboard`
- Image: `aleksanderurbaniak/pulze-dashboard:v1.0.0`
- Ports (from Services): `3000`
- StorageClass: `longhorn`

---

## 🧱 What gets deployed

- `pulze-dashboard-namespace.yml`: Namespace
- `pulze-dashboard-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `pulze-dashboard-service.yml`: Service
- `pulze-dashboard-deployment.yml`: Deployment
- `pulze-dashboard-ingress.yml`: Ingress
- `pulze-dashboard-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `pulze-dashboard-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-namespace.yml
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-service.yml
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-deployment.yml
kubectl apply -f kubernetes/applications/pulze-dashboard/pulze-dashboard-ingress.yml
```
