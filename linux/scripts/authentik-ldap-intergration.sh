#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/sssd-setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "[\033[32m✓\033[0m] %s\n" "$*"; }
info() { printf "[*] %s\n" "$*"; }
warn() { printf "[\033[33m!\033[0m] %s\n" "$*"; }
err()  { printf "[\033[31m✗\033[0m] %s\n" "$*"; }
die()  { err "$*"; exit 1; }
trap 'err "Script failed at line $LINENO. See log: $LOG"; exit 1' ERR

# ========= Arguments & defaults =========
HOST=""; DOMAIN=""; BASE_DN=""; USER_OU=""; GROUP_BASE=""; BIND_DN=""
ACCESS_GROUPS="linux-users,linux-admins"
ACCESS_MODE="ldap"                 # ldap|simple|permit (default ldap)
SSH_KEYS="no"
CA_FILE=""
USE_LDAPS="no"                     # default: StartTLS on 389
TLS_REQCERT="allow"
MODE="apply"
TEST_USER=""
PREFER_LOCAL="yes"                 # local accounts preferred in NSS
CACHE_USER_TTL="30"
CACHE_GROUP_TTL="30"
NEGATIVE_TTL="10"

usage() {
cat <<EOF
Usage: $0 --host <fqdn> --domain <sssd-domain> --base-dn <DN> --user-ou <DN> --group-base <DN> --bind-dn <DN> [options]

Required:
  --host            LDAP host FQDN (e.g. ldap.example.com)
  --domain          SSSD domain label (e.g. example.com)
  --base-dn         Base DN (e.g. dc=ldap,dc=example,dc=com)
  --user-ou         Users OU DN (e.g. ou=users,dc=ldap,dc=example,dc=com)
  --group-base      Groups base DN (e.g. ou=groups,dc=ldap,dc=example,dc=com)
  --bind-dn         Bind DN (e.g. cn=ldap-service-account,ou=users,dc=ldap,dc=example,dc=com)

Options:
  --access-group "<g1[,g2...]|DN1[,DN2...]>"  (default: linux-users,linux-admins)
  --access-mode <ldap|simple|permit>          (default: ldap)
  --ssh-ldap-keys                             (enable ldap_user_ssh_public_key=sshPublicKey)
  --ca-file <path>                            (extra CA, if using private PKI)
  --ldaps                                     (use LDAPS:636 instead of StartTLS:389)
  --prefer-local <yes|no>                     (default yes: local users first in NSS)
  --cache-user-ttl <sec>                      (default 30)
  --cache-group-ttl <sec>                     (default 30)
  --negative-ttl <sec>                        (default 10)  [in [nss] section]
  --mode <apply|check>                        (default apply)
  --test-user <login>                         (e.g. exampleuser@example.com)
  -h|--help
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --base-dn) BASE_DN="$2"; shift 2;;
    --user-ou) USER_OU="$2"; shift 2;;
    --group-base) GROUP_BASE="$2"; shift 2;;
    --bind-dn) BIND_DN="$2"; shift 2;;
    --access-group) ACCESS_GROUPS="$2"; shift 2;;
    --access-mode) ACCESS_MODE="$2"; shift 2;;
    --ssh-ldap-keys) SSH_KEYS="yes"; shift;;
    --ca-file) CA_FILE="$2"; shift 2;;
    --ldaps) USE_LDAPS="yes"; shift;;
    --prefer-local) PREFER_LOCAL="$2"; shift 2;;
    --cache-user-ttl) CACHE_USER_TTL="$2"; shift 2;;
    --cache-group-ttl) CACHE_GROUP_TTL="$2"; shift 2;;
    --negative-ttl) NEGATIVE_TTL="$2"; shift 2;;
    --mode) MODE="$2"; shift 2;;
    --test-user) TEST_USER="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done

[[ -n "$HOST" && -n "$DOMAIN" && -n "$BASE_DN" && -n "$USER_OU" && -n "$GROUP_BASE" && -n "$BIND_DN" ]] || { usage; die "Missing required arguments."; }
[[ $EUID -eq 0 ]] || die "Run as root."

bold "Log: $LOG"
info "Config: host=$HOST, domain=$DOMAIN, LDAPS=$USE_LDAPS, access-mode=$ACCESS_MODE, prefer-local=$PREFER_LOCAL, mode=$MODE"

# ========= 0) Time sync =========
info "0) Time sync (chrony)…"
dnf -y install chrony >/dev/null 2>&1 || true
systemctl enable --now chronyd >/dev/null 2>&1 || true

# ========= 1) Packages =========
info "1) Installing/verifying packages…"
dnf -y install sssd sssd-tools sssd-ldap authselect oddjob oddjob-mkhomedir \
  openldap-clients openssl ca-certificates nmap-ncat >/dev/null
ok "Packages installed."

# ========= 2) Connectivity =========
info "2) LDAP connectivity…"
if [[ "$USE_LDAPS" = "yes" ]]; then
  nc -vz -w3 "$HOST" 636
else
  nc -vz -w3 "$HOST" 389
fi
ok "TCP connectivity OK."

# ========= 3) CA trust (optional) =========
if [[ -n "$CA_FILE" ]]; then
  info "3) Trusting custom CA: $CA_FILE"
  [[ -s "$CA_FILE" ]] || die "CA file not found: $CA_FILE"
  dest="/etc/pki/ca-trust/source/anchors/$(basename "$CA_FILE")"
  install -m 0644 "$CA_FILE" "$dest"
  update-ca-trust
  ok "CA installed to $dest"
else
  info "3) Using system CA trust."
fi

# ========= Bind password (interactive) =========
BIND_AUTHTOK_TYPE="obfuscated_password"
BIND_AUTHTOK_VALUE=""
BIND_PLAIN=""
if [[ "$MODE" = "apply" ]]; then
  echo -n "Bind password for $BIND_DN: " >&2
  stty -echo; read -r BP; echo >&2
  echo -n "Re-enter password: " >&2
  read -r BP2; echo >&2; stty echo
  [[ "$BP" = "$BP2" ]] || die "Bind passwords do not match."
  BIND_PLAIN="$BP"
  if command -v sss_obfuscate >/dev/null 2>&1; then
    if token="$(printf '%s\n%s\n' "$BP" "$BP" | sss_obfuscate -d "$DOMAIN" 2>/dev/null | awk '/^\$/{print; exit}')"; then
      BIND_AUTHTOK_VALUE="$token"
      BIND_AUTHTOK_TYPE="obfuscated_password"
      ok "Bind password obfuscated."
    else
      warn "sss_obfuscate failed; storing plaintext."
      BIND_AUTHTOK_TYPE="password"; BIND_AUTHTOK_VALUE="$BP"
    fi
  else
    warn "sss_obfuscate not found; storing plaintext."
    BIND_AUTHTOK_TYPE="password"; BIND_AUTHTOK_VALUE="$BP"
  fi
  unset BP BP2
fi

# ========= 4) StartTLS/LDAPS sanity check + minimal bind search =========
LDAP_URI="ldap://${HOST}"; LDAP_STARTTLS="True"; LDAP_TLS_SWITCH="-ZZ"
if [[ "$USE_LDAPS" = "yes" ]]; then
  LDAP_URI="ldaps://${HOST}"; LDAP_STARTTLS="False"; LDAP_TLS_SWITCH=""
fi

info "4) Verifying TLS handhsake and bind search…"
if [[ "$USE_LDAPS" = "yes" ]]; then
  openssl s_client -connect "${HOST}:636" -brief </dev/null | sed -n '1,6p' || true
else
  openssl s_client -starttls ldap -connect "${HOST}:389" -brief </dev/null | sed -n '1,6p' || true
fi

# Try a small search to confirm credentials (many servers block anon rootDSE)
LDAPTLS_REQCERT=$TLS_REQCERT ldapsearch -LLL -x -H "$LDAP_URI" $LDAP_TLS_SWITCH \
  -D "$BIND_DN" -w "${BIND_PLAIN:-dummy}" -b "$USER_OU" -s base "(objectClass=*)" dn >/dev/null \
  || warn "Bind search failed (may be wrong DN/pass or ACL). Continuing to write config anyway."

# ========= Helper: resolve group CN -> DN =========
IFS=',' read -r -a ACCESS_ARR <<<"${ACCESS_GROUPS:-}"
declare -a RESOLVED_DNS=()
resolve_group_dn() {
  local g="$1"
  if [[ "$g" == *"="* ]]; then echo "$g"; return 0; fi
  local dn=""
  dn="$(LDAPTLS_REQCERT=$TLS_REQCERT ldapsearch -LLL -x -H "$LDAP_URI" $LDAP_TLS_SWITCH \
        -D "$BIND_DN" -w "${BIND_PLAIN:-dummy}" -b "$GROUP_BASE" "(cn=$g)" dn 2>/dev/null \
        | awk '/^dn: /{sub(/^dn: /,"");print; exit}')"
  if [[ -z "$dn" ]]; then
    dn="$(LDAPTLS_REQCERT=$TLS_REQCERT ldapsearch -LLL -x -H "$LDAP_URI" $LDAP_TLS_SWITCH \
          -D "$BIND_DN" -w "${BIND_PLAIN:-dummy}" -b "$BASE_DN" "(cn=$g)" dn 2>/dev/null \
          | awk '/^dn: /{sub(/^dn: /,"");print; exit}')"
  fi
  [[ -n "$dn" ]] && echo "$dn" || echo ""
}

for g in "${ACCESS_ARR[@]}"; do
  dn="$(resolve_group_dn "$g" || true)"
  if [[ -n "$dn" ]]; then
    RESOLVED_DNS+=("$dn")
    ok "Resolved group '$g' -> '$dn'"
  else
    warn "Group '$g' not resolved to DN (will fallback to SIMPLE if using ldap filter)."
  fi
done

# ========= 5) Build access provider =========
ACCESS_PROVIDER="permit"; ACCESS_EXTRAS=""
case "$ACCESS_MODE" in
  permit) ACCESS_PROVIDER="permit";;
  simple)
    ACCESS_PROVIDER="simple"
    ACCESS_EXTRAS=$'\n'"simple_allow_groups = ${ACCESS_GROUPS}"
    ;;
  ldap)
    if [[ ${#RESOLVED_DNS[@]} -gt 0 ]]; then
      ACCESS_PROVIDER="ldap"
      # Build OR filter over resolved DNs
      filt="(|"; for dn in "${RESOLVED_DNS[@]}"; do filt+="(memberOf=${dn})"; done; filt+=")"
      ACCESS_EXTRAS=$'\n'"ldap_access_order = filter"$'\n'"ldap_access_filter = ${filt}"
    else
      warn "No group DN resolved for LDAP filter → falling back to SIMPLE."
      ACCESS_PROVIDER="simple"
      ACCESS_EXTRAS=$'\n'"simple_allow_groups = ${ACCESS_GROUPS}"
    fi
    ;;
  *) die "--access-mode must be one of: permit|simple|ldap";;
esac

# ========= 6) Write /etc/sssd/sssd.conf =========
info "6) Writing /etc/sssd/sssd.conf…"

CACERT_LINE=""
if [[ -n "$CA_FILE" ]]; then
  CACERT_LINE=$'\n'"ldap_tls_cacert = /etc/pki/ca-trust/source/anchors/$(basename "$CA_FILE")"
fi

cat >/etc/sssd/sssd.conf <<EOF
[sssd]
services = nss, pam, ssh
domains = ${DOMAIN}

[nss]
homedir_substring = /home
entry_negative_timeout = ${NEGATIVE_TTL}

[pam]

[domain/${DOMAIN}]
id_provider = ldap
auth_provider = ldap
access_provider = ${ACCESS_PROVIDER}${ACCESS_EXTRAS}

cache_credentials = True
enumerate = False
entry_cache_user_timeout = ${CACHE_USER_TTL}
entry_cache_group_timeout = ${CACHE_GROUP_TTL}

ldap_uri = ${LDAP_URI}
ldap_id_use_start_tls = ${LDAP_STARTTLS}
ldap_tls_reqcert = ${TLS_REQCERT}${CACERT_LINE}
ldap_referrals = false
ldap_network_timeout = 3

ldap_schema = rfc2307bis
ldap_search_base       = ${BASE_DN}
ldap_user_search_base  = ${USER_OU}
ldap_user_search_filter = (mail=*)
ldap_group_search_base = ${GROUP_BASE}
ldap_group_member = member

ldap_user_name  = mail
ldap_user_email = mail
re_expression = (?P<name>[^@]+)(@(?P<domain>.*))?

ldap_default_bind_dn = ${BIND_DN}
ldap_default_authtok_type = ${BIND_AUTHTOK_TYPE}
ldap_default_authtok = ${BIND_AUTHTOK_VALUE}

use_fully_qualified_names = False
fallback_homedir = /home/%u
default_shell = /bin/bash
EOF

if [[ "$SSH_KEYS" = "yes" ]]; then
  echo "ldap_user_ssh_public_key = sshPublicKey" >> /etc/sssd/sssd.conf
fi

chmod 600 /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
ok "sssd.conf written."

# ========= 7) PAM/NSS + sshd =========
info "7) authselect & mkhomedir…"
authselect select sssd with-mkhomedir --force
systemctl enable --now oddjobd >/dev/null || true

if [[ "$PREFER_LOCAL" == "yes" ]]; then
  info "   NSS: prefer local users over SSSD…"
  cp -a /etc/nsswitch.conf "/etc/nsswitch.conf.bak.$(date +%s)" || true
  sed -ri 's/^(passwd:\s*).*/\1files sss/; s/^(group:\s*).*/\1files sss/; s/^(shadow:\s*).*/\1files sss/' /etc/nsswitch.conf
fi

info "   Clean legacy PAM exec hooks (if any)…"
sed -ri '/pam_exec\.so.*ssh-ldap-allow\.sh/d' /etc/pam.d/sshd || true

info "   sshd drop-in…"
install -d -m 0755 /etc/ssh/sshd_config.d
{
  echo "UsePAM yes"
  echo "PasswordAuthentication yes"
  echo "LogLevel VERBOSE"
} > /etc/ssh/sshd_config.d/99-sssd.conf
/usr/sbin/sshd -t
systemctl restart sshd
ok "sshd configured."

# ========= 8) Restart SSSD & cache =========
info "8) Restarting SSSD…"
sssctl config-check || true
systemctl enable --now sssd >/dev/null
sss_cache -E || true
systemctl restart sssd
sleep 1

bold "== sssctl domain-status =="
sssctl domain-status "$DOMAIN" || true

# ========= 9) Sudoers for linux-admins =========
info "9) Adding linux-admins to sudoers (NOPASSWD)…"
printf '%%linux-admins ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-linux-admins-nopasswd
chmod 440 /etc/sudoers.d/10-linux-admins-nopasswd
visudo -cf /etc/sudoers.d/10-linux-admins-nopasswd >/dev/null
ok "Sudoers updated."

# ========= 10) Quick checks =========
info "10) Quick checks…"
if [[ -n "$TEST_USER" ]]; then
  echo
  bold "== getent/id '${TEST_USER}' =="
  getent passwd "$TEST_USER" || true
  id "$TEST_USER" || true
fi

ok "Done. Log: $LOG"
echo
bold "Notes:"
echo " - StartTLS: $( [[ $USE_LDAPS == "yes" ]] && echo "OFF (LDAPS 636)" || echo "ON (389)")"
echo " - Cache TTLs: user=${CACHE_USER_TTL}s group=${CACHE_GROUP_TTL}s negative(NSS)=${NEGATIVE_TTL}s"
echo " - Local accounts preferred in NSS: ${PREFER_LOCAL}"
echo " - If you change group membership and want immediate effect: sss_cache -E && systemctl restart sssd"
