# 🗂️ Node Exporter (k3s)

> ✨ **What is Node Exporter?**
>
> Prometheus Node Exporter exposes host-level hardware and OS metrics.

---

This folder contains a k3s-ready Kubernetes configuration for **Node Exporter** (namespace: `node-exporter`).

## 🎯 Quick facts

- Namespace: `node-exporter`
- Images: `quay.io/prometheus/node-exporter:v1.10.2`
- Ports (from Services): `9100`

---

## 🧱 What gets deployed

- `node-exporter-daemonset.yml`: DaemonSet
- `node-exporter-manifest-example.yml`: Example combined manifest (with placeholders)
- `node-exporter-manifest.yml`: Combined multi-document manifest
- `node-exporter-namespace.yml`: Namespace
- `node-exporter-service.yml`: Service

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `node-exporter-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/node-exporter/node-exporter-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/node-exporter/node-exporter-namespace.yml
kubectl apply -f kubernetes/applications/node-exporter/node-exporter-service.yml
kubectl apply -f kubernetes/applications/node-exporter/node-exporter-daemonset.yml
```
