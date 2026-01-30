# 🔔 Apprise (k3s)

> ✨ **What is Apprise?**
>
> Apprise is a notification gateway that sends messages to many services (email, chat, push, and more).

---

This folder contains a k3s-ready Kubernetes configuration for **Apprise** (namespace: `apprise`).

## 📌 Quick facts

- Namespace: `apprise`
- Images: `caronc/apprise:v1.3.1`
- Ports (from Services): `8000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧩 What gets deployed

- `apprise-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `apprise-deployment.yml`: Deployment
- `apprise-manifest-example.yml`: Example combined manifest (with placeholders)
- `apprise-manifest.yml`: Combined multi-document manifest
- `apprise-namespace.yml`: Namespace
- `apprise-service.yml`: Service

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `apprise-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/apprise/apprise-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/apprise/apprise-namespace.yml
kubectl apply -f kubernetes/applications/apprise/apprise-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/apprise/apprise-service.yml
kubectl apply -f kubernetes/applications/apprise/apprise-deployment.yml
```
