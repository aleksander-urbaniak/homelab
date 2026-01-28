# 🗂️ Pi-hole (k3s)

> ✨ **What is Pi-hole?**
>
> Pi-hole is a network-wide ad blocker and DNS sinkhole.

---

This folder contains a k3s-ready Kubernetes configuration for **Pi-hole** (namespace: `pihole`).

## 🎯 Quick facts

- Namespace: `pihole`
- Images: `pihole/pihole:2025.05.2`
- Ports (from Services): `53`, `80`, `443`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `pihole-deployment.yml`: Deployment
- `pihole-etc-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `pihole-manifest.yml`: Combined multi-document manifest
- `pihole-namespace.yml`: Namespace
- `pihole-secrets.yml`: Secrets
- `pihole-service.yml`: Service
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/pihole/pihole-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pihole/pihole-namespace.yml
kubectl apply -f kubernetes/applications/pihole/pihole-secrets.yml
kubectl apply -f kubernetes/applications/pihole/pihole-etc-pvc-pvc.yml
kubectl apply -f kubernetes/applications/pihole/pihole-service.yml
kubectl apply -f kubernetes/applications/pihole/pihole-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
