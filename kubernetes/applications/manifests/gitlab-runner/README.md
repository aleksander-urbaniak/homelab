# 🗂️ GitLab Runner (k3s) ✨

> ✨ **What is GitLab Runner?**
>
> GitLab Runner executes CI/CD jobs for GitLab pipelines.

---

This folder contains a k3s-ready Kubernetes configuration for **GitLab Runner** (namespace: `gitlab-runner`).

## 🎯 Quick facts

- Namespace: `gitlab-runner`
- Image: `gitlab/gitlab-runner:alpine`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `gitlab-runner-namespace.yml`: Namespace
- `gitlab-runner-config-configmap.yml`: ConfigMap
- `gitlab-runner-pvc-persistentvolumeclaim.yml`: PersistentVolumeClaim (storage)
- `gitlab-runner-sa-serviceaccount.yml`: ServiceAccount
- `gitlab-runner-admin-binding-clusterrolebinding.yml`: Combined multi-document manifest
- `gitlab-runner-deployment.yml`: Deployment
- `gitlab-runner-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `gitlab-runner-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-namespace.yml
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-config-configmap.yml
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-sa-serviceaccount.yml
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-admin-binding-clusterrolebinding.yml
kubectl apply -f kubernetes/applications/manifests/gitlab-runner/gitlab-runner-deployment.yml
```
