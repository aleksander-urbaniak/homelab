# 🗂️ kube-state-metrics (k3s)

> ✨ **What is kube-state-metrics?**
>
> kube-state-metrics exports Kubernetes object state as Prometheus metrics.

---

This folder contains a k3s-ready Kubernetes configuration for **kube-state-metrics** (namespace: `kube-state-metrics`).

## 🎯 Quick facts

- Namespace: `kube-state-metrics`
- Images: `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.17.0`
- Ports (from Services): `8080`

---

## 🧱 What gets deployed

- `kube-state-metrics-clusterrole.yml`: ClusterRole (RBAC)
- `kube-state-metrics-clusterrolebinding.yml`: ClusterRoleBinding (RBAC)
- `kube-state-metrics-deployment.yml`: Deployment
- `kube-state-metrics-manifest-example.yml`: Example combined manifest (with placeholders)
- `kube-state-metrics-manifest.yml`: Combined multi-document manifest
- `kube-state-metrics-namespace.yml`: Namespace
- `kube-state-metrics-service.yml`: Service
- `kube-state-metrics-serviceaccount.yml`: ServiceAccount / RBAC

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `kube-state-metrics-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-namespace.yml
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-serviceaccount.yml
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-clusterrole.yml
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-clusterrolebinding.yml
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-service.yml
kubectl apply -f kubernetes/applications/kube-state-metrics/kube-state-metrics-deployment.yml
```
