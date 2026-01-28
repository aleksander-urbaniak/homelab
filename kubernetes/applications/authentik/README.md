# 🗂️ authentik (k3s)

> ✨ **What is authentik?**
>
> authentik is an identity provider for SSO (OAuth2/OIDC, SAML) and user/group management.

---

This folder contains a k3s-ready Kubernetes configuration for **authentik** (namespace: `authentik`).

## 🎯 Quick facts

- Namespace: `authentik`
- Images: `busybox:1.37`, `ghcr.io/goauthentik/ldap:2025.10.3`, `ghcr.io/goauthentik/server:2025.10.3`, ...
- Ports (from Services): `80`, `389`, `443`, `636`, `3389`, `5432`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `ak-ldap-outpost-deployment.yml`: Deployment
- `ak-ldap-outpost-service.yml`: Service
- `authentik-ldap-manifest-example.yml`: Example combined manifest (with placeholders)
- `authentik-ldap-manifest.yml`: Combined multi-document manifest
- `authentik-namespace.yml`: Namespace
- `authentik-postgres-service.yml`: Service
- `authentik-postgres-statefulset.yml`: StatefulSet
- `authentik-pvcs.yml`: PersistentVolumeClaim (storage)
- `authentik-redis-service.yml`: Service
- `authentik-redis-statefulset.yml`: StatefulSet
- `authentik-secrets.yml`: Secrets
- `authentik-server-deployment.yml`: Deployment
- `authentik-server-service.yml`: Service
- `authentik-worker-deployment.yml`: Deployment
- `secrets-example.yml`: Example secrets (placeholders)

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `authentik-ldap-manifest-example.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/authentik/authentik-ldap-manifest-example.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/authentik/authentik-namespace.yml
kubectl apply -f kubernetes/applications/authentik/authentik-secrets.yml
kubectl apply -f kubernetes/applications/authentik/authentik-pvcs.yml
kubectl apply -f kubernetes/applications/authentik/ak-ldap-outpost-service.yml
kubectl apply -f kubernetes/applications/authentik/authentik-postgres-service.yml
kubectl apply -f kubernetes/applications/authentik/authentik-redis-service.yml
kubectl apply -f kubernetes/applications/authentik/authentik-server-service.yml
kubectl apply -f kubernetes/applications/authentik/authentik-postgres-statefulset.yml
kubectl apply -f kubernetes/applications/authentik/authentik-redis-statefulset.yml
kubectl apply -f kubernetes/applications/authentik/ak-ldap-outpost-deployment.yml
kubectl apply -f kubernetes/applications/authentik/authentik-server-deployment.yml
kubectl apply -f kubernetes/applications/authentik/authentik-worker-deployment.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
