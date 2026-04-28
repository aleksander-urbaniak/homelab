# 💻 Authentik + LDAP + SSSD on Debian/Ubuntu

This package contains:

- `authentik-ldap-integration.sh` for installation and configuration on Debian/Ubuntu
- short usage and troubleshooting notes

## Usage

```bash
sudo bash authentik-ldap-integration.sh \
  --host ldap.example.com \
  --domain example.com \
  --base-dn 'dc=ldap,dc=example,dc=com' \
  --user-ou 'ou=users,dc=ldap,dc=example,dc=com' \
  --group-base 'ou=groups,dc=ldap,dc=example,dc=com' \
  --bind-dn 'cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com' \
  --ssh-ldap-keys \
  --access-group 'linux-users,linux-admins' \
  --access-mode ldap \
  --login-attr mail \
  --prefer-local yes \
  --cache-user-ttl 30 \
  --cache-group-ttl 30 \
  --negative-ttl 10 \
  --test-user 'exampleuser@example.com'
```

> If the LDAP server does not allow anonymous or search bind access, the **Bind DN** must be correct and the password must be valid.

## What the Script Does

- Installs `sssd`, `sssd-ldap`, `libnss-sss`, `libpam-sss`, `ldap-utils`, `openssh-server`, and optionally `sssd-ssh`
- Enables **StartTLS on port 389** by default, or **LDAPS on port 636** with `--ldaps`
- Uses **mail-based login** through `ldap_user_name = mail`
- Sets short SSSD cache TTL values for users, groups, and negative lookups
- Prefers local accounts in NSS with `files sss`
- Enables `pam_mkhomedir`
- Supports group-based access control with `--access-mode ldap|simple`
- Supports optional SSH public key retrieval from LDAP via `sshPublicKey`

## Useful Commands

```bash
sssctl domain-status example.com
sss_cache -E && systemctl restart sssd
journalctl -u ssh -b -n 200 --no-pager
journalctl -u sssd_pam -b -n 200 --no-pager
getent passwd 'user@domain'
id 'user@domain'
```

## Debug Notes

- If group names cannot be resolved to full DNs, the script switches from `ldap_access_filter` to `simple_allow_groups`
- After changing group membership, clear cache and restart SSSD:

```bash
sss_cache -E && systemctl restart sssd
```
