# 🗂️ MetalLB (k3s)

> ✨ **What is MetalLB?**
>
> MetalLB provides LoadBalancer services for bare-metal Kubernetes clusters.

---

This folder contains a k3s-ready Kubernetes configuration for **MetalLB** (namespace: `metallb-system`).

## 🎯 Quick facts

- Namespace: `metallb-system`

---

## 🧱 What gets deployed

- `metallb-addr-pool.yml`: Kubernetes manifest
- `metallb-l2-advertisment.yml`: Kubernetes manifest

## Configuration notes (k3s)

- **Storage**: If you add PVCs, ensure your cluster has a suitable default StorageClass.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/metallb/metallb-addr-pool.yml
kubectl apply -f kubernetes/applications/metallb/metallb-l2-advertisment.yml
```
