# 🗂️ Zabbix (k3s)

> ✨ **What is Zabbix?**
>
> Zabbix is a full-featured monitoring platform for infrastructure and applications.

---

This folder contains a k3s-ready Kubernetes configuration for **Zabbix** (namespace: `zabbix`).

## 🎯 Quick facts

- Namespace: `zabbix`
- Images: `busybox:1.35`, `postgres:16`, `zabbix/zabbix-server-pgsql:alpine-trunk`, ...
- Ports (from Services): `162`, `5432`, `8080`, `10051`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `secrets-example.yml`: Example secrets (placeholders)
- `zabbix-db-headless-service.yml`: Service
- `zabbix-db-service.yml`: Service
- `zabbix-db-statefulset.yml`: StatefulSet
- `zabbix-manifest.yml`: Combined multi-document manifest
- `zabbix-namespace.yml`: Namespace
- `zabbix-secrets.yml`: Secrets
- `zabbix-server-export-pvc.yml`: PersistentVolumeClaim (storage)
- `zabbix-server-pgsql-deployment.yml`: Deployment
- `zabbix-server-pgsql-service.yml`: Service
- `zabbix-server-web-deployment.yml`: Deployment
- `zabbix-server-web-service.yml`: Service
- `zabbix-snmptraps-data-pvc.yml`: PersistentVolumeClaim (storage)
- `zabbix-snmptraps-deployment.yml`: Deployment
- `zabbix-snmptraps-mibs-pvc.yml`: PersistentVolumeClaim (storage)
- `zabbix-snmptraps-service.yml`: Service
- `zabbix-web-ssl-pvc.yml`: PersistentVolumeClaim (storage)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

Apply the combined manifest:

```bash
kubectl apply -f kubernetes/applications/zabbix/zabbix-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/zabbix/zabbix-namespace.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-secrets.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-server-export-pvc.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-snmptraps-data-pvc.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-snmptraps-mibs-pvc.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-web-ssl-pvc.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-db-headless-service.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-db-service.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-server-pgsql-service.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-server-web-service.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-snmptraps-service.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-db-statefulset.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-server-pgsql-deployment.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-server-web-deployment.yml
kubectl apply -f kubernetes/applications/zabbix/zabbix-snmptraps-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
