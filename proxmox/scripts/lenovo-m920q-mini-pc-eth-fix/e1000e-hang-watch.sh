#!/usr/bin/env bash
set -Eeuo pipefail

IFACE="${IFACE:-eno1}"
RETRY_INTERVAL_SEC="${RETRY_INTERVAL_SEC:-5}"
LOCK="/run/e1000e-watch.lock"

log() {
    logger -t e1000e-watch -- "$*"
}

link_up() {
    if [[ -r /sys/class/net/$IFACE/carrier ]]; then
        [[ "$(cat /sys/class/net/$IFACE/carrier)" = "1" ]]
    else
        ethtool "$IFACE" 2>/dev/null | grep -q "Link detected: yes"
    fi
}

bounce_once() {
    ip link set "$IFACE" down || true
    ethtool -s "$IFACE" autoneg off speed 1000 duplex full 2>/dev/null || true
    sleep 1
    ethtool -s "$IFACE" autoneg on 2>/dev/null || true
    ip link set "$IFACE" up || true
    ethtool --set-eee "$IFACE" eee off 2>/dev/null || true
    ethtool -K "$IFACE" tso off gso off gro off 2>/dev/null || true
}

heal_until_up() {
    exec 9>"$LOCK"

    if ! flock -n 9; then
        log "heal skipped (already running)"
        return 0
    fi

    log "HANG detected on ${IFACE} -> restarting every ${RETRY_INTERVAL_SEC}s until link is up"

    attempt=0
    while true; do
        attempt=$((attempt + 1))
        log "bounce attempt $attempt"

        bounce_once
        sleep "$RETRY_INTERVAL_SEC"

        if link_up; then
            ip -br link show "$IFACE" | logger -t e1000e-watch
            ethtool "$IFACE" | egrep "Speed|Duplex|Auto-negotiation|Link detected" | logger -t e1000e-watch
            log "recovery complete (link up after attempt $attempt)"
            break
        fi

        log "link still down after attempt $attempt; retrying in ${RETRY_INTERVAL_SEC}s"
    done
}

match_line() {
    local line="$1"

    [[ "$line" =~ e1000e.*${IFACE}.*Detected[[:space:]]+Hardware[[:space:]]+Unit[[:space:]]+Hang ]] && return 0
    [[ "$line" =~ NETDEV[[:space:]]+WATCHDOG.*${IFACE} ]] && return 0
    [[ "$line" =~ TX[[:space:]]+timeout.*${IFACE} ]] && return 0

    return 1
}

stdbuf -oL -eL journalctl -kf -n0 -o cat | while IFS= read -r line; do
    if match_line "$line"; then
        log "trigger: $line"
        heal_until_up
    fi
done
