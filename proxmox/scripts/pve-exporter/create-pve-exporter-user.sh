#!/usr/bin/env bash
set -euo pipefail

# ===== Config (override via env) ==============================================
PVE_USERNAME="${PVE_USERNAME:-prometheus}"
PVE_REALM="${PVE_REALM:-pam}"           # usually 'pve' or 'pam'
PVE_ROLE="${PVE_ROLE:-PVEAuditor}"      # read-only role
TOKEN_NAME="${TOKEN_NAME:-exporter}"    # token id
PRIVSEP="${PRIVSEP:-1}"                 # 1 = token privileges are separate (safer). 0 = inherit user's roles
ROTATE_TOKEN="${ROTATE_TOKEN:-false}"   # true = remove & recreate token to get a new secret

# Where to save the token secret (created on first add or on rotation)
SECRET_OUT="${SECRET_OUT:-/root/pve_exporter_token_${PVE_USERNAME}_${TOKEN_NAME}.secret}"

# =============================================================================
die(){ echo "ERROR: $*" >&2; exit 1; }
log(){ echo "==> $*"; }

command -v pveum >/dev/null 2>&1 || die "Run this on a Proxmox VE node (pveum not found)."

USER_ID="${PVE_USERNAME}@${PVE_REALM}"
TOKEN_ID="${USER_ID}!${TOKEN_NAME}"

# ---- Ensure user exists (idempotent) ----------------------------------------
if pveum user list | awk 'NR>1{print $1}' | grep -qx "${USER_ID}"; then
  log "User ${USER_ID} already exists"
else
  log "Creating user ${USER_ID}"
  # No password needed when using API tokens; this only creates the PVE account entry.
  pveum user add "${USER_ID}" --comment "Prometheus read-only user for metrics"
fi

# ---- (Optional) Assign read-only to the user as well ------------------------
# Not strictly required if PRIVSEP=1 and we set ACL on the token below; harmless otherwise.
log "Ensuring ${USER_ID} has ${PVE_ROLE} on /"
pveum acl modify / -user "${USER_ID}" -role "${PVE_ROLE}" || true

# ---- Handle token ------------------------------------------------------------
TOKEN_EXISTS=false
if pveum user token list "${USER_ID}" 2>/dev/null | awk 'NR>1{print $2}' | grep -qx "${TOKEN_NAME}"; then
  TOKEN_EXISTS=true
fi

if [[ "${ROTATE_TOKEN}" == "true" && "${TOKEN_EXISTS}" == "true" ]]; then
  log "ROTATE_TOKEN=true -> removing existing token ${TOKEN_ID}"
  pveum user token remove "${USER_ID}" "${TOKEN_NAME}" || true
  TOKEN_EXISTS=false
fi

if [[ "${TOKEN_EXISTS}" == "false" ]]; then
  log "Creating API token ${TOKEN_ID} (PRIVSEP=${PRIVSEP})"
  # Capture the secret printed once at creation time.
  OUT="$(pveum user token add "${USER_ID}" "${TOKEN_NAME}" --comment "Prometheus Exporter Token" --privsep "${PRIVSEP}")"
  SECRET="$(echo "${OUT}" | awk -F': ' '/value:/{print $2}' | tr -d ' \t\r\n')"
  if [[ -z "${SECRET}" ]]; then
    echo "${OUT}"
    die "Could not parse token secret. Shown above is the raw output. Save the secret manually."
  fi
  umask 177
  echo -n "${SECRET}" > "${SECRET_OUT}"
  umask 022
  log "Token secret saved to ${SECRET_OUT}"
else
  log "Token ${TOKEN_ID} already exists (secret cannot be shown again)."
fi

# ---- Ensure the token has read-only at / (required when PRIVSEP=1) ----------
# Using token-level ACL avoids needing PRIVSEP=0 and grants just enough rights.
log "Ensuring ${TOKEN_ID} has ${PVE_ROLE} on /"
pveum acl modify / -token "${TOKEN_ID}" -role "${PVE_ROLE}" || true

# ---- Show effective permissions (helpful sanity check) ----------------------
echo
log "Effective permissions at /:"
pveum user permissions "${USER_ID}" --path / || true
pveum user token permissions "${USER_ID}" "${TOKEN_NAME}" --path / || true

echo
log "Done."
if [[ -f "${SECRET_OUT}" ]]; then
  echo "Use the token in /etc/prometheus/pve.yml:"
  echo "  user: ${USER_ID}"
  echo "  token_name: \"${TOKEN_NAME}\""
  echo "  token_value: \"\$(cat ${SECRET_OUT})\""
fi

# Notes:
# - If you prefer the token to inherit the user's roles, run with PRIVSEP=0.
#   In that case, the user-level ACL above is sufficient, but keeping the
#   token-level ACL is harmless and keeps things explicit.
