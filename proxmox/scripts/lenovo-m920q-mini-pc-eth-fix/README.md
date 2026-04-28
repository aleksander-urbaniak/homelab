# 🖥️ Proxmox M920q: e1000e NIC Hardware Unit Hang Runbook, Fixes & Auto Heal

**Applies to:** Lenovo ThinkCentre M920q / Intel I219‑LM (e1000e), Proxmox (Debian-based).  
**Symptoms:** Node loses connectivity but `eno1`/`vmbr0` show *UP*; kernel logs spam:
```
e1000e ... eno1: Detected Hardware Unit Hang:
```
Often recovers after a link bounce or driver reset. Root causes frequently include Energy Efficient Ethernet (EEE) interactions and PCIe power states.

This folder also contains the exported watcher script [e1000e-hang-watch.sh](e1000e-hang-watch.sh). The runbook remains below as the operational reference.

---

## 0) TL;DR: What to do when it wedges (KVM runbook)

> Use this when you’ve lost network but still have KVM/ILO.

**Pause HA locally so you don’t get fenced (start them again in step 6):**
```bash
systemctl stop pve-ha-lrm pve-ha-crm watchdog-mux
systemctl stop corosync
```

**1) Triage**
```bash
journalctl -k -n 200 | egrep -i 'e1000e|NETDEV WATCHDOG|tx timeout|hang'
ethtool --show-eee eno1
ethtool -S eno1 | egrep -i 'tx_timeout|restart_queue|rx_errors|tx_errors|dropped'
```

**2) Quick kick (link renegotiation)**
```bash
# if eno1 sits under a bridge (vmbr0), bring the bridge down first:
ifdown vmbr0 2>/dev/null || true
ip link set eno1 down
ethtool -s eno1 autoneg off speed 1000 duplex full
sleep 1
ethtool -s eno1 autoneg on
ip link set eno1 up
ifup vmbr0 2>/dev/null || ip link set vmbr0 up

# re-apply mitigations (driver reloads can clear these)
ethtool --set-eee eno1 eee off
ethtool -K eno1 tso off gso off gro off 2>/dev/null || true
```

**3) If still stuck: driver reload**
```bash
ifdown vmbr0 2>/dev/null || true
ip link set eno1 down
modprobe -r e1000e; sleep 2; modprobe e1000e
ip link set eno1 up
ifup vmbr0 2>/dev/null || ip link set vmbr0 up
ethtool --set-eee eno1 eee off
```

**4) Optional: PCI function reset (if supported)**
```bash
BDF=$(readlink -f /sys/class/net/eno1/device | awk -F/ '{print $NF}')
echo 1 > /sys/bus/pci/devices/$BDF/reset 2>/dev/null || true
# fallback: unbind/rebind
echo "$BDF" > /sys/bus/pci/drivers/e1000e/unbind
sleep 2
echo "$BDF" > /sys/bus/pci/drivers/e1000e/bind
ip link set eno1 up
ifup vmbr0 2>/dev/null || ip link set vmbr0 up
ethtool --set-eee eno1 eee off
```

**5) Verify & rejoin cluster**
```bash
ping -c3 <GATEWAY_OR_PEER>
pvecm status
```
**6) Resume HA**
```bash
systemctl start corosync
systemctl start pve-ha-crm pve-ha-lrm watchdog-mux
ha-manager status
```

---

## 1) Make mitigations persistent (no reboot for EEE; reboot for GRUB flags)

**Disable EEE on the host (persist via `/etc/network/interfaces`):**
```bash
# Apply now
ethtool --set-eee eno1 eee off

# Persist (example stanza addition)
cat <<'EOF' >> /etc/network/interfaces
# ensure EEE remains off for eno1 at boot
pre-up /sbin/ethtool --set-eee eno1 eee off
EOF

ifreload -a
```

**Kernel flags (require reboot to take effect):**
```bash
# Safer PCIe + NIC power handling
sed -i 's/^GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="pcie_aspm=off e1000e.SmartPowerDownEnable=0"/' /etc/default/grub
update-grub
reboot
```

**Post-boot checks:**
```bash
# Kernel flags are active
cat /proc/cmdline | egrep 'pcie_aspm=off|e1000e.SmartPowerDownEnable=0'

# EEE stays off
ethtool --show-eee eno1

# No new “unit hang” spam this boot
journalctl -k -b | grep -i 'e1000e.*hang' || echo "OK: no hangs"

# Optional: watch for errors/timeouts
ethtool -S eno1 | egrep -i 'tx_timeout|restart_queue|rx_errors|tx_errors' || true
```

**Optional (only if hangs persist after above):**
- Add to GRUB: `intel_idle.max_cstate=1` → `update-grub` → reboot in a window.
- Keep BIOS/ME/NVM updated (Lenovo).

---

## 2) Auto‑heal watcher (retries every 5s until the link is up)

This service watches kernel logs for e1000e hang signatures and, on trigger, **bounces `eno1` every 5 seconds** until `Link detected: yes`. No PCI unbind/rebind.

### Install (script + systemd)
```bash
# /usr/local/sbin/e1000e-hang-watch.sh
cat >/usr/local/sbin/e1000e-hang-watch.sh <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
IFACE="${IFACE:-eno1}"
RETRY_INTERVAL_SEC="${RETRY_INTERVAL_SEC:-5}"
LOCK="/run/e1000e-watch.lock"
log(){ logger -t e1000e-watch -- "$*"; }
link_up(){ if [[ -r /sys/class/net/$IFACE/carrier ]]; then [[ "$(cat /sys/class/net/$IFACE/carrier)" = "1" ]]; else ethtool "$IFACE" 2>/dev/null | grep -q "Link detected: yes"; fi; }
bounce_once(){ ip link set "$IFACE" down || true; ethtool -s "$IFACE" autoneg off speed 1000 duplex full 2>/dev/null || true; sleep 1; ethtool -s "$IFACE" autoneg on 2>/dev/null || true; ip link set "$IFACE" up || true; ethtool --set-eee "$IFACE" eee off 2>/dev/null || true; ethtool -K "$IFACE" tso off gso off gro off 2>/dev/null || true; }
heal_until_up(){ exec 9>"$LOCK"; if ! flock -n 9; then log "heal skipped (already running)"; return 0; fi; log "HANG detected on ${IFACE} -> restarting every ${RETRY_INTERVAL_SEC}s until link is up"; attempt=0; while true; do attempt=$((attempt+1)); log "bounce attempt $attempt"; bounce_once; sleep "$RETRY_INTERVAL_SEC"; if link_up; then ip -br link show "$IFACE" | logger -t e1000e-watch; ethtool "$IFACE" | egrep "Speed|Duplex|Auto-negotiation|Link detected" | logger -t e1000e-watch; log "recovery complete (link up after attempt $attempt)"; break; else log "link still down after attempt $attempt; retrying in ${RETRY_INTERVAL_SEC}s"; fi; done; }
match_line(){ local line="$1"; [[ "$line" =~ e1000e.*${IFACE}.*Detected[[:space:]]+Hardware[[:space:]]+Unit[[:space:]]+Hang ]] && return 0; [[ "$line" =~ NETDEV[[:space:]]+WATCHDOG.*${IFACE} ]] && return 0; [[ "$line" =~ TX[[:space:]]+timeout.*${IFACE} ]] && return 0; return 1; }
stdbuf -oL -eL journalctl -kf -n0 -o cat | while IFS= read -r line; do if match_line "$line"; then log "trigger: $line"; heal_until_up; fi; done
EOF
chmod +x /usr/local/sbin/e1000e-hang-watch.sh

# /etc/systemd/system/e1000e-hang-watch.service
cat >/etc/systemd/system/e1000e-hang-watch.service <<'EOF'
[Unit]
Description=Auto-heal e1000e NIC hang by bouncing the link until up
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
Environment=IFACE=eno1
Environment=RETRY_INTERVAL_SEC=5
ExecStart=/usr/local/sbin/e1000e-hang-watch.sh
Restart=always
RestartSec=2
Nice=-5
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now e1000e-hang-watch.service
```

### Test
```bash
# simulate the kernel error and watch the service react
printf '<3>e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang:
' > /dev/kmsg
sleep 2
journalctl -u e1000e-hang-watch -b --no-pager -n 100
```

**Expected logs:**
- `trigger: … Detected Hardware Unit Hang`
- `HANG detected on eno1 -> restarting every 5s until link is up`
- `bounce attempt 1` (then 2, 3, … every ~5s until up)
- `recovery complete (link up after attempt X)` with speed/duplex snapshot.

### One‑liner (deploy to other nodes)
```bash
IFACE=eno1 RETRY_INTERVAL_SEC=5 bash -c 'set -euo pipefail;
cat >/usr/local/sbin/e1000e-hang-watch.sh <<'"'"'EOF'"'"'
#!/usr/bin/env bash
set -Eeuo pipefail
IFACE="${IFACE:-eno1}"
RETRY_INTERVAL_SEC="${RETRY_INTERVAL_SEC:-5}"
LOCK="/run/e1000e-watch.lock"
log(){ logger -t e1000e-watch -- "$*"; }
link_up(){ if [[ -r /sys/class/net/$IFACE/carrier ]]; then [[ "$(cat /sys/class/net/$IFACE/carrier)" = "1" ]]; else ethtool "$IFACE" 2>/dev/null | grep -q "Link detected: yes"; fi; }
bounce_once(){ ip link set "$IFACE" down || true; ethtool -s "$IFACE" autoneg off speed 1000 duplex full 2>/dev/null || true; sleep 1; ethtool -s "$IFACE" autoneg on 2>/dev/null || true; ip link set "$IFACE" up || true; ethtool --set-eee "$IFACE" eee off 2>/dev/null || true; ethtool -K "$IFACE" tso off gso off gro off 2>/dev/null || true; }
heal_until_up(){ exec 9>"$LOCK"; if ! flock -n 9; then log "heal skipped (already running)"; return 0; fi; log "HANG detected on ${IFACE} -> restarting every ${RETRY_INTERVAL_SEC}s until link is up"; attempt=0; while true; do attempt=$((attempt+1)); log "bounce attempt $attempt"; bounce_once; sleep "$RETRY_INTERVAL_SEC"; if link_up; then ip -br link show "$IFACE" | logger -t e1000e-watch; ethtool "$IFACE" | egrep "Speed|Duplex|Auto-negotiation|Link detected" | logger -t e1000e-watch; log "recovery complete (link up after attempt $attempt)"; break; else log "link still down after attempt $attempt; retrying in ${RETRY_INTERVAL_SEC}s"; fi; done; }
match_line(){ local line="$1"; [[ "$line" =~ e1000e.*${IFACE}.*Detected[[:space:]]+Hardware[[:space:]]+Unit[[:space:]]+Hang ]] && return 0; [[ "$line" =~ NETDEV[[:space:]]+WATCHDOG.*${IFACE} ]] && return 0; [[ "$line" =~ TX[[:space:]]+timeout.*${IFACE} ]] && return 0; return 1; }
stdbuf -oL -eL journalctl -kf -n0 -o cat | while IFS= read -r line; do if match_line "$line"; then log "trigger: $line"; heal_until_up; fi; done
EOF
chmod +x /usr/local/sbin/e1000e-hang-watch.sh
cat >/etc/systemd/system/e1000e-hang-watch.service <<EOF2
[Unit]
Description=Auto-heal e1000e NIC hang by bouncing the link until up
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
Environment=IFACE=${IFACE}
Environment=RETRY_INTERVAL_SEC=${RETRY_INTERVAL_SEC}
ExecStart=/usr/local/sbin/e1000e-hang-watch.sh
Restart=always
RestartSec=2
Nice=-5
[Install]
WantedBy=multi-user.target
EOF2
systemctl daemon-reload
systemctl enable --now e1000e-hang-watch.service
systemctl --no-pager -l status e1000e-hang-watch.service | sed -n "1,20p"
'
```

---

## 3) Switch‑side: disable EEE (802.3az)

Disabling EEE on the **switch port** that faces each node is the #1 external fix for these hangs.

**Examples:**

**Cisco IOS:**
```text
conf t
 interface Gi1/0/X
  power efficient-ethernet never
end
write mem
```

**Aruba/HP (AOS‑S/CX):**
```text
conf t
 interface 1/1/X
  no energy-efficient-ethernet
end
write memory
```

**MikroTik (ROS 7):**
```text
/interface/ethernet set [find name=etherX] eee=no
```

**Ubiquiti UniFi:** Port Profile → Advanced → disable **Green Ethernet (EEE)**.

---

## 4) Rollback (reversible)

```bash
# Re-enable EEE on host
ethtool --set-eee eno1 eee on
# Remove the pre-up line from /etc/network/interfaces then:
ifreload -a

# Remove GRUB flags and reboot
nano /etc/default/grub    # delete pcie_aspm=off and e1000e.SmartPowerDownEnable=0
update-grub
reboot

# Re-enable offloads if previously disabled
ethtool -K eno1 tso on gso on gro on

# Remove the watcher
systemctl disable --now e1000e-hang-watch.service
rm -f /etc/systemd/system/e1000e-hang-watch.service /usr/local/sbin/e1000e-hang-watch.sh
systemctl daemon-reload
```

---

## 5) Notes & hardening

- `eno1` under `vmbr0`: **no change needed** to the bridge itself; the watcher bounces only the physical NIC.
- Add a **second corosync ring** on an independent NIC (USB‑3 GbE is fine) or bond (active‑backup) to prevent isolation from a single NIC hang.
- Keep Lenovo BIOS/ME/NVM current.
- Avoid disabling watchdog/fencing globally; use node **maintenance mode** during changes.

---

## 6) Useful verification commands

```bash
# Current link & speed
ip -br link show eno1
ethtool eno1 | egrep 'Speed|Duplex|Auto-negotiation|Link detected'

# Watcher activity (this boot)
journalctl -u e1000e-hang-watch -b --no-pager -n 100

# Count recoveries today
journalctl -t e1000e-watch -S today | grep -c 'recovery complete'
```
