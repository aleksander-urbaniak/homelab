# ☸️ authentik (k3s) ✨

> ✨ **What is authentik?**
>
> authentik is an identity provider for SSO (OAuth2/OIDC, SAML) and user/group management.

---

This folder contains a k3s-ready Kubernetes configuration for **authentik** (namespace: `authentik`).

## 🎯 Quick facts

- Namespace: `authentik`
- Images: `postgres:18`, `redis:alpine`, `busybox:1.37`, `ghcr.io/goauthentik/server:2025.12.1`, `ghcr.io/goauthentik/ldap:2025.12.1`
- Ports (from Services): `5432`, `6379`, `80`, `443`, `389`, `636`
- StorageClass: `longhorn`
- Node placement: uses `nodeSelector` in at least one workload

---

## 🧱 What gets deployed

- `authentik-namespace.yml`: Namespace
- `authentik-secrets.yml`: Secret
- `authentik-pvcs.yml`: PersistentVolumeClaim (storage)
- `ak-ldap-outpost-service.yml`: Service
- `authentik-postgres-service.yml`: Service
- `authentik-redis-service.yml`: Service
- `authentik-server-service.yml`: Service
- `ak-ldap-outpost-deployment.yml`: Deployment
- `authentik-server-deployment.yml`: Deployment
- `authentik-worker-deployment.yml`: Deployment
- `authentik-postgres-statefulset.yml`: StatefulSet
- `authentik-redis-statefulset.yml`: StatefulSet
- `authentik-ingress.yml`: Ingress
- `authentik-ldap-manifest.yml`: Combined multi-document manifest

## Configuration notes (k3s)

- **Storage**: PVCs reference the StorageClass above; adjust it if your cluster uses something else.
- **Node placement**: Some workloads pin to specific nodes via `nodeSelector`; adjust labels as needed.
- **External access**: Most Services are `ClusterIP`; expose via Ingress / Gateway / reverse proxy as desired.
- **Images**: manifest files are the source of truth; Renovate may update image tags automatically, so this README can drift.

## Deploy 🚀

This folder may include both **combined** manifests (`*-manifest*.yml`) and **split** manifests (the other files).

### Option A: apply the combined manifest

1. Edit `authentik-ldap-manifest.yml` and replace placeholders.
2. Apply:

```bash
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-ldap-manifest.yml
```

### Option B: apply the split manifests

```bash
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-namespace.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-secrets.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-pvcs.yml
kubectl apply -f kubernetes/applications/manifests/authentik/ak-ldap-outpost-service.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-postgres-service.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-redis-service.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-server-service.yml
kubectl apply -f kubernetes/applications/manifests/authentik/ak-ldap-outpost-deployment.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-server-deployment.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-worker-deployment.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-postgres-statefulset.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-redis-statefulset.yml
kubectl apply -f kubernetes/applications/manifests/authentik/authentik-ingress.yml
```

Tip: start by copying/editing `secrets-example.yml` (and any `*-secrets.yml`) before applying.
