# 🗂️ Flarewatcher (k3s) ✨

> ✨ **What is Flarewatcher?**
>
> Flarewatcher is a self-hosted dashboard/API for monitoring Cloudflare DNS records and related metadata.

---

This folder contains a k3s-ready Kubernetes configuration for **Flarewatcher** (namespace: `flarewatcher`).

## 🎯 Quick facts

- Namespace: `flarewatcher`
- Image: `aleksanderurbaniak/flarewatcher:v1.0.0`
- Ports (from Services): `3000`
- StorageClass: `longhorn`

---

## 🧱 What gets deployed

- `flarewatcher-namespace.yml`: Namespace
- `flarewatcher-secrets.yml`: Secret
- `flarewatcher-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `flarewatcher-service.yml`: Service
- `flarewatcher-deployment.yml`: Deployment
- `flarewatcher-ingress.yml`: Ingress
- `flarewatcher-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `flarewatcher-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-namespace.yml
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-secrets.yml
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-service.yml
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-deployment.yml
kubectl apply -f kubernetes/applications/flarewatcher/flarewatcher-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
