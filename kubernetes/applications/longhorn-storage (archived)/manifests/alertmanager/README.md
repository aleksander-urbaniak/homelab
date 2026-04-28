# ☸️ Alertmanager (k3s) ✨

This folder contains a k3s-ready Kubernetes configuration for Alertmanager (namespace: `alertmanager`).

## Quick facts

- Namespace: `alertmanager`
- Image: `prom/alertmanager:v0.30.1`
- Service port: `9093`
- StorageClass: `longhorn`
- Node placement: `nodeSelector` (`node-role.kubernetes.io/worker: ""`)

## Files

- `alertmanager-namespace.yml`: Namespace
- `alertmanager-data-pvc-persistentvolumeclaim.yml`: PVC for Alertmanager data
- `alertmanager-config-configmap.yml`: Alertmanager config
- `alertmanager-service.yml`: Service
- `alertmanager-deployment.yml`: Deployment
- `alertmanager-ingress.yml`: Ingress
- `alertmanager-manifest.yml`: Combined multi-document manifest
- `alertmanager-manifest-example.yml`: Example combined manifest

## Configuration notes

- The Discord webhook is redacted in this repo as `REPLACE_ME`.
- Update `webhook_url` before applying manifests.

## Deploy

This folder includes both combined and split manifests.

### Option A: apply the combined manifest

```bash
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-namespace.yml
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-data-pvc-persistentvolumeclaim.yml
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-config-configmap.yml
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-service.yml
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-deployment.yml
kubectl apply -f kubernetes/applications/manifests/alertmanager/alertmanager-ingress.yml
```
