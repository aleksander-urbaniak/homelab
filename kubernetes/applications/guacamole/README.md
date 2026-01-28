# 🗂️ Guacamole (k3s)

> ✨ **What is Guacamole?**
>
> Apache Guacamole provides browser-based remote access (RDP/SSH/VNC) without needing a native client.

---

This folder contains a k3s-ready Kubernetes configuration for **Guacamole** (namespace: `guacamole`).

## 🎯 Quick facts

- Namespace: `guacamole`
- Images: `abesnier/guacamole:1.6.0`
- Ports (from Services): `8080`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `guacamole-app-service.yml`: Service
- `guacamole-headless-service.yml`: Service
- `guacamole-manifest-example.yml`: Example combined manifest (with placeholders)
- `guacamole-manifest.yml`: Combined multi-document manifest
- `guacamole-namespace.yml`: Namespace
- `guacamole-statefulset.yml`: StatefulSet

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `guacamole-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/guacamole/guacamole-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/guacamole/guacamole-namespace.yml
kubectl apply -f kubernetes/applications/guacamole/guacamole-app-service.yml
kubectl apply -f kubernetes/applications/guacamole/guacamole-headless-service.yml
kubectl apply -f kubernetes/applications/guacamole/guacamole-statefulset.yml
```
