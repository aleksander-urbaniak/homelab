# 🗂️ InfluxDB (k3s) ✨

> ✨ **What is InfluxDB?**
>
> InfluxDB is a time series database for metrics and events.

---

This folder contains a k3s-ready Kubernetes configuration for **InfluxDB** (namespace: `influxdb`).

## 🎯 Quick facts

- Namespace: `influxdb`
- Image: `influxdb:2.8.0`
- Ports (from Services): `8086`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `influxdb-namespace.yml`: Namespace
- `influxdb-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `influxdb-app-service.yml`: Service
- `influxdb-deployment.yml`: Deployment
- `influxdb-ingress.yml`: Ingress
- `influxdb-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `influxdb-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-namespace.yml
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-app-service.yml
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-deployment.yml
kubectl apply -f kubernetes/applications/manifests/influxdb/influxdb-ingress.yml
```
