# 🔔 Apprise (k3s) ✨

> ✨ **What is Apprise?**
>
> Apprise is a notification gateway that sends messages to many services (email, chat, push, and more).

---

This folder contains a k3s-ready Kubernetes configuration for **Apprise** (namespace: `apprise`).

## 📌 Quick facts

- Namespace: `apprise`
- Image: `caronc/apprise:v1.3.1`
- Ports (from Services): `8000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧩 What gets deployed

- `apprise-namespace.yml`: Namespace
- `apprise-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `apprise-service.yml`: Service
- `apprise-deployment.yml`: Deployment
- `apprise-ingress.yml`: Ingress
- `apprise-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `apprise-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-namespace.yml
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-service.yml
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-deployment.yml
kubectl apply -f kubernetes/applications/manifests/apprise/apprise-ingress.yml
```
