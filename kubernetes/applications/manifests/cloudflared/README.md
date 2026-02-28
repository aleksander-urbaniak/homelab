# 🗂️ cloudflared (k3s) ✨

> ✨ **What is cloudflared?**
>
> cloudflared runs a Cloudflare Tunnel to securely expose internal services without opening inbound ports.

---

This folder contains a k3s-ready Kubernetes configuration for **cloudflared** (namespace: `cloudflared`).

## 🎯 Quick facts

- Namespace: `cloudflared`
- Image: `cloudflare/cloudflared:2025.11.1`
- Ports (from Services): none
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `cloudflared-namespace.yml`: Namespace
- `cloudflared-secrets.yml`: Secret
- `cloudflared-deployment.yml`: Deployment
- `cloudflared-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `cloudflared-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/cloudflared/cloudflared-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/cloudflared/cloudflared-namespace.yml
kubectl apply -f kubernetes/applications/manifests/cloudflared/cloudflared-secrets.yml
kubectl apply -f kubernetes/applications/manifests/cloudflared/cloudflared-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
