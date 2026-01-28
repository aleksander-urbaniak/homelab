# 🗂️ Karma (k3s)

> ✨ **What is Karma?**
>
> Karma is a web UI for browsing and triaging alerts from Prometheus Alertmanager.

---

This folder contains a k3s-ready Kubernetes configuration for **Karma** (namespace: `karma`).

## 🎯 Quick facts

- Namespace: `karma`
- Images: `busybox:1.37`, `ghcr.io/prymitive/karma:latest`
- Ports (from Services): `8080`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `karma-config-configmap.yml`: ConfigMap
- `karma-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `karma-deployment.yml`: Deployment
- `karma-manifest-example.yml`: Example combined manifest (with placeholders)
- `karma-manifest.yml`: Combined multi-document manifest
- `karma-namespace.yml`: Namespace
- `karma-service.yml`: Service

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `karma-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/karma/karma-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/karma/karma-namespace.yml
kubectl apply -f kubernetes/applications/karma/karma-config-configmap.yml
kubectl apply -f kubernetes/applications/karma/karma-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/karma/karma-service.yml
kubectl apply -f kubernetes/applications/karma/karma-deployment.yml
```
