# 🗂️ Pi-hole Exporter (k3s)

> ✨ **What is Pi-hole Exporter?**
>
> Pi-hole Exporter exposes Pi-hole metrics for Prometheus.

---

This folder contains a k3s-ready Kubernetes configuration for **Pi-hole Exporter** (namespace: `pihole-exporter`).

## 🎯 Quick facts

- Namespace: `pihole-exporter`
- Images: `ekofr/pihole-exporter:latest`
- Ports (from Services): `9617`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `pihole-exporter-certs-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `pihole-exporter-deployment.yml`: Deployment
- `pihole-exporter-manifest-example.yml`: Example combined manifest (with placeholders)
- `pihole-exporter-manifest.yml`: Combined multi-document manifest
- `pihole-exporter-namespace.yml`: Namespace
- `pihole-exporter-secrets.yml`: Secrets
- `pihole-exporter-service.yml`: Service
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `pihole-exporter-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-namespace.yml
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-secrets.yml
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-certs-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-service.yml
kubectl apply -f kubernetes/applications/pihole-exporter/pihole-exporter-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
