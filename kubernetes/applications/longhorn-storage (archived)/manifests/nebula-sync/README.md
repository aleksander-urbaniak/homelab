# ☸️ nebula-sync (k3s) ✨

> ✨ **What is nebula-sync?**
>
> nebula-sync synchronizes Pi-hole configuration between multiple Pi-hole instances.

---

This folder contains a k3s-ready Kubernetes configuration for **nebula-sync** (namespace: `nebula-sync`).

## 🎯 Quick facts

- Namespace: `nebula-sync`
- Image: `ghcr.io/lovelaze/nebula-sync:v0.11.1`
- Ports (from Services): `80`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `nebula-sync-namespace.yml`: Namespace
- `nebula-sync-secrets.yml`: Secret
- `nebula-sync-config-configmap.yml`: ConfigMap
- `nebula-sync-service.yml`: Service
- `nebula-sync-deployment.yml`: Deployment
- `nebula-sync-ingress.yml`: Ingress
- `nebula-sync-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `nebula-sync-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-namespace.yml
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-secrets.yml
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-config-configmap.yml
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-service.yml
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-deployment.yml
kubectl apply -f kubernetes/applications/manifests/nebula-sync/nebula-sync-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
