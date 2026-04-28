# ☸️ Pulse (k3s) ✨

> ✨ **What is Pulse?**
>
> Pulse is a real-time monitoring dashboard for Proxmox VE/PBS and related infrastructure.

---

This folder contains a k3s-ready Kubernetes configuration for **Pulse** (namespace: `pulse`).

## 🎯 Quick facts

- Namespace: `pulse`
- Image: `rcourtman/pulse:5.0.17`
- Ports (from Services): `7655`
- StorageClass: `longhorn`

---

## 🧱 What gets deployed

- `pulse-namespace.yml`: Namespace
- `pulse-secrets.yml`: Secret
- `pulse-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `pulse-service.yml`: Service
- `pulse-deployment.yml`: Deployment
- `pulse-ingress.yml`: Ingress
- `pulse-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-namespace.yml
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-secrets.yml
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-service.yml
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-deployment.yml
kubectl apply -f kubernetes/applications/manifests/pulse/pulse-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
