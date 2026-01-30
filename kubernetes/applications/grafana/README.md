# 🗂️ Grafana (k3s)

> ✨ **What is Grafana?**
>
> Grafana provides dashboards and visualization for metrics, logs, and traces.

---

This folder contains a k3s-ready Kubernetes configuration for **Grafana** (namespace: `grafana`).

## 🎯 Quick facts

- Namespace: `grafana`
- Images: `busybox:1.37`, `grafana/grafana:12.3.2`
- Ports (from Services): `3000`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `grafana-namespace.yml`: Namespace
- `grafana-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `grafana-app-service.yml`: Service
- `grafana-deployment.yml`: Deployment
- `grafana-ingress.yml`: Ingress
- `grafana-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `grafana-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/grafana/grafana-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/grafana/grafana-namespace.yml
kubectl apply -f kubernetes/applications/grafana/grafana-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/grafana/grafana-app-service.yml
kubectl apply -f kubernetes/applications/grafana/grafana-deployment.yml
kubectl apply -f kubernetes/applications/grafana/grafana-ingress.yml
```
