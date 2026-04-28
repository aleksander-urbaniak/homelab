#!/usr/bin/env bash
set -euo pipefail

# ===== Config you can override via env =====
PVE_USER="${PVE_USER:-prometheus@pam}"
PVE_TOKEN_NAME="${PVE_TOKEN_NAME:-exporter}"
: "${PVE_TOKEN_VALUE:?Set PVE_TOKEN_VALUE to the token secret (export PVE_TOKEN_VALUE=...)}"

# Exporter listen address
EXPORTER_LISTEN="${EXPORTER_LISTEN:-0.0.0.0:9221}"

# Disable TLS verification to PVE API (set true if you have trusted certs)
PVE_VERIFY_SSL="${PVE_VERIFY_SSL:-false}"

# Re-apply read-only ACL directly to the token (safe/idempotent)
ENSURE_ACL="${ENSURE_ACL:-true}"

# Paths
VENV_DIR="${VENV_DIR:-/opt/prometheus-pve-exporter-venv}"
CONFIG_DIR="${CONFIG_DIR:-/etc/prometheus}"
CONFIG_FILE="${CONFIG_DIR}/pve.yml"
SERVICE_FILE="/etc/systemd/system/prometheus-pve-exporter.service"

log(){ echo "==> $*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

command -v pveum >/dev/null 2>&1 || die "Run this on a Proxmox VE node (missing pveum)."

TOKEN_ID="${PVE_USER}!${PVE_TOKEN_NAME}"

# Optional: ensure the token has read-only at / (covers Sys.Audit)
if [ "${ENSURE_ACL}" = "true" ]; then
  log "Ensuring ${TOKEN_ID} has PVEAuditor on /"
  pveum acl modify / -token "${TOKEN_ID}" -role PVEAuditor || true
fi

# Install exporter into a venv
log "Installing dependencies"
apt-get update -y
apt-get install -y python3-venv python3-pip

log "Creating virtualenv at ${VENV_DIR}"
python3 -m venv "${VENV_DIR}"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
pip install --upgrade pip
pip install prometheus-pve-exporter
deactivate

# Config
log "Writing ${CONFIG_FILE}"
mkdir -p "${CONFIG_DIR}"
cat > "${CONFIG_FILE}" <<EOF
default:
  user: ${PVE_USER}
  token_name: "${PVE_TOKEN_NAME}"
  token_value: "${PVE_TOKEN_VALUE}"
  verify_ssl: ${PVE_VERIFY_SSL}
EOF
chmod 600 "${CONFIG_FILE}"

# Systemd unit
log "Writing ${SERVICE_FILE}"
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Prometheus Proxmox VE Exporter
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=${VENV_DIR}/bin/pve_exporter \\
  --config.file=${CONFIG_FILE} \\
  --web.listen-address=${EXPORTER_LISTEN}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

log "Enabling and starting service"
systemctl daemon-reload
systemctl enable --now prometheus-pve-exporter

# Health check (running on-node so /pve should work without ?target=)
log "Health check"
set +e
curl -sk "http://${EXPORTER_LISTEN}/pve" | head -n 5 | sed 's/^/    /'
RC=$?
set -e
if [ $RC -ne 0 ]; then
  echo "WARN: curl check failed; check logs: journalctl -u prometheus-pve-exporter -n 200 --no-pager"
else
  echo "OK: exporter responded. Add this node (port 9221) to Prometheus."
fi
