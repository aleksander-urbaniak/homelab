# ☸️ Prometheus (k3s) ✨

> ✨ **What is Prometheus?**
>
> Prometheus is a monitoring system and time series database.

---

This folder contains a k3s-ready Kubernetes configuration for **Prometheus** (namespace: `prometheus`).

## 🎯 Quick facts

- Namespace: `prometheus`
- Images: `busybox:1.37`, `prom/prometheus:v3.9.1`
- Ports (from Services): `9090`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `prometheus-namespace.yml`: Namespace
- `prometheus-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `prometheus-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `prometheus-serviceaccount.yml`: ServiceAccount
- `prometheus-clusterrole.yml`: ClusterRole
- `prometheus-clusterrolebinding.yml`: Combined multi-document manifest
- `prometheus-service.yml`: Service
- `prometheus-deployment.yml`: Deployment
- `prometheus-ingress.yml`: Ingress
- `prometheus-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `prometheus-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-namespace.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-serviceaccount.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-clusterrole.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-clusterrolebinding.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-service.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-deployment.yml
kubectl apply -f kubernetes/applications/manifests/prometheus/prometheus-ingress.yml
```
