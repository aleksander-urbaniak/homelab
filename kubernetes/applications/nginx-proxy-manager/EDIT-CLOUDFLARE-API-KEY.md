# 🔑 Edit Cloudflare API Key/Token in Nginx Proxy Manager (k3s) via DB ✨

Nginx Proxy Manager does not reliably expose Cloudflare DNS credential editing for existing certs in UI.  
In this deployment, update it directly in MariaDB.

## Important

- Prefer a **Cloudflare API Token** over a Global API Key.
- Minimum token permissions:
  - `Zone:DNS:Edit`
  - `Zone:Zone:Read`
- Scope token to required zone(s) only.

## 1) Connect to MariaDB in Kubernetes

Get DB credentials from secret and enter the DB pod:

```bash
kubectl -n nginx-proxy-manager get secret mariadb-secret -o yaml
kubectl -n nginx-proxy-manager exec -it statefulset/mariadb -- sh
```

Inside pod:

```bash
mysql -u<MYSQL_USER> -p<DB_MYSQL_PASSWORD> proxy-manager
```

## 2) Backup before changes

From inside DB pod:

```bash
mysqldump -u<MYSQL_USER> -p<DB_MYSQL_PASSWORD> proxy-manager > /tmp/proxy-manager-before-cloudflare-key-rotate.sql
```

## 3) Find the certificate row

Common query:

```sql
SELECT id, nice_name, provider, domain_names
FROM certificate
WHERE provider = 'dns-cloudflare';
```

If your schema/provider naming differs, discover candidates:

```sql
SELECT id, nice_name, provider, domain_names
FROM certificate
ORDER BY id DESC;
```

## 4) Inspect current metadata

```sql
SELECT id, meta FROM certificate WHERE id = <CERT_ID>;
```

`meta` contains provider credentials/config JSON for that certificate.

## 5) Update Cloudflare credential in `meta`

Update only the key/token field inside JSON.  
Use one of these patterns depending on your stored field name.

```sql
-- If meta uses "dns_cloudflare_api_token"
UPDATE certificate 
SET meta = REPLACE(meta, 'YOUR_OLD_TOKEN_STRING', 'YOUR_NEW_TOKEN_STRING') 
WHERE id = <CERT_ID>;
```

Verify:

```sql
SELECT id, meta FROM certificate WHERE id = <CERT_ID>;
```

## 6) Restart NPM and validate

```bash
kubectl -n nginx-proxy-manager rollout restart deploy/nginx-proxy-manager
kubectl -n nginx-proxy-manager rollout status deploy/nginx-proxy-manager
kubectl -n nginx-proxy-manager logs deploy/nginx-proxy-manager --tail=200
```

Look for successful ACME DNS challenge and certificate renewal/issue.

## Rollback

If renewal fails after update:

```bash
kubectl -n nginx-proxy-manager exec -it statefulset/mariadb -- sh
mysql -u<MYSQL_USER> -p<DB_MYSQL_PASSWORD> proxy-manager < /tmp/proxy-manager-before-cloudflare-key-rotate.sql
```

Then restart NPM deployment again.

## Security notes

- Never commit real Cloudflare credentials to Git.
- Rotate old token/key immediately after successful cutover.
- Prefer short-lived, scoped API tokens over global keys.
