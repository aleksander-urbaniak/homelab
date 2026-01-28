# 🗂️ GitLab (k3s)

> ✨ **What is GitLab?**
>
> GitLab Community Edition provides Git hosting, CI/CD, and project/project-management features.

---

This folder contains a k3s-ready Kubernetes configuration for **GitLab** (namespace: `gitlab`).

## 🎯 Quick facts

- Namespace: `gitlab`
- Images: `alpine:3.23`, `gitlab/gitlab-ce:18.6.2-ce.0`
- Ports (from Services): `22`, `80`, `443`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `gitlab-config-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `gitlab-data-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `gitlab-deployment.yml`: Deployment
- `gitlab-logs-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `gitlab-manifest.yml`: Combined multi-document manifest
- `gitlab-namespace.yml`: Namespace
- `gitlab-pgdata-pvc-pvc.yml`: PersistentVolumeClaim (storage)
- `gitlab-service.yml`: Service

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/gitlab/gitlab-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/gitlab/gitlab-namespace.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-config-pvc-pvc.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-data-pvc-pvc.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-logs-pvc-pvc.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-pgdata-pvc-pvc.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-service.yml
kubectl apply -f kubernetes/applications/gitlab/gitlab-deployment.yml
```
