# 🗂️ Alertmanager (k3s) ✨

> ✨ **What is Alertmanager?**
>
> Prometheus Alertmanager routes, groups, and delivers alerts from Prometheus and other clients.

---

This folder contains a k3s-ready Kubernetes configuration for **Alertmanager** (namespace: `alertmanager`).

## 🎯 Quick facts

- Namespace: `alertmanager`
- Images: `busybox:1.37`, `prom/alertmanager:v0.30.1`
- Ports (from Services): `9093`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `alertmanager-namespace.yml`: Namespace
- `alertmanager-config-configmap.yml`: ConfigMap
- `alertmanager-config-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `alertmanager-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `alertmanager-service.yml`: Service
- `alertmanager-deployment.yml`: Deployment
- `alertmanager-ingress.yml`: Ingress
- `alertmanager-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `alertmanager-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-namespace.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-config-configmap.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-config-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-service.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-deployment.yml
kubectl apply -f kubernetes/applications/alertmanager/alertmanager-ingress.yml
```
