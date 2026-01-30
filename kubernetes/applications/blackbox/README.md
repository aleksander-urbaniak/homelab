# 🗂️ Blackbox Exporter (k3s)

> ✨ **What is Blackbox Exporter?**
>
> Prometheus Blackbox Exporter probes endpoints (HTTP/TCP/ICMP/DNS) and exports the results as metrics.

---

This folder contains a k3s-ready Kubernetes configuration for **Blackbox Exporter** (namespace: `blackbox`).

## 🎯 Quick facts

- Namespace: `blackbox`
- Image: `quay.io/prometheus/blackbox-exporter:v0.28.0`
- Ports (from Services): `9115`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `blackbox-namespace.yml`: Namespace
- `blackbox-config-configmap.yml`: ConfigMap
- `config-map-blackbox-config-configmap.yml`: ConfigMap
- `config-map-manifest.yml`: ConfigMap
- `blackbox-exporter-service.yml`: Service
- `blackbox-exporter-deployment.yml`: Deployment
- `blackbox-ingress.yml`: Ingress
- `blackbox-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/blackbox/blackbox-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/blackbox/blackbox-namespace.yml
kubectl apply -f kubernetes/applications/blackbox/blackbox-config-configmap.yml
kubectl apply -f kubernetes/applications/blackbox/config-map-blackbox-config-configmap.yml
kubectl apply -f kubernetes/applications/blackbox/config-map-manifest.yml
kubectl apply -f kubernetes/applications/blackbox/blackbox-exporter-service.yml
kubectl apply -f kubernetes/applications/blackbox/blackbox-exporter-deployment.yml
kubectl apply -f kubernetes/applications/blackbox/blackbox-ingress.yml
```
