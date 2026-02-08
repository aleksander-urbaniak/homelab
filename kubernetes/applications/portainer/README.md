# 🗂️ Portainer (k3s) ✨

> ✨ **What is Portainer?**
>
> Portainer provides a web UI to manage container environments (Docker and Kubernetes).

---

This folder contains a k3s-ready Kubernetes configuration for **Portainer** (namespace: `portainer`).

## 🎯 Quick facts

- Namespace: `portainer`
- Image: `portainer/portainer-ce:2.36.0`
- Ports (from Services): `8000`, `9443`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `portainer-namespace.yml`: Namespace
- `portainer-data-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `portainer-service.yml`: Service
- `portainer-deployment.yml`: Deployment
- `portainer-ingress.yml`: Ingress
- `portainer-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `portainer-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/portainer/portainer-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/portainer/portainer-namespace.yml
kubectl apply -f kubernetes/applications/portainer/portainer-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/portainer/portainer-service.yml
kubectl apply -f kubernetes/applications/portainer/portainer-deployment.yml
kubectl apply -f kubernetes/applications/portainer/portainer-ingress.yml
```
