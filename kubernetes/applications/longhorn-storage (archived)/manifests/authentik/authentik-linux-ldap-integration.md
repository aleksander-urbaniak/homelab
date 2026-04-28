# Authentik LDAP Setup Guide (Docker + Kubernetes Outpost)

This guide outlines how to configure the **generic LDAP provider** in **Authentik**. It allows applications that do **not support modern protocols** (OIDC / SAML) to authenticate users via **LDAP**, using an **Authentik LDAP Outpost**.

---

## Prerequisites

* An existing **Authentik** installation
* **Admin access** to the Authentik web interface
* Ability to deploy an outpost via either:

  * **Docker / Docker Compose**, or
  * **Kubernetes** (Deployment + Service + Secret)

---

## Step 1: Directory Preparation

Before configuring the LDAP provider, create a **service account** that the LDAP Outpost (and external applications) will use to **bind** and **search** the directory.

### 1.1 Create Service Account

1. Go to **Directory → Users**
2. Click **Create**
3. Set:

   * **Username:** `ldapservice` (or similar)
   * **Name:** LDAP Service Account
4. Set a **strong password** and record it
5. Save

### 1.2 Create Search Group

1. Go to **Directory → Groups**
2. Click **Create**
3. Set:

   * **Name:** `ldap-search`
4. Add **ldapservice** as a member
5. *(Optional)* Add other users you want visible via LDAP if you plan to restrict the search scope later

---

## Step 2: Create LDAP Provider

The provider defines the LDAP directory structure and authentication logic.

1. Go to **Applications → Providers**
2. Click **Create** → select **LDAP Provider**
3. Configure:

   * **Name:** LDAP Provider
   * **Bind Flow:** `default-authentication-flow` *(or a custom password-only flow)*
   * **Search Group:** `ldap-search`
   * **Base DN:**

     ```text
     dc=ldap,dc=example,dc=com
     ```
   * **Bind Mode:** Direct Bind
4. Click **Finish**

> ⚠️ **MFA Note**
>
> Standard LDAP clients do **not support MFA prompts**.
>
> If users have MFA enabled, LDAP login will fail unless:
>
> * users authenticate with `password;123456` (append TOTP), **or**
> * you assign a **password-only flow** to the LDAP Provider.

---

## Step 3: Create Application

This wraps the provider into an application entity.

1. Go to **Applications → Applications**
2. Click **Create**
3. Configure:

   * **Name:** LDAP Connect
   * **Slug:** `ldap-connect`
   * **Provider:** Select the LDAP Provider created in Step 2
   * **Policy:** Ensure the default policy allows access
4. Click **Finish**

---

## Step 4: Create LDAP Outpost in Authentik UI

The Outpost is the actual LDAP server component.

1. Go to **Applications → Outposts**
2. Click **Create**
3. Configure:

   * **Name:** LDAP Outpost
   * **Type:** LDAP
   * **Integration:**

     * choose **Local Docker** if you use Authentik’s docker integration, **or**
     * leave empty for manual deployment (Docker/Kubernetes)
   * **Applications:** Select **LDAP Connect**
4. Click **Create**
5. Open the outpost details and **copy the Token**

You will use this token in either the Docker or Kubernetes outpost deployment.

---

## Step 5: Deploy the LDAP Outpost

Choose **one** deployment method:

* ✅ **Option A: Docker / Docker Compose**
* ✅ **Option B: Kubernetes**

---

## Option A: Docker / Docker Compose Outpost

Add the LDAP outpost service to your Authentik `docker-compose.yaml`.

```yaml
services:
  # ... existing authentik services ...

  authentik_ldap:
    image: ghcr.io/goauthentik/ldap:stable
    # Alternatively, pin a specific version, e.g.: ghcr.io/goauthentik/ldap:2025.10.3
    restart: unless-stopped
    ports:
      - "389:3389"
      - "636:6636"
    environment:
      AUTHENTIK_HOST: https://auth.yourdomain.com
      AUTHENTIK_INSECURE: "false"   # Set "true" only if using self-signed certs
      AUTHENTIK_TOKEN: "REPLACE_ME"
```

Start (or restart) services:

```bash
docker-compose up -d
```

---

## Option B: Kubernetes Outpost (Deployment + Service + Secret)

This example runs the LDAP outpost in the `authentik` namespace and exposes it via a ClusterIP service.

### 1) Create the Secret

Create a secret that provides the required environment variables. At minimum, you typically need:

* `AUTHENTIK_HOST`
* `AUTHENTIK_INSECURE`
* `AUTHENTIK_TOKEN`

Example Secret manifest:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ak-ldap-outpost-secret
  namespace: authentik
type: Opaque
stringData:
  AUTHENTIK_HOST: "https://auth.yourdomain.com"
  AUTHENTIK_INSECURE: "false"
  AUTHENTIK_TOKEN: "REPLACE_ME"
```

Apply it:

```bash
kubectl apply -f ak-ldap-outpost-secret.yaml
```

---

### 2) Service

```yaml
# Authentik LDAP Outpost Service
---
apiVersion: v1
kind: Service
metadata:
  name: ak-ldap-outpost
  namespace: authentik
spec:
  type: ClusterIP
  selector:
    app: ak-ldap-outpost
  ports:
    - name: ldap
      port: 389
      targetPort: 3389
      protocol: TCP
    - name: ldaps
      port: 636
      targetPort: 6636
      protocol: TCP
```

---

### 3) Deployment

```yaml
# Authentik LDAP Outpost Deployment
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ak-ldap-outpost
  namespace: authentik
  labels:
    app: ak-ldap-outpost
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: ak-ldap-outpost
  template:
    metadata:
      labels:
        app: ak-ldap-outpost
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker: ""
      containers:
        - name: ldap
          image: ghcr.io/goauthentik/ldap:2025.10.3
          imagePullPolicy: IfNotPresent
          envFrom:
            - secretRef:
                name: ak-ldap-outpost-secret
          ports:
            - name: ldap-internal
              containerPort: 3389
              protocol: TCP
            - name: ldaps-internal
              containerPort: 6636
              protocol: TCP
          readinessProbe:
            tcpSocket:
              port: 3389
            initialDelaySeconds: 3
            periodSeconds: 5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
```

Apply manifests:

```bash
kubectl apply -f ak-ldap-outpost.yaml
```

> Tip: If you need the LDAP service reachable outside the cluster, change the Service type to `NodePort` or place it behind an Ingress / TCP load balancer depending on your environment.

---

## Step 6: Verification

Before connecting an application (e.g., Jellyfin, BookStack), verify the outpost is responding correctly using `ldapsearch`.

```bash
ldapsearch -x \
  -h <authentik_outpost_ip_or_service> -p 389 \
  -D "cn=ldapservice,ou=users,dc=ldap,dc=example,dc=com" \
  -w "service_account_password" \
  -b "dc=ldap,dc=example,dc=com" \
  "(objectClass=user)"
```

### Key parameters

* `-D` – Bind DN (often `cn=<username>,ou=users,<Base DN>`)
* `-w` – Password for the `ldapservice` account
* `-b` – Base DN configured in the LDAP Provider

If the command returns users, your LDAP outpost is working.

---

## Common Issues & Gotchas

### MFA conflicts

* Standard LDAP clients do not support MFA prompts.
* Use a password-only flow **or** `password;123456`.

### Bind DN errors

* Ensure the DN matches the expected directory structure.
* Default commonly looks like:

  ```text
  cn=username,ou=users,dc=...
  ```

### Connectivity

* Ensure required ports are reachable:

  * `389` (LDAP)
  * `636` (LDAPS)

---

✅ **LDAP authentication via Authentik Outpost is ready.**
