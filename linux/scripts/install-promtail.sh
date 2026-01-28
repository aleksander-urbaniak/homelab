#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###############################################################

# Optional: pin a specific Promtail version, e.g. "v3.2.0"
# If empty, script will use the latest release from GitHub.
PROMTAIL_VERSION="${PROMTAIL_VERSION:-}"

INSTALL_DIR="/usr/local/bin"
PROMTAIL_BIN="${INSTALL_DIR}/promtail"
CONFIG_DIR="/etc/promtail"
CONFIG_FILE="${CONFIG_DIR}/promtail-config.yaml"
POSITIONS_DIR="/var/lib/promtail"
SERVICE_FILE="/etc/systemd/system/promtail.service"
PROMTAIL_USER="promtail"
PROMTAIL_GROUP="promtail"

#######################################################################

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[-] Please run as root (sudo)."
    exit 1
  fi
}

detect_pkg_mgr() {
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
  else
    echo "[-] Could not detect package manager (apt, dnf, yum)."
    exit 1
  fi
}

install_deps() {
  case "${PKG_MGR}" in
    apt)
      apt-get update -y
      apt-get install -y curl unzip
      ;;
    dnf)
      dnf install -y curl unzip
      ;;
    yum)
      yum install -y curl unzip
      ;;
  esac
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "${arch}" in
    x86_64|amd64)
      PROMTAIL_ARCH="amd64"
      ;;
    aarch64|arm64)
      PROMTAIL_ARCH="arm64"
      ;;
    *)
      echo "[-] Unsupported architecture: ${arch}"
      exit 1
      ;;
  esac
}

prompt_loki_url() {
  local input
  if [[ -n "${LOKI_URL:-}" ]]; then
    input="${LOKI_URL}"
  else
    echo "Enter Loki URL (base or push endpoint)."
    echo "Examples:"
    echo "  https://grafana-loki.example.com"
    echo "  https://grafana-loki.example.com/loki/api/v1/push"
    read -rp "Loki URL: " input
  fi

  # Trim whitespace
  input="$(echo "${input}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  if [[ -z "${input}" ]]; then
    echo "[-] Loki URL cannot be empty."
    exit 1
  fi

  # If user gave base URL, append /loki/api/v1/push
  if [[ "${input}" != *"/loki/api/v1/push" ]]; then
    input="${input%/}/loki/api/v1/push"
  fi

  LOKI_URL="${input}"
  echo "[*] Using Loki push URL: ${LOKI_URL}"
}

get_download_url() {
  if [[ -n "${PROMTAIL_VERSION}" ]]; then
    TAG="${PROMTAIL_VERSION}"
  else
    echo "[*] Detecting latest Promtail release from GitHub..."
    TAG="$(curl -s https://api.github.com/repos/grafana/loki/releases/latest \
      | grep '"tag_name"' | head -n1 | cut -d '"' -f4)"
    if [[ -z "${TAG}" ]]; then
      echo "[-] Failed to detect latest release tag from GitHub."
      exit 1
    fi
  fi

  DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/${TAG}/promtail-linux-${PROMTAIL_ARCH}.zip"
  echo "[*] Using Promtail release: ${TAG}"
  echo "[*] Download URL: ${DOWNLOAD_URL}"
}

download_promtail() {
  local tmp
  tmp="$(mktemp -d)"
  pushd "${tmp}" >/dev/null

  echo "[*] Downloading Promtail..."
  curl -fL -o promtail.zip "${DOWNLOAD_URL}"

  echo "[*] Unpacking..."
  unzip -q promtail.zip

  if [[ ! -f "promtail-linux-${PROMTAIL_ARCH}" ]]; then
    echo "[-] promtail binary not found after unzip."
    exit 1
  fi

  echo "[*] Installing to ${PROMTAIL_BIN}..."
  install -m 0755 "promtail-linux-${PROMTAIL_ARCH}" "${PROMTAIL_BIN}"

  popd >/dev/null
  rm -rf "${tmp}"
}

create_user() {
  if ! id -u "${PROMTAIL_USER}" >/dev/null 2>&1; then
    echo "[*] Creating user ${PROMTAIL_USER}..."
    useradd --system --no-create-home --shell /usr/sbin/nologin "${PROMTAIL_USER}"
  fi
}

write_config() {
  mkdir -p "${CONFIG_DIR}" "${POSITIONS_DIR}"
  chown -R "${PROMTAIL_USER}:${PROMTAIL_GROUP}" "${POSITIONS_DIR}"

  echo "[*] Writing config to ${CONFIG_FILE}..."
  cat > "${CONFIG_FILE}" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: ${POSITIONS_DIR}/positions.yaml

clients:
  - url: ${LOKI_URL}

scrape_configs:
  - job_name: varlogs-root
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          host: \${HOSTNAME}
          __path__: /var/log/*log

  - job_name: varlogs-subdirs
    static_configs:
      - targets: [localhost]
        labels:
          job: varlogs
          host: \${HOSTNAME}
          __path__: /var/log/*/*log
EOF

  chown "${PROMTAIL_USER}:${PROMTAIL_GROUP}" "${CONFIG_FILE}"
  chmod 0644 "${CONFIG_FILE}"
}

write_service() {
  echo "[*] Writing systemd service to ${SERVICE_FILE}..."
  cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Promtail log shipper
After=network-online.target
Wants=network-online.target

[Service]
User=${PROMTAIL_USER}
Group=${PROMTAIL_GROUP}
Type=simple
Environment=HOSTNAME=%H
ExecStart=${PROMTAIL_BIN} -log.level=info -config.expand-env=true -config.file=${CONFIG_FILE}
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
}

enable_service() {
  echo "[*] Enabling and starting promtail.service..."
  systemctl daemon-reload
  systemctl enable --now promtail.service
}

print_done() {
  echo
  echo "==============================================="
  echo "[+] Promtail installed and started!"
  echo
  echo "  Binary : ${PROMTAIL_BIN}"
  echo "  Config : ${CONFIG_FILE}"
  echo "  Service: promtail.service"
  echo
  echo "Using Loki push URL:"
  echo "  ${LOKI_URL}"
  echo
  echo "To check status:"
  echo "  systemctl status promtail"
  echo
  echo "To see Promtail logs:"
  echo "  journalctl -u promtail -f"
  echo "==============================================="
}

main() {
  require_root
  detect_pkg_mgr
  install_deps
  detect_arch
  prompt_loki_url
  get_download_url
  download_promtail
  create_user
  write_config
  write_service
  enable_service
  print_done
}

main "$@"
