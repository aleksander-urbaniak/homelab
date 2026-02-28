# 🗂️ Karma (k3s) ✨

> ✨ **What is Karma?**
>
> Karma is a web UI for browsing and triaging alerts from Prometheus Alertmanager.

---

This folder contains a k3s-ready Kubernetes configuration for **Karma** (namespace: `karma`).

## 🎯 Quick facts

- Namespace: `karma`
- Images: `busybox:1.37`, `ghcr.io/prymitive/karma:v0.122`
- Ports (from Services): `8080`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `karma-namespace.yml`: Namespace
- `karma-config-configmap.yml`: ConfigMap
- `karma-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `karma-service.yml`: Service
- `karma-deployment.yml`: Deployment
- `karma-ingress.yml`: Ingress
- `karma-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `karma-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/karma/karma-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/karma/karma-namespace.yml
kubectl apply -f kubernetes/applications/manifests/karma/karma-config-configmap.yml
kubectl apply -f kubernetes/applications/manifests/karma/karma-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/karma/karma-service.yml
kubectl apply -f kubernetes/applications/manifests/karma/karma-deployment.yml
kubectl apply -f kubernetes/applications/manifests/karma/karma-ingress.yml
```
