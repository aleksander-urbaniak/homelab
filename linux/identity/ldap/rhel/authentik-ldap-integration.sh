#!/usr/bin/env bash
set -Eeuo pipefail

LOG="/var/log/sssd-setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
ok()   { printf "[OK] %s\n" "$*"; }
info() { printf "[*] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err()  { printf "[ERR] %s\n" "$*"; }
die()  { err "$*"; exit 1; }

cleanup() {
  stty echo 2>/dev/null || true
}
trap cleanup EXIT
trap 'err "Script failed at line $LINENO. See log: $LOG"; exit 1' ERR

HOST=""
DOMAIN=""
BASE_DN=""
USER_OU=""
GROUP_BASE=""
BIND_DN=""

ACCESS_GROUPS="linux-users,linux-admins"
ACCESS_MODE="simple"          # simple|permit
SSH_KEYS="no"

CA_FILE=""
FETCH_CERT="yes"              # yes|no
TLS_MODE="auto"               # auto|ldaps|starttls
TLS_REQCERT="allow"           # allow|demand|never

MODE="apply"                  # apply|check
TEST_USER=""
CACHE_USER_TTL="30"
CACHE_GROUP_TTL="30"
NEGATIVE_TTL="10"
ENABLE_SUDOERS="yes"

LDAP_MODE=""
LDAP_URI=""
LDAP_STARTTLS=""
LDAP_PORT=""
LDAP_TLS_SWITCH=""
LDAP_TLS_CACERT=""
BIND_SECRET=""

usage() {
cat <<EOF
Usage: $0 --host <fqdn> --domain <sssd-domain> --base-dn <DN> --user-ou <DN> --group-base <DN> --bind-dn <DN> [options]

Required:
  --host <fqdn>
  --domain <sssd-domain>
  --base-dn <DN>
  --user-ou <DN>
  --group-base <DN>
  --bind-dn <DN>

Options:
  --access-group "<g1[,g2...]>"       Default: linux-users,linux-admins
  --access-mode <simple|permit>       Default: simple
  --ssh-ldap-keys                     Enable ldap_user_ssh_public_key = sshPublicKey
  --ca-file <path>                    Use this CA/cert file instead of fetching from server
  --fetch-cert <yes|no>               Default: yes
  --tls-mode <auto|ldaps|starttls>    Default: auto
  --tls-reqcert <allow|demand|never>  Default: allow
  --cache-user-ttl <sec>              Default: 30
  --cache-group-ttl <sec>             Default: 30
  --negative-ttl <sec>                Default: 10
  --mode <apply|check>                Default: apply
  --test-user <email>                 Example: exampleuser@example.com
  --enable-sudoers <yes|no>           Default: yes
  -h|--help
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

set_transport_vars() {
  local mode="$1"
  case "$mode" in
    ldaps)
      LDAP_MODE="ldaps"
      LDAP_URI="ldaps://${HOST}"
      LDAP_STARTTLS="False"
      LDAP_PORT="636"
      LDAP_TLS_SWITCH=""
      ;;
    starttls)
      LDAP_MODE="starttls"
      LDAP_URI="ldap://${HOST}"
      LDAP_STARTTLS="True"
      LDAP_PORT="389"
      LDAP_TLS_SWITCH="-ZZ"
      ;;
    *)
      die "Internal error: unsupported transport mode '$mode'"
      ;;
  esac
}

write_openldap_client_conf() {
  local conf="/etc/openldap/ldap.conf"
  local tmp
  tmp="$(mktemp)"

  mkdir -p /etc/openldap
  touch "$conf"

  awk '
    BEGIN {skip=0}
    /^# BEGIN managed-by-authentik-ldap-integration$/ {skip=1; next}
    /^# END managed-by-authentik-ldap-integration$/   {skip=0; next}
    skip==0 {print}
  ' "$conf" > "$tmp"

  cat >> "$tmp" <<EOF

# BEGIN managed-by-authentik-ldap-integration
TLS_CACERT ${LDAP_TLS_CACERT}
TLS_REQCERT ${TLS_REQCERT}
# END managed-by-authentik-ldap-integration
EOF

  install -m 0644 "$tmp" "$conf"
  rm -f "$tmp"
}

fetch_cert_for_mode() {
  local mode="$1"
  local dest="/etc/pki/ca-trust/source/anchors/${HOST}-${mode}.pem"
  local tmp
  tmp="$(mktemp)"

  set_transport_vars "$mode"
  info "Fetching certificate chain for ${mode} from ${HOST}:${LDAP_PORT}"

  if [[ "$mode" == "ldaps" ]]; then
    openssl s_client \
      -connect "${HOST}:636" \
      -servername "$HOST" \
      -showcerts </dev/null 2>/dev/null \
      | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > "$tmp"
  else
    openssl s_client \
      -starttls ldap \
      -connect "${HOST}:389" \
      -servername "$HOST" \
      -showcerts </dev/null 2>/dev/null \
      | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > "$tmp"
  fi

  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    return 1
  fi

  install -m 0644 "$tmp" "$dest"
  rm -f "$tmp"

  LDAP_TLS_CACERT="$dest"
  export LDAPTLS_CACERT="$dest"
  export LDAPTLS_REQCERT="$TLS_REQCERT"

  update-ca-trust extract >/dev/null 2>&1 || update-ca-trust >/dev/null 2>&1 || true
  write_openldap_client_conf

  ok "Certificate chain saved to $dest"
}

install_provided_cert() {
  local dest="/etc/pki/ca-trust/source/anchors/${HOST}-manual.pem"

  [[ -s "$CA_FILE" ]] || die "CA file not found or empty: $CA_FILE"

  info "Installing provided CA/cert: $CA_FILE"
  install -m 0644 "$CA_FILE" "$dest"

  LDAP_TLS_CACERT="$dest"
  export LDAPTLS_CACERT="$dest"
  export LDAPTLS_REQCERT="$TLS_REQCERT"

  update-ca-trust extract >/dev/null 2>&1 || update-ca-trust >/dev/null 2>&1 || true
  write_openldap_client_conf

  ok "Installed CA/cert to $dest"
}

bind_test_for_mode() {
  local mode="$1"

  set_transport_vars "$mode"
  info "Testing LDAP bind over ${LDAP_URI}"

  LDAPTLS_REQCERT="$TLS_REQCERT" \
  LDAPTLS_CACERT="$LDAP_TLS_CACERT" \
  ldapsearch -LLL \
    -o nettimeout=5 \
    -x -H "$LDAP_URI" $LDAP_TLS_SWITCH \
    -D "$BIND_DN" -w "$BIND_SECRET" \
    -b "$BASE_DN" -s base \
    '(objectClass=*)' dn >/dev/null
}

select_working_transport() {
  local -a candidates=()

  case "$TLS_MODE" in
    ldaps)
      candidates=("ldaps")
      ;;
    starttls)
      candidates=("starttls")
      ;;
    auto)
      nc -z -w2 "$HOST" 636 >/dev/null 2>&1 && candidates+=("ldaps")
      nc -z -w2 "$HOST" 389 >/dev/null 2>&1 && candidates+=("starttls")
      ;;
    *)
      die "--tls-mode must be one of: auto|ldaps|starttls"
      ;;
  esac

  [[ ${#candidates[@]} -gt 0 ]] || die "Neither LDAPS 636 nor LDAP 389 is reachable on $HOST"

  for mode in "${candidates[@]}"; do
    info "Trying transport candidate: $mode"

    if [[ -n "$CA_FILE" ]]; then
      install_provided_cert
    else
      if [[ "$FETCH_CERT" == "yes" ]]; then
        if ! fetch_cert_for_mode "$mode"; then
          if [[ "$TLS_REQCERT" == "demand" ]]; then
            warn "Could not fetch a certificate chain for $mode"
            continue
          else
            warn "Could not fetch a certificate chain for $mode; continuing because tls-reqcert=${TLS_REQCERT}"
            LDAP_TLS_CACERT="/etc/pki/tls/certs/ca-bundle.crt"
          fi
        fi
      else
        if [[ "$TLS_REQCERT" == "demand" ]]; then
          die "No --ca-file provided and --fetch-cert is disabled while tls-reqcert=demand"
        fi
        LDAP_TLS_CACERT="/etc/pki/tls/certs/ca-bundle.crt"
      fi
    fi

    if bind_test_for_mode "$mode"; then
      set_transport_vars "$mode"
      ok "Selected LDAP transport: uri=$LDAP_URI starttls=$LDAP_STARTTLS port=$LDAP_PORT"
      return 0
    fi

    warn "Bind test failed for $mode, trying next candidate."
  done

  die "Could not complete a successful LDAP bind over any requested transport."
}

check_test_user_attrs() {
  [[ -n "$TEST_USER" ]] || return 0

  info "Checking LDAP attributes for test user: $TEST_USER"

  local out
  out="$(
    LDAPTLS_REQCERT="$TLS_REQCERT" \
    LDAPTLS_CACERT="$LDAP_TLS_CACERT" \
    ldapsearch -LLL \
      -o nettimeout=5 \
      -x -H "$LDAP_URI" $LDAP_TLS_SWITCH \
      -D "$BIND_DN" -w "$BIND_SECRET" \
      -b "$USER_OU" \
      "(mail=$TEST_USER)" \
      dn cn uid mail uidNumber gidNumber homeDirectory loginShell objectClass memberOf 2>/dev/null || true
  )"

  if [[ -z "$out" ]]; then
    warn "No LDAP entry found for test user mail=$TEST_USER"
    return 0
  fi

  echo "$out"
  grep -q '^uidNumber: ' <<<"$out" || warn "User $TEST_USER has no uidNumber. SSSD identity lookup needs it."
  grep -q '^gidNumber: ' <<<"$out" || warn "User $TEST_USER has no gidNumber. SSSD identity lookup needs it."
}

write_sssd_conf() {
  local services="nss, pam"
  local access_provider="permit"
  local access_extra=""

  if [[ "$SSH_KEYS" == "yes" ]]; then
    services="nss, pam, ssh"
  fi

  case "$ACCESS_MODE" in
    permit)
      access_provider="permit"
      ;;
    simple)
      access_provider="simple"
      access_extra=$'\n'"simple_allow_groups = ${ACCESS_GROUPS}"
      ;;
    *)
      die "--access-mode must be simple or permit"
      ;;
  esac

  info "Writing /etc/sssd/sssd.conf"

  cat > /etc/sssd/sssd.conf <<EOF
[sssd]
services = ${services}
domains = ${DOMAIN}

[nss]
homedir_substring = /home
entry_negative_timeout = ${NEGATIVE_TTL}

[pam]

[domain/${DOMAIN}]
id_provider = ldap
auth_provider = ldap
access_provider = ${access_provider}${access_extra}

cache_credentials = True
enumerate = False
entry_cache_user_timeout = ${CACHE_USER_TTL}
entry_cache_group_timeout = ${CACHE_GROUP_TTL}

ldap_uri = ${LDAP_URI}
ldap_id_use_start_tls = ${LDAP_STARTTLS}
ldap_tls_reqcert = ${TLS_REQCERT}
ldap_tls_cacert = ${LDAP_TLS_CACERT}
ldap_referrals = false
ldap_network_timeout = 3
ldap_id_mapping = false

ldap_schema = rfc2307bis
ldap_search_base = ${BASE_DN}
ldap_user_search_base = ${USER_OU}
ldap_group_search_base = ${GROUP_BASE}
ldap_group_member = member

ldap_user_name = mail
ldap_user_email = mail
ldap_user_uid_number = uidNumber
ldap_user_gid_number = gidNumber
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell

re_expression = (?P<name>.+)

ldap_default_bind_dn = ${BIND_DN}
ldap_default_authtok_type = password
ldap_default_authtok = ${BIND_SECRET}

use_fully_qualified_names = False
fallback_homedir = /home/%u
default_shell = /bin/bash
EOF

  if [[ "$SSH_KEYS" == "yes" ]]; then
    echo "ldap_user_ssh_public_key = sshPublicKey" >> /etc/sssd/sssd.conf
  fi

  chmod 600 /etc/sssd/sssd.conf
  chown root:root /etc/sssd/sssd.conf
  command -v restorecon >/dev/null 2>&1 && restorecon -Rv /etc/sssd >/dev/null 2>&1 || true

  ok "sssd.conf written."
}

configure_authselect_and_sshd() {
  info "Configuring authselect and oddjob"
  authselect select sssd with-mkhomedir --force
  systemctl enable --now oddjobd >/dev/null 2>&1 || true

  info "Configuring sshd"
  install -d -m 0755 /etc/ssh/sshd_config.d
  cat > /etc/ssh/sshd_config.d/99-sssd.conf <<'EOF'
UsePAM yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
LogLevel VERBOSE
EOF

  /usr/sbin/sshd -t
  systemctl restart sshd
  ok "sshd configured."
}

restart_sssd() {
  info "Validating SSSD config"
  sssctl config-check

  info "Restarting SSSD"
  systemctl enable --now sssd >/dev/null 2>&1 || true
  sss_cache -E >/dev/null 2>&1 || true
  rm -rf /var/lib/sss/mc/* >/dev/null 2>&1 || true

  if ! systemctl restart sssd; then
    systemctl status sssd --no-pager -l || true
    journalctl -u sssd -n 100 --no-pager || true
    die "SSSD failed to start."
  fi

  sleep 1
  bold "== sssctl domain-status =="
  sssctl domain-status "$DOMAIN" || true
}

configure_sudoers() {
  [[ "$ENABLE_SUDOERS" == "yes" ]] || return 0

  info "Adding linux-admins to sudoers"
  printf '%%linux-admins ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-linux-admins-nopasswd
  chmod 440 /etc/sudoers.d/10-linux-admins-nopasswd
  visudo -cf /etc/sudoers.d/10-linux-admins-nopasswd >/dev/null
  ok "Sudoers updated."
}

quick_checks() {
  [[ -n "$TEST_USER" ]] || return 0

  info "Quick checks for ${TEST_USER}"
  echo
  bold "== getent/id '${TEST_USER}' =="
  getent passwd "$TEST_USER" || true
  id "$TEST_USER" || true
  echo
  bold "== sssctl user-checks '${TEST_USER}' =="
  sssctl user-checks "$TEST_USER" || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --base-dn) BASE_DN="$2"; shift 2 ;;
    --user-ou) USER_OU="$2"; shift 2 ;;
    --group-base) GROUP_BASE="$2"; shift 2 ;;
    --bind-dn) BIND_DN="$2"; shift 2 ;;
    --access-group) ACCESS_GROUPS="$2"; shift 2 ;;
    --access-mode) ACCESS_MODE="$2"; shift 2 ;;
    --ssh-ldap-keys) SSH_KEYS="yes"; shift ;;
    --ca-file) CA_FILE="$2"; shift 2 ;;
    --fetch-cert) FETCH_CERT="$2"; shift 2 ;;
    --tls-mode) TLS_MODE="$2"; shift 2 ;;
    --tls-reqcert) TLS_REQCERT="$2"; shift 2 ;;
    --cache-user-ttl) CACHE_USER_TTL="$2"; shift 2 ;;
    --cache-group-ttl) CACHE_GROUP_TTL="$2"; shift 2 ;;
    --negative-ttl) NEGATIVE_TTL="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --test-user) TEST_USER="$2"; shift 2 ;;
    --enable-sudoers) ENABLE_SUDOERS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$HOST" && -n "$DOMAIN" && -n "$BASE_DN" && -n "$USER_OU" && -n "$GROUP_BASE" && -n "$BIND_DN" ]] || {
  usage
  die "Missing required arguments."
}

[[ "$TLS_REQCERT" =~ ^(allow|demand|never)$ ]] || die "--tls-reqcert must be allow, demand, or never"
[[ $EUID -eq 0 ]] || die "Run as root."

# Only require commands that should exist before package install
require_cmd dnf
require_cmd sed
require_cmd awk
require_cmd systemctl

bold "Log: $LOG"
info "Config: host=$HOST, domain=$DOMAIN, tls-mode=$TLS_MODE, tls-reqcert=$TLS_REQCERT, access-mode=$ACCESS_MODE, mode=$MODE"

info "Installing required packages"
dnf -y install \
  sssd sssd-tools sssd-ldap authselect oddjob oddjob-mkhomedir \
  openldap-clients openssl ca-certificates nmap-ncat sudo >/dev/null
ok "Packages installed."

# Require commands after packages are installed
require_cmd openssl
require_cmd ldapsearch
require_cmd nc
require_cmd authselect
require_cmd sssctl
require_cmd visudo

echo "Bind secret for $BIND_DN"
echo "Use the Authentik service account token here."
read -rsp "Enter bind secret: " BIND_SECRET
echo
read -rsp "Re-enter bind secret: " BIND_SECRET_2
echo
[[ "$BIND_SECRET" == "$BIND_SECRET_2" ]] || die "Bind secrets do not match."
unset BIND_SECRET_2

select_working_transport
check_test_user_attrs

if [[ "$MODE" == "check" ]]; then
  ok "Check mode completed successfully. Log: $LOG"
  exit 0
fi

write_sssd_conf
configure_authselect_and_sshd
restart_sssd
configure_sudoers
quick_checks

ok "Done. Log: $LOG"
echo
bold "Notes:"
echo " - LDAP transport: ${LDAP_URI}"
echo " - Email login is enabled via ldap_user_name = mail"
echo " - TLS_REQCERT mode: ${TLS_REQCERT}"
echo " - SSH with: ssh -l 'user@example.com' <host>"
echo " - If lookup still fails, compare journalctl -u sssd and sssctl config-check between hosts"