# 🗂️ Pastefy (k3s)

> ✨ **What is Pastefy?**
>
> Pastefy is a self-hostable pastebin for sharing snippets and files.

---

This folder contains a k3s-ready Kubernetes configuration for **Pastefy** (namespace: `pastefy`).

## 🎯 Quick facts

- Namespace: `pastefy`
- Images: `busybox:1.37`, `interaapps/pastefy:7.1.5`, `mariadb:12.1`
- Ports (from Services): `80`, `3306`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `pastefy-app-deployment.yml`: Deployment
- `pastefy-app-service.yml`: Service
- `pastefy-db-headless-service.yml`: Service
- `pastefy-db-service.yml`: Service
- `pastefy-manifest-example.yml`: Example combined manifest (with placeholders)
- `pastefy-manifest.yml`: Combined multi-document manifest
- `pastefy-mariadb-db-statefulset.yml`: StatefulSet
- `pastefy-namespace.yml`: Namespace
- `pastefy-secrets.yml`: Secrets
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `pastefy-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/pastefy/pastefy-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/pastefy/pastefy-namespace.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-secrets.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-app-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-db-headless-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-db-service.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-mariadb-db-statefulset.yml
kubectl apply -f kubernetes/applications/pastefy/pastefy-app-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
