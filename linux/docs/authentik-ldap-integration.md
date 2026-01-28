# Authentik LDAP + SSSD (Debian/Ubuntu, RHEL/Oracle Linux)

This document describes how to integrate a Linux host with **Authentik LDAP** (typically via an LDAP Outpost) using **SSSD** for:

- Login with LDAP credentials (commonly by **email**, e.g. `exampleuser@example.com`)
- Group-based access control (e.g. `linux-users`, `linux-admins`)
- Optional SSH public keys from LDAP (`sshPublicKey`)
- Automatic home directory creation on first login

## Prerequisites (Authentik / LDAP side)

- Create a **Bind DN** account (service user) and grant it read access to users/groups within your chosen bases.
- If you want `--access-mode ldap` (memberOf filter), your directory should expose `memberOf` for users (or an equivalent membership attribute).
- Have the correct DNs ready, for example:
  - Base DN: `dc=ldap,dc=example,dc=com`
  - Users OU: `ou=users,dc=ldap,dc=example,dc=com`
  - Groups OU/base: `ou=groups,dc=ldap,dc=example,dc=com`

## Quick start (RHEL / Oracle Linux 8–9)

This repo includes a RHEL/OL-focused script:

```bash
sudo bash linux/scripts/authentik-ldap-intergration.sh \
  --host ldap.example.com \
  --domain example.com \
  --base-dn 'dc=ldap,dc=example,dc=com' \
  --user-ou 'ou=users,dc=ldap,dc=example,dc=com' \
  --group-base 'ou=groups,dc=ldap,dc=example,dc=com' \
  --bind-dn 'cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com' \
  --access-group 'linux-users,linux-admins' \
  --access-mode ldap \
  --ssh-ldap-keys \
  --test-user 'exampleuser@example.com'
```

Notes:
- Default is **StartTLS on 389**. Use `--ldaps` for **LDAPS on 636**.
- The script prompts interactively for the Bind DN password (it is not passed on the CLI).

### What the script changes (high level)

- Installs packages (SSSD, LDAP clients, SSH server, mkhomedir helpers).
- Writes `/etc/sssd/sssd.conf`:
  - `id_provider = ldap`, `auth_provider = ldap`
  - Login attribute set to `mail` (`ldap_user_name = mail`)
  - Optional `ldap_user_ssh_public_key = sshPublicKey`
  - Access gating:
    - `--access-mode ldap` uses a membership filter (`ldap_access_filter`) if group DNs can be resolved
    - otherwise it falls back to `simple_allow_groups`
  - Short cache TTLs can be configured via flags (defaults: user/group 30s, negative 10s)
- Enables SSSD, configures PAM/NSS, turns on `mkhomedir`
- Adds an sshd drop-in at `/etc/ssh/sshd_config.d/99-sssd.conf`
- Adds sudo rule for admins: `%linux-admins ALL=(ALL) NOPASSWD: ALL`

## Debian / Ubuntu (manual checklist)

There is no Debian/Ubuntu installer script in this repo at the moment, but the same SSSD approach works. Minimal checklist:

1) Install packages
```bash
sudo apt update
sudo apt install -y sssd sssd-ldap libnss-sss libpam-sss ldap-utils openssh-server
```

2) Create `/etc/sssd/sssd.conf` (adapt the bases/host)
```ini
[sssd]
services = nss, pam, ssh
domains = example.com

[nss]
entry_negative_timeout = 10

[domain/example.com]
id_provider = ldap
auth_provider = ldap
access_provider = simple
simple_allow_groups = linux-users,linux-admins

ldap_uri = ldap://ldap.example.com
ldap_id_use_start_tls = True
ldap_search_base = dc=ldap,dc=example,dc=com
ldap_user_search_base = ou=users,dc=ldap,dc=example,dc=com
ldap_group_search_base = ou=groups,dc=ldap,dc=example,dc=com

ldap_user_name = mail
ldap_default_bind_dn = cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com
ldap_default_authtok_type = password
ldap_default_authtok = REPLACE_ME
```

3) Secure the config and restart SSSD
```bash
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf
sudo systemctl enable --now sssd
sudo sss_cache -E && sudo systemctl restart sssd
```

4) Ensure home dirs are created (one common way)
```bash
sudo pam-auth-update --enable mkhomedir
```

## Verification & debugging

### TLS / connectivity
```bash
# StartTLS (389)
openssl s_client -starttls ldap -connect ldap.example.com:389 -brief </dev/null

# LDAPS (636)
openssl s_client -connect ldap.example.com:636 -servername ldap.example.com -brief </dev/null
```

### LDAP queries
```bash
ldapsearch -LLL -x -H ldap://ldap.example.com -ZZ \
  -D 'cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com' -W \
  -b 'ou=users,dc=ldap,dc=example,dc=com' '(mail=exampleuser@example.com)' dn memberOf
```

### SSSD lookups
```bash
sssctl domain-status example.com
getent passwd 'exampleuser@example.com'
id 'exampleuser@example.com'
journalctl -u sssd_pam -b -n 200 --no-pager
journalctl -u sshd -b -n 200 --no-pager
```

After changing group membership:
```bash
sss_cache -E && systemctl restart sssd
```

## Common issues

- **Bind DN cannot search (`Insufficient access (50)`)**: ensure the Bind account has read permissions on the configured user/group bases.
- **Group filter doesn’t work**: confirm that group membership attributes are returned (`memberOf` or equivalent). If needed, switch to `access_provider = simple`.
- **Local emergency account won’t work**: ensure `nsswitch.conf` prefers `files` before `sss` and that you don’t have restrictive `AllowGroups` in SSH.

