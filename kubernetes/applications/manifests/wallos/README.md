# 🗂️ Wallos (k3s) ✨

> ✨ **What is Wallos?**
>
> Wallos is a self-hosted personal subscription tracker with spending/renewal insights.

---

This folder contains a k3s-ready Kubernetes configuration for **Wallos** (namespace: `wallos`).

## 🎯 Quick facts

- Namespace: `wallos`
- Images: `busybox:1.37`, `bellamy/wallos:4.6.0`
- Ports (from Services): `80`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `wallos-namespace.yml`: Namespace
- `wallos-db-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `wallos-logos-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `wallos-app-service.yml`: Service
- `wallos-deployment.yml`: Deployment
- `wallos-ingress.yml`: Ingress
- `wallos-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-namespace.yml
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-db-pvc-pvc.yml
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-logos-pvc-pvc.yml
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-app-service.yml
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-deployment.yml
kubectl apply -f kubernetes/applications/manifests/wallos/wallos-ingress.yml
```
