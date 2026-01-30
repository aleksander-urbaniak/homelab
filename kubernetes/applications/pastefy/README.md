# 🗂️ Pastefy (k3s)

> ✨ **What is Pastefy?**
>
> Pastefy is a self-hostable pastebin for sharing snippets and files.

---

This folder contains a k3s-ready Kubernetes configuration for **Pastefy** (namespace: `pastefy`).

## 🎯 Quick facts

- Namespace: `pastefy`
- Images: `mariadb:12.1`, `busybox:1.37`, `interaapps/pastefy:7.1.5`
- Ports (from Services): `3306`, `80`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `pastefy-namespace.yml`: Namespace
- `pastefy-secrets.yml`: Secret
- `pastefy-app-service.yml`: Service
- `pastefy-db-headless-service.yml`: Service
- `pastefy-db-service.yml`: Service
- `pastefy-app-deployment.yml`: Deployment
- `pastefy-mariadb-db-statefulset.yml`: StatefulSet
- `pastefy-ingress.yml`: Ingress
- `pastefy-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `pastefy-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/pastefy/pastefy-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pastefy/pastefy-namespace.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-secrets.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-app-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-db-headless-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-db-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-app-deployment.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-mariadb-db-statefulset.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
