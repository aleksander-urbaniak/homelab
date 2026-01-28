# 🗂️ Pulse (k3s)

> ✨ **What is Pulse?**
>
> Pulse is a real-time monitoring dashboard for Proxmox VE/PBS and related infrastructure.

---

This folder contains a k3s-ready Kubernetes configuration for **Pulse** (namespace: `pulse`).

## 🎯 Quick facts

- Namespace: `pulse`
- Images: `rcourtman/pulse:latest`
- Ports (from Services): `7655`
- StorageClass: `longhorn`

---

## 🧱 What gets deployed

- `pulse-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `pulse-deployment.yml`: Deployment
- `pulse-manifest.yml`: Combined multi-document manifest
- `pulse-namespace.yml`: Namespace
- `pulse-secrets.yml`: Secrets
- `pulse-service.yml`: Service
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/pulse/pulse-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pulse/pulse-namespace.yml
kubectl apply -f kubernetes/applications/pulse/pulse-secrets.yml
kubectl apply -f kubernetes/applications/pulse/pulse-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/pulse/pulse-service.yml
kubectl apply -f kubernetes/applications/pulse/pulse-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
