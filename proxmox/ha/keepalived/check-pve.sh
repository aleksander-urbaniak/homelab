#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

TAG="keepalived-check-pve"

log_fail() {
    logger -t "$TAG" "CHECK FAILED: $1. Priority will be lowered."
    exit 1
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

port_open() {
    local host="$1"
    local port="$2"
    timeout 2 nc -z "$host" "$port" >/dev/null 2>&1
}

# 1. Core Proxmox health
systemctl is-active --quiet pve-cluster || log_fail "pve-cluster not active"

have_cmd pvecm || log_fail "pvecm command missing"
pvecm status 2>/dev/null | grep -Eq 'Quorate:\s+Yes' || log_fail "node is not quorate"

# 2. Proxmox API must actually be reachable
port_open 127.0.0.1 8006 || log_fail "Proxmox port 8006 closed (pveproxy not answering)"

# 3. Ceph check: only enforce if ceph-mgr is installed/enabled on this node
if systemctl list-unit-files 2>/dev/null | grep -q '^ceph-mgr@'; then
    if systemctl list-units --full -all 2>/dev/null | grep -q 'ceph-mgr@.*\.service'; then
        systemctl is-active --quiet 'ceph-mgr@*' || log_fail "ceph-mgr service not active"
        port_open 127.0.0.1 8003 || log_fail "Ceph mgr port 8003 closed on localhost"
    fi
fi

exit 0