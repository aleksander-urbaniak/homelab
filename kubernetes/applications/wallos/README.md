# 🗂️ Wallos (k3s)

> ✨ **What is Wallos?**
>
> Wallos is a self-hosted personal subscription tracker with spending/renewal insights.

---

This folder contains a k3s-ready Kubernetes configuration for **Wallos** (namespace: `wallos`).

## 🎯 Quick facts

- Namespace: `wallos`
- Images: `bellamy/wallos:v4.5.0`, `busybox:1.37`
- Ports (from Services): `80`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `wallos-app-service.yml`: Service
- `wallos-db-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `wallos-deployment.yml`: Deployment
- `wallos-logos-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `wallos-manifest.yml`: Combined multi-document manifest
- `wallos-namespace.yml`: Namespace

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/wallos/wallos-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/wallos/wallos-namespace.yml
kubectl apply -f kubernetes/applications/wallos/wallos-db-pvc-pvc.yml
kubectl apply -f kubernetes/applications/wallos/wallos-logos-pvc-pvc.yml
kubectl apply -f kubernetes/applications/wallos/wallos-app-service.yml
kubectl apply -f kubernetes/applications/wallos/wallos-deployment.yml
```
