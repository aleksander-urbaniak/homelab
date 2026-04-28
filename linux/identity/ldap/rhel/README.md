# 💻 Authentik + LDAP + SSSD on RHEL / Oracle Linux 8-9

This document explains how to run the script that integrates RHEL / Oracle Linux with Authentik LDAP. It supports:

- login by **email address**
- group-based access control using `linux-users` and `linux-admins`
- passwordless sudo for `linux-admins`

The script configures **SSSD**, **PAM/NSS**, **sshd**, and **oddjobd**, and can optionally pull SSH public keys from LDAP.

> Tested on Oracle Linux / RHEL 9 and expected to work on version 8 as well.

---

## Quick Start

Recommended setup using LDAP **StartTLS on port 389**:

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
  --access-mode simple \
  --tls-reqcert allow \
  --test-user 'exampleuser@example.com'
```

> If you use a reverse proxy and want **LDAPS on port 636**, add `--ldaps`. Make sure the proxy preserves the correct LDAP/TLS behavior and presents a valid certificate for `ldap.example.com`.

---

## What the Script Does

- Installs `sssd`, `sssd-ldap`, `sssd-tools`, `oddjob`, `oddjob-mkhomedir`, `authselect-compat`, `openldap-clients`, `openssh-server`, and `ca-certificates`
- Creates `/etc/sssd/sssd.conf`
- Configures:
  - `id_provider = ldap`
  - `auth_provider = ldap`
  - email-based login with `ldap_user_name = mail`
  - support for both `user` and `user@domain` style names
  - search bind using the provided Bind DN
  - group-based access control:
    - `--access-mode ldap` uses `ldap_access_filter`
    - `--access-mode simple` uses `simple_allow_groups`
  - optional LDAP SSH public key support with `ldap_user_ssh_public_key = sshPublicKey`
- Configures **authselect** with the `sssd` profile and `with-mkhomedir`
- Starts and enables **oddjobd**
- Adds an `sshd` drop-in with `UsePAM yes` and `PasswordAuthentication yes`
- Clears SSSD cache and restarts the required services
- Adds sudoers entry:

```text
%linux-admins ALL=(ALL) NOPASSWD: ALL
```

### Prefer Local Accounts First

If you want local accounts to take priority for emergency access, set `/etc/nsswitch.conf` like this:

```text
passwd: files sss
group:  files sss
shadow: files sss
```

---

## Authentik-Side Requirements

- The **Bind DN** and password must have read access to the configured user and group trees
- For `--access-mode ldap`, the server must return `memberOf`, or the groups must expose `member` / `uniqueMember` values that refer to the user DN
- Make sure the groups exist under the expected DN, for example:

```text
cn=linux-users,ou=groups,dc=ldap,dc=example,dc=com
```

---

## Verification and Troubleshooting

### 1) Connection and TLS

```bash
# StartTLS on port 389
openssl s_client -starttls ldap -connect ldap.example.com:389 -brief </dev/null

# LDAPS on port 636
openssl s_client -connect ldap.example.com:636 -servername ldap.example.com -brief </dev/null
```

### 2) LDAP Tests

```bash
# RootDSE / namingContexts
ldapsearch -LLL -x -H ldap://ldap.example.com -ZZ -b "" -s base namingContexts defaultNamingContext

# Bind and search
ldapsearch -LLL -x -H ldap://ldap.example.com -ZZ \
  -D 'cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com' -W \
  -b 'ou=users,dc=ldap,dc=example,dc=com' -s one '(objectClass=*)' dn

# Search user by mail
ldapsearch -LLL -x -H ldap://ldap.example.com -ZZ \
  -D 'cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com' -W \
  -b 'ou=users,dc=ldap,dc=example,dc=com' '(mail=exampleuser@example.com)' dn memberOf
```

### 3) SSSD Status and Lookups

```bash
sssctl domain-status example.com
sssctl user-checks 'exampleuser@example.com'
getent passwd 'exampleuser@example.com'
id 'exampleuser@example.com'
journalctl -u sssd_pam -b -n 200 --no-pager
journalctl -u sshd -b -n 200 --no-pager
```

### 4) Cache and TTL

After group membership changes:

```bash
sss_cache -E && systemctl restart sssd
```

If you want shorter cache values, you can set:

```text
entry_cache_user_timeout = 30
entry_cache_group_timeout = 30
entry_negative_timeout = 10
```

---

## Common Problems

### Login closes right after password entry

- Make sure there is no legacy PAM hook left behind:

```bash
sed -ri '/pam_exec\.so.*ssh-ldap-allow\.sh/d' /etc/pam.d/sshd
systemctl restart sshd
```

- Check whether `AllowGroups` is restricting access independently of SSSD

### `ldap_bind: Insufficient access (50)`

- Verify the Bind DN path is correct
- Make sure the account has read access to both the user and group trees

### `ldap_access_filter` does not work

- Confirm that group CNs resolve to full DNs
- Confirm the LDAP user entry returns the expected `memberOf` values

### Local accounts cannot log in

- Make sure `nsswitch.conf` prefers `files` over `sss`
- Remove any conflicting `AllowGroups` restrictions
- Reset lockouts if needed:

```bash
faillock --user <login> --reset
```

### `sss_obfuscate` logs `failed; storing plaintext.`

This is usually only informational. The password still gets written as `ldap_default_authtok = ...`, but obfuscation is preferable when available.

---

## Transport Security

- **StartTLS:389** encrypts the session after STARTTLS negotiation
- **LDAPS:636** encrypts immediately after TCP connection
- In both cases, certificate validation should be enabled with `ldap_tls_reqcert = demand`
- For private CAs, use `--ca-file /path/to/ca.crt`

---

## Rollback

- `authselect` keeps backups under `/var/lib/authselect/backups/...`
- Remove the SSH drop-in from `/etc/ssh/sshd_config.d/99-sssd.conf` and restart `sshd`
- Remove or adjust `/etc/sudoers.d/10-linux-admins-nopasswd`
- Remove or edit `/etc/sssd/sssd.conf` and restart `sssd`

---

## Example Login

```bash
ssh -o PubkeyAuthentication=no -l 'exampleuser@example.com' 192.0.2.40
```

This should authenticate against Authentik and create the home directory automatically through `pam_mkhomedir`.

---

If something breaks, check `journalctl`, `sssctl`, and `ldapsearch`, then clear the SSSD cache after group membership changes.
