#!/usr/bin/env bash
set -euo pipefail

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.9.1}"
NODE_EXPORTER_USER="${NODE_EXPORTER_USER:-nodeusr}"
NODE_EXPORTER_BIN="${NODE_EXPORTER_BIN:-/usr/local/bin/node_exporter}"

SUDO=""
if [[ "${EUID:-0}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Error: must run as root (or have sudo installed)." >&2
    exit 1
  fi
fi

detect_distro() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${ID:-unknown}"
    return 0
  fi
  echo "unknown"
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "unsupported" ;;
  esac
}

install_packages() {
  local distro="$1"
  if [[ "$distro" == "debian" || "$distro" == "ubuntu" ]]; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y wget tar ca-certificates
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    $SUDO dnf makecache
    $SUDO dnf install -y wget tar ca-certificates
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    $SUDO yum makecache
    $SUDO yum install -y wget tar ca-certificates
    return 0
  fi

  echo "Error: unsupported distro/package manager (need apt, dnf, or yum)." >&2
  exit 1
}

ensure_user() {
  local username="$1"
  if id -u "$username" >/dev/null 2>&1; then
    return 0
  fi

  local nologin_shell="/usr/sbin/nologin"
  if [[ ! -x "$nologin_shell" ]] && [[ -x /sbin/nologin ]]; then
    nologin_shell="/sbin/nologin"
  fi

  $SUDO useradd --system --no-create-home --user-group --shell "$nologin_shell" "$username"
}

install_node_exporter() {
  local version="$1"
  local arch="$2"
  local bin_path="$3"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  local url="https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-${arch}.tar.gz"
  local tarball="${tmp}/node_exporter-${version}.linux-${arch}.tar.gz"

  $SUDO wget -qO "$tarball" "$url"
  tar -xzf "$tarball" -C "$tmp"

  $SUDO mv "${tmp}/node_exporter-${version}.linux-${arch}/node_exporter" "$bin_path"
  $SUDO chown root:root "$bin_path"
  $SUDO chmod 0755 "$bin_path"
}

write_systemd_unit() {
  local user="$1"
  local bin_path="$2"

  $SUDO tee /etc/systemd/system/node_exporter.service >/dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=${user}
Group=${user}
Type=simple
ExecStart=${bin_path}

[Install]
WantedBy=multi-user.target
EOF

  $SUDO systemctl daemon-reload
  $SUDO systemctl enable --now node_exporter
}

configure_firewall() {
  # Debian/Ubuntu (ufw)
  if command -v ufw >/dev/null 2>&1; then
    if $SUDO ufw status >/dev/null 2>&1; then
      $SUDO ufw allow 9100/tcp >/dev/null 2>&1 || true
    fi
  fi

  # RHEL-ish (firewalld)
  if command -v firewall-cmd >/dev/null 2>&1; then
    if $SUDO firewall-cmd --state >/dev/null 2>&1; then
      $SUDO firewall-cmd --add-port=9100/tcp --permanent >/dev/null 2>&1 || true
      $SUDO firewall-cmd --reload >/dev/null 2>&1 || true
    fi
  fi
}

maybe_restorecon() {
  if command -v restorecon >/dev/null 2>&1; then
    if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce 2>/dev/null || true)" != "Disabled" ]]; then
      $SUDO restorecon -v "$NODE_EXPORTER_BIN" || true
    fi
  fi
}

main() {
  local distro arch
  distro="$(detect_distro)"
  arch="$(detect_arch)"

  if [[ "$arch" == "unsupported" ]]; then
    echo "Error: unsupported architecture: $(uname -m)" >&2
    exit 1
  fi

  install_packages "$distro"
  ensure_user "$NODE_EXPORTER_USER"
  install_node_exporter "$NODE_EXPORTER_VERSION" "$arch" "$NODE_EXPORTER_BIN"
  maybe_restorecon
  write_systemd_unit "$NODE_EXPORTER_USER" "$NODE_EXPORTER_BIN"
  configure_firewall

  $SUDO systemctl --no-pager status node_exporter || true
  "$NODE_EXPORTER_BIN" --version || true
}

main "$@"
