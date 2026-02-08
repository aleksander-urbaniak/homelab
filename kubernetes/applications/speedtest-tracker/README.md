# 🗂️ Speedtest Tracker (k3s) ✨

> ✨ **What is Speedtest Tracker?**
>
> Speedtest Tracker runs scheduled speed tests and stores results for history and graphs.

---

This folder contains a k3s-ready Kubernetes configuration for **Speedtest Tracker** (namespace: `speedtest-tracker`).

## 🎯 Quick facts

- Namespace: `speedtest-tracker`
- Images: `postgres:18`, `busybox:1.37`, `lscr.io/linuxserver/speedtest-tracker:1.13.5`
- Ports (from Services): `5432`, `443`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `speedtest-tracker-namespace.yml`: Namespace
- `speedtest-tracker-secrets.yml`: Secret
- `speedtest-tracker-config-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `speedtest-tracker-web-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `speedtest-tracker-app-service.yml`: Service
- `speedtest-tracker-db-headless-service.yml`: Service
- `speedtest-tracker-db-service.yml`: Service
- `speedtest-tracker-deployment.yml`: Deployment
- `speedtest-tracker-db-statefulset.yml`: StatefulSet
- `speedtest-tracker-ingress.yml`: Ingress
- `speedtest-tracker-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `speedtest-tracker-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-namespace.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-secrets.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-config-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-web-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-app-service.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-db-headless-service.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-db-service.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-deployment.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-db-statefulset.yml
kubectl apply -f kubernetes/applications/speedtest-tracker/speedtest-tracker-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
