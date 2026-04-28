#!/usr/bin/env bash
set -euo pipefail

# TUI wizard for creating an Uptime Kuma push monitor.
# Notes:
# - Monitor type is always "push".
# - Authentication uses the Uptime Kuma user account flow.
# - If the account has TOTP enabled, the wizard asks for the current code.

APP_TITLE="Uptime Kuma Push Monitor"
BACKTITLE="Homelab Linux Scripts"
DEFAULT_HEARTBEAT="60s"
DEFAULT_TRIES="3"
DEFAULT_RETRY_INTERVAL="60s"
DEFAULT_RESEND="0"
DEFAULT_UPSIDE_DOWN="no"
DEFAULT_NAME="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf 'host')"
UI_IMPL=""
DIALOG_BIN=""
PYTHON_BIN=""
PKG_MGR=""
PKG_REFRESHED="0"
CRON_SERVICE_NAME=""
GENERATED_SCRIPT_PATH=""
GENERATED_SCRIPT_NAME=""
GENERATED_CRON_TAG=""
SERVICE_SELECTION_RAW=""
CUSTOM_SERVICE_INPUT=""
SELECTED_SERVICES=()
NOTIFICATION_SELECTION_RAW=""
SELECTED_NOTIFICATION_IDS=()

SERVICE_PRESETS=(
  "wazuh-agent|Wazuh Agent"
  "zabbix-agent2|Zabbix Agent 2"
  "node-exporter|Prometheus Node Exporter"
  "docker|Docker Engine"
  "k3s|K3s Server"
  "k3s-agent|K3s Agent"
  "k3s-admin|K3s Admin"
  "nfs|NFS Generic Alias"
  "nfs-server|NFS Server"
  "nfs-kernel-server|NFS Kernel Server"
  "sshd|OpenSSH Server"
  "ssh|OpenSSH Server Alias"
)

cleanup() {
  stty sane >/dev/null 2>&1 || true
}

trap cleanup EXIT

clear_screen() {
  if command -v clear >/dev/null 2>&1; then
    clear
  else
    printf '\033c'
  fi
}

cancelled() {
  clear_screen
  echo "[*] Wizard cancelled."
  exit 1
}

trim_value() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "[-] ${hint}"
    exit 1
  fi
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[-] Please run this script as root."
    exit 1
  fi
}

detect_pkg_mgr() {
  if [[ -n "${PKG_MGR}" ]]; then
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
  elif command -v zypper >/dev/null 2>&1; then
    PKG_MGR="zypper"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
  else
    echo "[-] Could not detect a supported package manager."
    exit 1
  fi
}

refresh_package_index_if_needed() {
  if [[ "${PKG_REFRESHED}" == "1" ]]; then
    return
  fi

  case "${PKG_MGR}" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      ;;
    pacman)
      pacman -Sy --noconfirm
      ;;
  esac

  PKG_REFRESHED="1"
}

install_packages() {
  detect_pkg_mgr
  refresh_package_index_if_needed

  case "${PKG_MGR}" in
    apt)
      apt-get install -y "$@"
      ;;
    dnf)
      dnf install -y "$@"
      ;;
    yum)
      yum install -y "$@"
      ;;
    zypper)
      zypper --non-interactive install "$@"
      ;;
    pacman)
      pacman -S --noconfirm "$@"
      ;;
    *)
      echo "[-] Unsupported package manager: ${PKG_MGR}"
      exit 1
      ;;
  esac
}

ensure_ui_dependency() {
  if command -v whiptail >/dev/null 2>&1; then
    return
  fi

  if command -v dialog >/dev/null 2>&1; then
    return
  fi

  echo "[*] Installing a TUI package for this host..."
  detect_pkg_mgr

  case "${PKG_MGR}" in
    apt)
      install_packages whiptail
      ;;
    dnf|yum|zypper|pacman)
      install_packages dialog
      ;;
    *)
      echo "[-] Could not determine which TUI package to install."
      exit 1
      ;;
  esac
}

ensure_cron_ready() {
  detect_pkg_mgr

  if ! command -v crontab >/dev/null 2>&1; then
    echo "[*] Installing cron support..."
    case "${PKG_MGR}" in
      apt)
        install_packages cron
        ;;
      dnf|yum|zypper|pacman)
        install_packages cronie
        ;;
      *)
        echo "[-] Unable to install cron automatically on this platform."
        exit 1
        ;;
    esac
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files crond.service --no-legend 2>/dev/null | grep -q '^crond\.service'; then
      CRON_SERVICE_NAME="crond"
    elif systemctl list-unit-files cron.service --no-legend 2>/dev/null | grep -q '^cron\.service'; then
      CRON_SERVICE_NAME="cron"
    fi

    if [[ -n "${CRON_SERVICE_NAME}" ]]; then
      systemctl enable --now "${CRON_SERVICE_NAME}" >/dev/null 2>&1 || true
    fi
  fi
}

ensure_curl_ready() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  echo "[*] Installing curl..."
  install_packages curl
}

init_ui() {
  ensure_ui_dependency

  if command -v whiptail >/dev/null 2>&1; then
    UI_IMPL="whiptail"
    DIALOG_BIN="whiptail"
  elif command -v dialog >/dev/null 2>&1; then
    UI_IMPL="dialog"
    DIALOG_BIN="dialog"
  else
    echo "[-] Please install 'whiptail' or 'dialog' first."
    exit 1
  fi
}

msg_box() {
  local text="$1"
  "${DIALOG_BIN}" \
    --backtitle "${BACKTITLE}" \
    --title "${APP_TITLE}" \
    --msgbox "${text}" 18 78 \
    < /dev/tty > /dev/tty 2>&1
}

capture_dialog_value() {
  local mode="$1"
  shift
  local output_file=""
  local output=""
  local rc=0

  output_file="$(mktemp)"

  if [[ "${UI_IMPL}" == "whiptail" ]]; then
    set +e
    "${DIALOG_BIN}" \
      --backtitle "${BACKTITLE}" \
      --title "${APP_TITLE}" \
      "${mode}" "$@" \
      < /dev/tty > /dev/tty 2> "${output_file}"
    rc=$?
    set -e
  else
    set +e
    "${DIALOG_BIN}" \
      --backtitle "${BACKTITLE}" \
      --title "${APP_TITLE}" \
      --stdout \
      "${mode}" "$@" \
      < /dev/tty > "${output_file}" 2> /dev/tty
    rc=$?
    set -e
  fi

  output="$(cat "${output_file}")"
  rm -f "${output_file}"

  if [[ ${rc} -ne 0 ]]; then
    cancelled
  fi

  printf '%s' "${output}"
}

input_box() {
  local text="$1"
  local default_value="${2-}"
  capture_dialog_value --inputbox "${text}" 18 78 "${default_value}"
}

yesno_box() {
  local text="$1"
  local default_no="${2-no}"
  local rc=0

  set +e
  "${DIALOG_BIN}" \
    --backtitle "${BACKTITLE}" \
    --title "${APP_TITLE}" \
    $( [[ "${default_no}" == "yes" ]] && printf '%s' '--defaultno' ) \
    --yesno "${text}" 18 78 \
    < /dev/tty > /dev/tty 2>&1
  rc=$?
  set -e

  if [[ ${rc} -gt 1 ]]; then
    cancelled
  fi

  return "${rc}"
}

menu_box() {
  local text="$1"
  shift
  capture_dialog_value --menu "${text}" 22 86 12 "$@"
}

checklist_box() {
  local text="$1"
  shift
  capture_dialog_value --checklist "${text}" 24 90 14 "$@"
}

run_with_progress() {
  local title="$1"
  shift
  local log_file=""
  local status_file=""
  local progress=5
  local command_rc=0

  log_file="$(mktemp)"
  status_file="$(mktemp)"

  (
    set +e
    "$@" >"${log_file}" 2>&1
    printf '%s' "$?" > "${status_file}"
  ) &
  local worker_pid=$!

  {
    while kill -0 "${worker_pid}" >/dev/null 2>&1; do
      printf '%s\n' "${progress}"
      printf 'XXX\n'
      printf '%s\n\nPlease wait...\n' "${title}"
      printf 'XXX\n'
      if (( progress < 95 )); then
        progress=$((progress + 5))
      fi
      sleep 1
    done

    wait "${worker_pid}" 2>/dev/null || true
    printf '100\n'
    printf 'XXX\n'
    printf '%s\n\nDone.\n' "${title}"
    printf 'XXX\n'
  } | "${DIALOG_BIN}" \
        --backtitle "${BACKTITLE}" \
        --title "${APP_TITLE}" \
        --gauge "${title}" 12 78 0

  if [[ -f "${status_file}" ]]; then
    command_rc="$(cat "${status_file}")"
  fi

  if [[ "${command_rc}" != "0" ]]; then
    msg_box "${title}

The command failed.

Last output:
$(tail -n 15 "${log_file}")"
    rm -f "${log_file}" "${status_file}"
    return 1
  fi

  rm -f "${log_file}" "${status_file}"
  return 0
}

normalize_seconds() {
  local raw
  local number
  local unit

  raw="$(trim_value "${1}")"

  if [[ -z "${raw}" ]]; then
    return 1
  fi

  if [[ "${raw}" =~ ^[0-9]+$ ]]; then
    printf '%s' "${raw}"
    return 0
  fi

  if [[ "${raw}" =~ ^([0-9]+)[[:space:]]*([sSmMhHdD])$ ]]; then
    number="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case "${unit}" in
      s|S) printf '%s' "${number}" ;;
      m|M) printf '%s' "$((number * 60))" ;;
      h|H) printf '%s' "$((number * 3600))" ;;
      d|D) printf '%s' "$((number * 86400))" ;;
      *) return 1 ;;
    esac
    return 0
  fi

  return 1
}

require_integer() {
  local label="$1"
  local value="$2"

  if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
    msg_box "${label} must be a whole number."
    return 1
  fi

  return 0
}

slugify() {
  local raw="$1"
  printf '%s' "${raw,,}" | sed 's/[^a-z0-9._-]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

service_is_known() {
  local service_name="$1"

  if systemctl list-unit-files --type=service --all --no-legend "${service_name}" 2>/dev/null | grep -q .; then
    return 0
  fi

  if [[ "${service_name}" != *.service ]] && systemctl list-unit-files --type=service --all --no-legend "${service_name}.service" 2>/dev/null | grep -q .; then
    return 0
  fi

  case "${service_name}" in
    nfs)
      systemctl list-unit-files --type=service --all --no-legend nfs-server.service nfs-kernel-server.service 2>/dev/null | grep -q .
      return
      ;;
  esac

  return 1
}

append_service_if_missing() {
  local service_name="$1"
  local existing=""

  for existing in "${SELECTED_SERVICES[@]}"; do
    if [[ "${existing}" == "${service_name}" ]]; then
      return
    fi
  done

  SELECTED_SERVICES+=("${service_name}")
}

append_notification_id_if_missing() {
  local notification_id="$1"
  local existing=""

  for existing in "${SELECTED_NOTIFICATION_IDS[@]}"; do
    if [[ "${existing}" == "${notification_id}" ]]; then
      return
    fi
  done

  SELECTED_NOTIFICATION_IDS+=("${notification_id}")
}

parse_custom_services() {
  local raw="$1"
  local normalized=""
  local token=""

  normalized="$(printf '%s' "${raw}" | tr ',' ' ')"
  for token in ${normalized}; do
    token="$(trim_value "${token}")"
    [[ -z "${token}" ]] && continue

    if [[ ! "${token}" =~ ^[A-Za-z0-9_.@-]+$ ]]; then
      msg_box "Invalid service name: ${token}

Use systemd unit names such as docker, docker.service, k3s, wazuh-agent, or zabbix-agent2."
      return 1
    fi

    append_service_if_missing "${token}"
  done

  return 0
}

ensure_python_runtime() {
  local base_python=""
  local data_home=""
  local app_home=""
  local venv_dir=""

  if command -v python3 >/dev/null 2>&1; then
    base_python="$(command -v python3)"
  elif command -v python >/dev/null 2>&1; then
    base_python="$(command -v python)"
  else
    echo "[-] Please install Python 3 first."
    exit 1
  fi

  data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
  app_home="${data_home}/uptime-kuma-push-monitor-tui"
  venv_dir="${app_home}/.venv"

  mkdir -p "${app_home}"

  if [[ ! -x "${venv_dir}/bin/python3" ]]; then
    if ! run_with_progress "Preparing a small Python runtime for the Uptime Kuma API helper." \
      "${base_python}" -m venv "${venv_dir}"; then
      echo "[-] Failed to create Python virtual environment. Install the venv package first (for example: python3-venv)." >&2
      exit 1
    fi
  fi

  PYTHON_BIN="${venv_dir}/bin/python3"
  if [[ ! -x "${PYTHON_BIN}" ]]; then
    PYTHON_BIN="${venv_dir}/bin/python"
  fi

  if ! "${PYTHON_BIN}" -c "import socketio" >/dev/null 2>&1; then
    if ! run_with_progress "Upgrading pip for the Uptime Kuma helper environment." \
      "${PYTHON_BIN}" -m pip install --upgrade pip; then
      echo "[-] Failed to upgrade pip inside ${venv_dir}." >&2
      exit 1
    fi
    if ! run_with_progress "Installing the Python Socket.IO dependency used to talk to Uptime Kuma." \
      "${PYTHON_BIN}" -m pip install "python-socketio[client]>=5,<6"; then
      echo "[-] Failed to install python-socketio. Check internet access and pip output." >&2
      exit 1
    fi
  fi
}

run_python_helper() {
  local action="$1"

  "${PYTHON_BIN}" - "${action}" <<'PY'
import os
import secrets
import string
import sys
import threading
from urllib.parse import urlparse

import socketio


def fail(message: str, exit_code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(exit_code)


def env_required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        fail(f"Missing required environment variable: {name}")
    return value


def env_int(name: str, default: int = 0) -> int:
    value = os.environ.get(name, "").strip()
    if value == "":
        return default
    try:
        return int(value)
    except ValueError as exc:
        fail(f"{name} must be an integer: {exc}")


def env_bool(name: str, default: bool = False) -> bool:
    value = os.environ.get(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def validate_url(raw_url: str) -> str:
    parsed = urlparse(raw_url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        fail("Uptime Kuma URL must include http:// or https:// and a hostname.")
    return raw_url.rstrip("/")


def parse_tags(raw_tags: str):
    results = []
    if not raw_tags.strip():
        return results

    for chunk in raw_tags.split(","):
        item = chunk.strip()
        if not item:
            continue

        if ":" in item:
            name, value = item.split(":", 1)
        else:
            name, value = item, ""

        name = name.strip()
        value = value.strip()

        if not name:
            fail("Tag names cannot be empty.")

        results.append({"name": name, "value": value})

    return results


def pick_tag_color(name: str) -> str:
    palette = [
        "#4ade80",
        "#60a5fa",
        "#f59e0b",
        "#f472b6",
        "#22d3ee",
        "#a78bfa",
        "#fb7185",
        "#34d399",
    ]
    return palette[sum(ord(char) for char in name) % len(palette)]


def random_push_token(length: int = 32) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


class KumaClient:
    def __init__(self, base_url: str):
        self.base_url = validate_url(base_url)
        self.sio = socketio.Client(
            logger=False,
            engineio_logger=False,
            reconnection=False,
            request_timeout=20,
        )
        self.monitor_list_event = threading.Event()
        self.monitor_list_payload = {}
        self.notification_list_event = threading.Event()
        self.notification_list_payload = []

        @self.sio.on("monitorList")
        def _monitor_list(data):
            self.monitor_list_payload = data or {}
            self.monitor_list_event.set()

        @self.sio.on("notificationList")
        def _notification_list(data):
            self.notification_list_payload = data or []
            self.notification_list_event.set()

    def connect(self) -> None:
        self.sio.connect(self.base_url, transports=["websocket", "polling"], wait_timeout=20)

    def disconnect(self) -> None:
        try:
            if self.sio.connected:
                self.sio.disconnect()
        except Exception:
            pass

    def login_by_token(self, token: str) -> None:
        response = self.sio.call("loginByToken", token, timeout=20)
        if not response or not response.get("ok"):
            raise RuntimeError(response.get("msg", "Token login failed"))

    def login_with_password(self, username: str, password: str, token: str = "") -> str:
        response = self.sio.call(
            "login",
            {"username": username, "password": password, "token": token},
            timeout=20,
        )
        if response.get("tokenRequired"):
            raise RuntimeError("__TOTP_REQUIRED__")
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", "Username/password login failed"))
        token = response.get("token")
        if not token:
            raise RuntimeError("Login succeeded but Uptime Kuma did not return a session token.")
        return token

    def get_groups(self):
        self.monitor_list_event.clear()
        response = self.sio.call("getMonitorList", timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", "Failed to fetch monitor list"))
        if not self.monitor_list_event.wait(timeout=20):
            raise RuntimeError("Timed out while waiting for the monitor list.")

        groups = []
        for monitor_id, monitor in (self.monitor_list_payload or {}).items():
            if monitor.get("type") == "group":
                groups.append(
                    {
                        "id": int(monitor_id),
                        "name": monitor.get("name", f"group-{monitor_id}"),
                    }
                )

        groups.sort(key=lambda item: item["name"].lower())
        return groups

    def get_tags(self):
        response = self.sio.call("getTags", timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", "Failed to fetch tags"))
        return response.get("tags", [])

    def get_notifications(self):
        if not self.notification_list_event.wait(timeout=20):
            raise RuntimeError("Timed out while waiting for the notification list.")
        return self.notification_list_payload or []

    def add_monitor(self, payload):
        response = self.sio.call("add", payload, timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", "Failed to create monitor"))
        return int(response["monitorID"])

    def add_tag(self, name: str, color: str):
        response = self.sio.call("addTag", {"name": name, "color": color}, timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", f"Failed to create tag '{name}'"))
        return response["tag"]

    def add_monitor_tag(self, tag_id: int, monitor_id: int, value: str):
        response = self.sio.call("addMonitorTag", [tag_id, monitor_id, value], timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", f"Failed to assign tag {tag_id}"))

    def resume_monitor(self, monitor_id: int):
        response = self.sio.call("resumeMonitor", monitor_id, timeout=20)
        if not response.get("ok"):
            raise RuntimeError(response.get("msg", f"Failed to resume monitor {monitor_id}"))


def build_group_payload(name: str, interval: int):
    return {
        "type": "group",
        "name": name,
        "parent": None,
        "description": "",
        "interval": interval,
        "retryInterval": interval,
        "resendInterval": 0,
        "maxretries": 0,
        "notificationIDList": {},
        "accepted_statuscodes": ["200-299"],
        "ignoreTls": False,
        "upsideDown": False,
        "maxredirects": 10,
        "active": False,
        "conditions": [],
    }


def build_push_payload(parent_id):
    interval = env_int("KUMA_INTERVAL")
    retry_interval = env_int("KUMA_RETRY_INTERVAL")
    resend_interval = env_int("KUMA_RESEND_INTERVAL")
    max_retries = env_int("KUMA_MAX_RETRIES")
    name = env_required("KUMA_MONITOR_NAME")
    description = os.environ.get("KUMA_DESCRIPTION", "")
    notification_ids = os.environ.get("KUMA_NOTIFICATION_IDS", "").strip()
    push_token = random_push_token()
    notification_id_list = {}

    if notification_ids:
        for raw_id in notification_ids.split(","):
            item = raw_id.strip()
            if not item:
                continue
            notification_id_list[str(int(item))] = True

    payload = {
        "type": "push",
        "name": name,
        "parent": parent_id,
        "description": description,
        "interval": interval,
        "retryInterval": retry_interval,
        "resendInterval": resend_interval,
        "maxretries": max_retries,
        "notificationIDList": notification_id_list,
        "accepted_statuscodes": ["200-299"],
        "ignoreTls": False,
        "upsideDown": env_bool("KUMA_UPSIDE_DOWN"),
        "maxredirects": 10,
        "active": True,
        "pushToken": push_token,
        "conditions": [],
    }
    return payload, push_token


def main():
    action = sys.argv[1]
    base_url = env_required("KUMA_URL")
    client = KumaClient(base_url)

    try:
        client.connect()

        if action == "auth":
            mode = env_required("KUMA_AUTH_MODE")
            if mode == "token":
                token = env_required("KUMA_AUTH_SECRET")
                client.login_by_token(token)
                print(token)
                return
            if mode == "password":
                username = env_required("KUMA_USERNAME")
                password = env_required("KUMA_PASSWORD")
                totp_token = os.environ.get("KUMA_TOTP_TOKEN", "").strip()
                token = client.login_with_password(username, password, totp_token)
                print(token)
                return
            fail(f"Unsupported auth mode: {mode}")

        token = env_required("KUMA_SESSION_TOKEN")
        client.login_by_token(token)

        if action == "list-groups":
            for group in client.get_groups():
                print(f"{group['id']}\t{group['name']}")
            return

        if action == "list-notifications":
            for notification in client.get_notifications():
                notification_id = notification.get("id")
                if notification_id is None:
                    continue
                name = (notification.get("name") or f"notification-{notification_id}").replace("\t", " ")
                is_default = 1 if notification.get("isDefault") else 0
                active = 1 if notification.get("active", True) else 0
                print(f"{notification_id}\t{name}\t{is_default}\t{active}")
            return

        if action == "create-push-monitor":
            interval = env_int("KUMA_INTERVAL")
            group_mode = os.environ.get("KUMA_GROUP_MODE", "none").strip()
            parent_id = None

            if group_mode == "existing":
                parent_id = env_int("KUMA_GROUP_ID")
            elif group_mode == "create":
                group_name = env_required("KUMA_GROUP_NAME")
                group_id = client.add_monitor(build_group_payload(group_name, interval))
                parent_id = group_id
            elif group_mode != "none":
                fail(f"Unsupported group mode: {group_mode}")

            payload, push_token = build_push_payload(parent_id)
            monitor_id = client.add_monitor(payload)

            existing_tags = client.get_tags()
            tags_by_name = {
                tag["name"].strip().lower(): tag
                for tag in existing_tags
                if tag.get("name")
            }

            for tag in parse_tags(os.environ.get("KUMA_TAGS", "")):
                existing = tags_by_name.get(tag["name"].lower())
                if existing is None:
                    existing = client.add_tag(tag["name"], pick_tag_color(tag["name"]))
                    tags_by_name[tag["name"].lower()] = existing
                client.add_monitor_tag(int(existing["id"]), monitor_id, tag["value"])

            if group_mode == "create" and parent_id is not None:
                client.resume_monitor(parent_id)

            push_url = f"{base_url}/api/push/{push_token}?status=up&msg=OK&ping="
            print(f"{monitor_id}\t{push_url}")
            return

        fail(f"Unsupported action: {action}")
    except Exception as exc:
        fail(str(exc))
    finally:
        client.disconnect()


if __name__ == "__main__":
    main()
PY
}

prompt_url() {
  local value=""

  while true; do
    value="$(input_box "General

Monitor Type: Push

Enter the Uptime Kuma base URL that will receive the new monitor.

Example:
https://status.example.com" "https://")"
    value="$(trim_value "${value}")"

    if [[ -z "${value}" ]]; then
      msg_box "Uptime Kuma URL cannot be empty."
      continue
    fi

    if [[ ! "${value}" =~ ^https?://.+$ ]]; then
      msg_box "Use a full URL such as https://status.example.com"
      continue
    fi

    printf '%s' "${value%/}"
    return
  done
}

prompt_totp_token() {
  local value=""

  while true; do
    value="$(input_box "Two-Factor Authentication

Enter the current TOTP code from your authenticator app.

Use the 6-digit code that is currently shown for your Uptime Kuma account." "")"
    value="$(trim_value "${value}")"

    if [[ -z "${value}" ]]; then
      msg_box "The TOTP code cannot be empty."
      continue
    fi

    if [[ ! "${value}" =~ ^[0-9]{6}$ ]]; then
      msg_box "Enter a 6-digit TOTP code."
      continue
    fi

    printf '%s' "${value}"
    return
  done
}

run_password_auth() {
  local username="$1"
  local password="$2"
  local totp_token="${3-}"

  KUMA_URL="${KUMA_URL}" \
  KUMA_AUTH_MODE="password" \
  KUMA_USERNAME="${username}" \
  KUMA_PASSWORD="${password}" \
  KUMA_TOTP_TOKEN="${totp_token}" \
  run_python_helper auth 2>&1
}

prompt_username_password_fallback() {
  local username=""
  local password=""
  local totp_token=""
  local auth_result=""
  local auth_rc=0

  while true; do
    username="$(input_box "Authentication

Enter the Uptime Kuma username to use for monitor creation." "")"
    username="$(trim_value "${username}")"
    if [[ -z "${username}" ]]; then
      msg_box "Username cannot be empty."
      continue
    fi

    password="$(input_box "Authentication

Enter the password for ${username}.

This field is intentionally visible so paste works reliably." "")"
    if [[ -z "${password}" ]]; then
      msg_box "Password cannot be empty."
      continue
    fi

    set +e
    auth_result="$(run_password_auth "${username}" "${password}")"
    auth_rc=$?
    set -e

    if [[ ${auth_rc} -eq 0 ]]; then
      printf '%s' "$(trim_value "${auth_result}")"
      return
    fi

    if [[ "$(trim_value "${auth_result}")" == "__TOTP_REQUIRED__" ]]; then
      while true; do
        totp_token="$(prompt_totp_token)"

        set +e
        auth_result="$(run_password_auth "${username}" "${password}" "${totp_token}")"
        auth_rc=$?
        set -e

        if [[ ${auth_rc} -eq 0 ]]; then
          printf '%s' "$(trim_value "${auth_result}")"
          return
        fi

        if yesno_box "TOTP authentication failed.

${auth_result}

Try another TOTP code for ${username}?"; then
          continue
        fi

        break
      done
      continue
    fi

    msg_box "Username/password login failed.

${auth_result}"
  done
}

authenticate() {
  prompt_username_password_fallback
}

prompt_name() {
  local value=""
  while true; do
    value="$(input_box "General

Friendly Name for the monitor.

Leave the default if you want to use this host's hostname." "${DEFAULT_NAME}")"
    value="$(trim_value "${value}")"
    if [[ -z "${value}" ]]; then
      msg_box "Monitor name cannot be empty."
      continue
    fi
    printf '%s' "${value}"
    return
  done
}

prompt_seconds() {
  local label="$1"
  local default_value="$2"
  local value=""
  local normalized=""

  while true; do
    value="$(input_box "${label}

You can enter seconds directly or use suffixes like 60s, 5m, 1h." "${default_value}")"
    value="$(trim_value "${value}")"

    if ! normalized="$(normalize_seconds "${value}")"; then
      msg_box "Please enter a valid duration, for example: 60, 60s, 5m, 1h"
      continue
    fi

    printf '%s' "${normalized}"
    return
  done
}

prompt_integer() {
  local label="$1"
  local default_value="$2"
  local value=""

  while true; do
    value="$(input_box "${label}" "${default_value}")"
    value="$(trim_value "${value}")"

    if require_integer "${label}" "${value}"; then
      printf '%s' "${value}"
      return
    fi
  done
}

prompt_upside_down() {
  if yesno_box "Upside Down Mode

If enabled, Uptime Kuma will flip the monitor status.

Choose 'Yes' to enable upside down mode." "yes"; then
    printf 'yes'
  else
    printf 'no'
  fi
}

fetch_groups() {
  KUMA_URL="${KUMA_URL}" \
  KUMA_SESSION_TOKEN="${SESSION_TOKEN}" \
  run_python_helper list-groups
}

fetch_notifications() {
  KUMA_URL="${KUMA_URL}" \
  KUMA_SESSION_TOKEN="${SESSION_TOKEN}" \
  run_python_helper list-notifications
}

prompt_group() {
  local group_rows=""
  local choice=""
  local group_id=""
  local group_name=""
  local -a menu_items

  if ! group_rows="$(fetch_groups 2>&1)"; then
    msg_box "Failed to load existing monitor groups.

${group_rows}"
    exit 1
  fi

  menu_items=(
    "__none__" "No monitor group"
    "__create__" "Create a new monitor group"
  )

  while IFS=$'\t' read -r existing_id existing_name; do
    [[ -z "${existing_id:-}" ]] && continue
    menu_items+=("${existing_id}" "${existing_name}")
  done <<< "${group_rows}"

  choice="$(menu_box "Monitor Group

Choose an existing group, create a new one, or leave the monitor ungrouped." "${menu_items[@]}")"

  case "${choice}" in
    "__none__")
      GROUP_MODE="none"
      GROUP_ID=""
      GROUP_NAME=""
      ;;
    "__create__")
      while true; do
        group_name="$(input_box "Monitor Group

Enter the new monitor group name.")"
        group_name="$(trim_value "${group_name}")"
        if [[ -z "${group_name}" ]]; then
          msg_box "Group name cannot be empty."
          continue
        fi
        GROUP_MODE="create"
        GROUP_ID=""
        GROUP_NAME="${group_name}"
        break
      done
      ;;
    *)
      GROUP_MODE="existing"
      GROUP_ID="${choice}"
      GROUP_NAME="$(printf '%s\n' "${group_rows}" | awk -F '\t' -v id="${choice}" '$1 == id { print $2; exit }')"
      ;;
  esac
}

prompt_description() {
  local value=""
  value="$(input_box "Description

Optional description to show on the Uptime Kuma dashboard.

You can leave this empty." "")"
  printf '%s' "${value}"
}

prompt_tags() {
  local value=""
  value="$(input_box "Tags

Optional comma-separated tags.

Format:
linux, prod, role:web, site:home

Use name:value if you want a tag value. Leave empty to skip." "")"
  printf '%s' "$(trim_value "${value}")"
}

prompt_notifications() {
  local notification_rows=""
  local notification_id=""
  local notification_name=""
  local is_default=""
  local active=""
  local default_state=""
  local label=""
  local -a checklist_items=()
  local -a selected_from_ui=()

  SELECTED_NOTIFICATION_IDS=()

  if ! notification_rows="$(fetch_notifications 2>&1)"; then
    msg_box "Failed to load notification channels.

${notification_rows}"
    exit 1
  fi

  while IFS=$'\t' read -r notification_id notification_name is_default active; do
    [[ -z "${notification_id:-}" ]] && continue
    [[ "${active}" != "1" ]] && continue

    default_state="OFF"
    label="${notification_name}"
    if [[ "${is_default}" == "1" ]]; then
      default_state="ON"
      label="${label} (default)"
    fi

    checklist_items+=("${notification_id}" "${label}" "${default_state}")
  done <<< "${notification_rows}"

  if [[ ${#checklist_items[@]} -eq 0 ]]; then
    msg_box "No active notification channels are configured in Uptime Kuma.

The monitor can still be created, but it will have no notifications attached and may appear muted until you assign one later."
    return
  fi

  NOTIFICATION_SELECTION_RAW="$(checklist_box "Notifications

Select which Uptime Kuma notification channels should be attached to this monitor.

Default notification channels are pre-selected." "${checklist_items[@]}")"
  NOTIFICATION_SELECTION_RAW="${NOTIFICATION_SELECTION_RAW//\"/}"

  if [[ -n "${NOTIFICATION_SELECTION_RAW}" ]]; then
    read -r -a selected_from_ui <<< "${NOTIFICATION_SELECTION_RAW}"
    for notification_id in "${selected_from_ui[@]}"; do
      append_notification_id_if_missing "${notification_id}"
    done
  fi

  if [[ ${#SELECTED_NOTIFICATION_IDS[@]} -eq 0 ]]; then
    if ! yesno_box "No notification channels are selected.

The monitor will still work, but it will not send alerts and may appear muted.

Continue without notifications?"; then
      prompt_notifications
    fi
  fi
}

prompt_services() {
  local preset=""
  local service_name=""
  local service_label=""
  local detected_state=""
  local -a checklist_items=()
  local -a selected_from_ui=()

  SELECTED_SERVICES=()

  for preset in "${SERVICE_PRESETS[@]}"; do
    service_name="${preset%%|*}"
    service_label="${preset#*|}"

    if service_is_known "${service_name}"; then
      detected_state="ON"
      service_label="${service_label} (detected)"
    else
      detected_state="OFF"
      service_label="${service_label} (not detected)"
    fi

    checklist_items+=("${service_name}" "${service_label}" "${detected_state}")
  done

  SERVICE_SELECTION_RAW="$(checklist_box "Services

Select the systemd services this host should verify before sending a push heartbeat.

Detected services are pre-selected. You can keep them, remove them, or add custom units in the next step." "${checklist_items[@]}")"
  SERVICE_SELECTION_RAW="${SERVICE_SELECTION_RAW//\"/}"

  if [[ -n "${SERVICE_SELECTION_RAW}" ]]; then
    read -r -a selected_from_ui <<< "${SERVICE_SELECTION_RAW}"
    for service_name in "${selected_from_ui[@]}"; do
      append_service_if_missing "${service_name}"
    done
  fi

  CUSTOM_SERVICE_INPUT="$(input_box "Custom Services

Optionally add more systemd service names separated by commas or spaces.

Examples:
nfs-server
docker.service
my-custom-agent" "")"
  CUSTOM_SERVICE_INPUT="$(trim_value "${CUSTOM_SERVICE_INPUT}")"

  if ! parse_custom_services "${CUSTOM_SERVICE_INPUT}"; then
    prompt_services
    return
  fi

  if [[ ${#SELECTED_SERVICES[@]} -eq 0 ]]; then
    msg_box "Select at least one service to monitor."
    prompt_services
    return
  fi
}

create_monitor() {
  local notification_ids_csv=""

  if [[ ${#SELECTED_NOTIFICATION_IDS[@]} -gt 0 ]]; then
    notification_ids_csv="$(IFS=,; printf '%s' "${SELECTED_NOTIFICATION_IDS[*]}")"
  fi

  KUMA_URL="${KUMA_URL}" \
  KUMA_SESSION_TOKEN="${SESSION_TOKEN}" \
  KUMA_GROUP_MODE="${GROUP_MODE}" \
  KUMA_GROUP_ID="${GROUP_ID}" \
  KUMA_GROUP_NAME="${GROUP_NAME}" \
  KUMA_MONITOR_NAME="${MONITOR_NAME}" \
  KUMA_INTERVAL="${HEARTBEAT_SECONDS}" \
  KUMA_RETRY_INTERVAL="${RETRY_INTERVAL_SECONDS}" \
  KUMA_RESEND_INTERVAL="${RESEND_TIMES}" \
  KUMA_MAX_RETRIES="${TRIES}" \
  KUMA_UPSIDE_DOWN="${UPSIDE_DOWN}" \
  KUMA_DESCRIPTION="${DESCRIPTION}" \
  KUMA_TAGS="${TAGS}" \
  KUMA_NOTIFICATION_IDS="${notification_ids_csv}" \
  run_python_helper create-push-monitor
}

generate_service_array_literal() {
  local service_name=""

  for service_name in "${SELECTED_SERVICES[@]}"; do
    printf "  '%s'\n" "${service_name}"
  done
}

generate_local_checker_script() {
  local push_url="$1"
  local heartbeat_seconds="$2"
  local checker_push_endpoint=""
  local checker_state_dir=""
  local checker_state_file=""
  local checker_lock_file=""
  local checker_services_literal=""
  local services_summary=""

  GENERATED_SCRIPT_NAME="$(slugify "${MONITOR_NAME}")"
  [[ -z "${GENERATED_SCRIPT_NAME}" ]] && GENERATED_SCRIPT_NAME="uptime-kuma-service-check"
  GENERATED_SCRIPT_NAME="uptime-kuma-${GENERATED_SCRIPT_NAME}.sh"
  GENERATED_SCRIPT_PATH="/root/scripts/${GENERATED_SCRIPT_NAME}"
  GENERATED_CRON_TAG="uptime-kuma-monitor:${GENERATED_SCRIPT_NAME}"

  mkdir -p /root/scripts
  checker_push_endpoint="${push_url%%\?*}"
  checker_state_dir="/root/scripts/.uptime-kuma-state"
  checker_state_file="${checker_state_dir}/${GENERATED_SCRIPT_NAME}.last_run"
  checker_lock_file="${checker_state_dir}/${GENERATED_SCRIPT_NAME}.lock"
  checker_services_literal="$(generate_service_array_literal)"
  services_summary="$(printf '%s, ' "${SELECTED_SERVICES[@]}")"
  services_summary="${services_summary%, }"

  cat > "${GENERATED_SCRIPT_PATH}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

PUSH_ENDPOINT='${checker_push_endpoint}'
HEARTBEAT_SECONDS='${heartbeat_seconds}'
STATE_DIR='${checker_state_dir}'
STATE_FILE='${checker_state_file}'
LOCK_FILE='${checker_lock_file}'
SERVICES=(
${checker_services_literal}
)

mkdir -p "\${STATE_DIR}"
exec 9>"\${LOCK_FILE}"
if ! flock -n 9; then
  exit 0
fi

resolve_service_unit() {
  local raw="\$1"
  local candidate=""
  local -a candidates=()

  candidates+=("\${raw}")
  if [[ "\${raw}" != *.service ]]; then
    candidates+=("\${raw}.service")
  fi

  case "\${raw}" in
    nfs)
      candidates+=("nfs-server.service" "nfs-kernel-server.service")
      ;;
    docker)
      candidates+=("docker.service")
      ;;
    wazuh-agent)
      candidates+=("wazuh-agent.service")
      ;;
    zabbix-agent2)
      candidates+=("zabbix-agent2.service")
      ;;
    k3s)
      candidates+=("k3s.service")
      ;;
    k3s-agent)
      candidates+=("k3s-agent.service")
      ;;
    k3s-admin)
      candidates+=("k3s-admin.service")
      ;;
    ssh)
      candidates+=("ssh.service" "sshd.service")
      ;;
    sshd)
      candidates+=("sshd.service" "ssh.service")
      ;;
  esac

  for candidate in "\${candidates[@]}"; do
    if systemctl list-unit-files --type=service --all --no-legend "\${candidate}" 2>/dev/null | grep -q .; then
      printf '%s' "\${candidate}"
      return 0
    fi
  done

  printf '%s' "\${candidates[0]}"
  return 0
}

send_push() {
  local status="\$1"
  local message="\$2"
  local ping_ms="\$3"

  curl -fsS -G "\${PUSH_ENDPOINT}" \
    --data-urlencode "status=\${status}" \
    --data-urlencode "msg=\${message}" \
    --data-urlencode "ping=\${ping_ms}" \
    >/dev/null
}

run_single_check() {
  local start_ms end_ms duration_ms
  local service_name resolved_unit
  local -a failed_services=()
  local status="up"
  local message="All monitored services are active"

  start_ms="\$(date +%s%3N)"

  for service_name in "\${SERVICES[@]}"; do
    resolved_unit="\$(resolve_service_unit "\${service_name}")"
    if ! systemctl is-active --quiet "\${resolved_unit}" 2>/dev/null; then
      failed_services+=("\${service_name}")
    fi
  done

  end_ms="\$(date +%s%3N)"
  duration_ms="\$((end_ms - start_ms))"

  if [[ \${#failed_services[@]} -gt 0 ]]; then
    status="down"
    message="Inactive services: \$(printf '%s, ' "\${failed_services[@]}")"
    message="\${message%, }"
  fi

  send_push "\${status}" "\${message}" "\${duration_ms}"
}

should_run_now() {
  local now last_run
  now="\$(date +%s)"

  if [[ ! -f "\${STATE_FILE}" ]]; then
    return 0
  fi

  last_run="\$(cat "\${STATE_FILE}" 2>/dev/null || printf '0')"
  [[ -z "\${last_run}" ]] && last_run=0

  if (( now - last_run >= HEARTBEAT_SECONDS )); then
    return 0
  fi

  return 1
}

mark_run() {
  date +%s > "\${STATE_FILE}"
}

main() {
  local started_at now
  started_at="\$(date +%s)"

  while true; do
    if should_run_now; then
      run_single_check
      mark_run
    fi

    now="\$(date +%s)"
    if (( now - started_at >= 59 )); then
      break
    fi

    sleep 1
  done
}

main "\$@"
EOF

  chmod 700 "${GENERATED_SCRIPT_PATH}"
}

install_or_update_cronjob() {
  local existing_crontab=""
  local new_crontab=""
  local cron_line=""

  ensure_cron_ready

  cron_line="* * * * * ${GENERATED_SCRIPT_PATH} >/dev/null 2>&1 # ${GENERATED_CRON_TAG}"
  existing_crontab="$(crontab -l 2>/dev/null || true)"
  new_crontab="$(printf '%s\n' "${existing_crontab}" | sed "/# ${GENERATED_CRON_TAG//\//\\/}\$/d")"
  new_crontab="$(printf '%s\n%s\n' "${new_crontab}" "${cron_line}" | sed '/^[[:space:]]*$/d')"
  printf '%s\n' "${new_crontab}" | crontab -
}

main() {
  local create_result=""
  local monitor_id=""
  local push_url=""
  local summary_group=""
  local summary_notifications=""
  local summary_services=""

  require_root
  require_cmd systemctl "Please install systemd/systemctl first."
  init_ui
  require_cmd awk "Please install awk first."
  ensure_curl_ready
  ensure_python_runtime

  msg_box "General

Monitor Type: Push

This wizard creates an Uptime Kuma push monitor and returns the Push URL you can call from cron, systemd timers, or your own scripts."

  KUMA_URL="$(prompt_url)"
  SESSION_TOKEN="$(authenticate)"

  MONITOR_NAME="$(prompt_name)"
  HEARTBEAT_SECONDS="$(prompt_seconds "Heartbeat Interval

How often should the host send a push heartbeat?" "${DEFAULT_HEARTBEAT}")"
  TRIES="$(prompt_integer "Retries

Maximum retries before the service is marked as down and a notification is sent." "${DEFAULT_TRIES}")"
  RETRY_INTERVAL_SECONDS="$(prompt_seconds "Heartbeat Retry Interval

How long Uptime Kuma should wait before retrying after a failed heartbeat." "${DEFAULT_RETRY_INTERVAL}")"
  RESEND_TIMES="$(prompt_integer "Resend Notification if Down X Times Consecutively

Use 0 to disable repeated resend notifications." "${DEFAULT_RESEND}")"
  UPSIDE_DOWN="$(prompt_upside_down)"
  prompt_group
  DESCRIPTION="$(prompt_description)"
  TAGS="$(prompt_tags)"
  prompt_notifications
  prompt_services

  case "${GROUP_MODE}" in
    none) summary_group="None" ;;
    create) summary_group="Create: ${GROUP_NAME}" ;;
    existing) summary_group="Existing: ${GROUP_NAME} (#${GROUP_ID})" ;;
    *) summary_group="Unknown" ;;
  esac

  summary_services="$(printf '%s, ' "${SELECTED_SERVICES[@]}")"
  summary_services="${summary_services%, }"
  if [[ ${#SELECTED_NOTIFICATION_IDS[@]} -gt 0 ]]; then
    summary_notifications="$(printf '%s, ' "${SELECTED_NOTIFICATION_IDS[@]}")"
    summary_notifications="${summary_notifications%, }"
  else
    summary_notifications="<none>"
  fi

  if ! yesno_box "Review

Monitor Type: Push
Friendly Name: ${MONITOR_NAME}
Heartbeat Interval: ${HEARTBEAT_SECONDS}s
Retries: ${TRIES}
Heartbeat Retry Interval: ${RETRY_INTERVAL_SECONDS}s
Resend Notification: ${RESEND_TIMES}
Upside Down Mode: ${UPSIDE_DOWN}
Monitor Group: ${summary_group}
Description: ${DESCRIPTION:-<empty>}
Tags: ${TAGS:-<none>}
Notification IDs: ${summary_notifications}
Services: ${summary_services}

The script will also create:
/root/scripts/<generated-checker>
and install/update a root cron job for it.

Create this monitor now?"; then
    cancelled
  fi

  if ! create_result="$(create_monitor 2>&1)"; then
    msg_box "Monitor creation failed.

${create_result}"
    exit 1
  fi

  monitor_id="$(printf '%s' "${create_result}" | awk -F '\t' 'NR==1 { print $1 }')"
  push_url="$(printf '%s' "${create_result}" | awk -F '\t' 'NR==1 { print $2 }')"
  generate_local_checker_script "${push_url}" "${HEARTBEAT_SECONDS}"
  install_or_update_cronjob

  msg_box "Success

Monitor ID: ${monitor_id}
Friendly Name: ${MONITOR_NAME}
Push URL:
${push_url}

Local checker script:
${GENERATED_SCRIPT_PATH}

Selected services:
${summary_services}

Notification IDs:
${summary_notifications}

Cron job:
* * * * * ${GENERATED_SCRIPT_PATH}

The generated checker handles the ${HEARTBEAT_SECONDS}-second schedule internally."

  clear_screen
  printf 'Monitor ID: %s\nPush URL: %s\nChecker Script: %s\n' "${monitor_id}" "${push_url}" "${GENERATED_SCRIPT_PATH}"
}

main "$@"
