# Expand `/dev/sda1` Mounted at `/mnt/longhorn` Online, Without Downtime

> **Goal:** Increase the size of an existing **ext4** filesystem mounted at `/mnt/longhorn`, for example from `100G` to `200G`, without unmounting it.

---

## Assumptions and Context

- You have a single disk **`/dev/sda`** with one partition **`/dev/sda1`** mounted at **`/mnt/longhorn`**
- The filesystem is **ext4**
- This is a **virtual machine** environment such as vSphere, Proxmox, Hyper-V, or a cloud VM
- The operation is performed **online**, without unmounting

> `lsblk` shows binary GiB values, while `df -H` uses decimal GB values, so small differences in displayed sizes are normal.

---

## TL;DR

```bash
# 0) In the hypervisor, increase /dev/sda first, for example 100G -> 200G

# 1) Rescan the disk in the guest
lsblk
echo 1 | sudo tee /sys/class/block/sda/device/rescan
lsblk

# 2) Extend partition 1 to fill the new free space
# Install growpart if needed:
# RHEL/CentOS/Alma/Rocky: sudo yum install -y cloud-utils-growpart
# Debian/Ubuntu:         sudo apt-get update && sudo apt-get install -y cloud-guest-utils
sudo growpart /dev/sda 1

# 3) Reload the partition table
sudo partprobe /dev/sda

# 4) Grow the ext4 filesystem online
sudo resize2fs /dev/sda1

# 5) Verify
df -h /mnt/longhorn
lsblk
```

Alternative without `growpart`:

```bash
sudo parted /dev/sda ---pretend-input-tty <<<'resizepart 1 100%'
sudo partprobe /dev/sda
sudo resize2fs /dev/sda1
```

---

## Step by Step

### 0) Increase the Disk Size in the Hypervisor

Use the hypervisor UI or CLI to grow the virtual disk for **`/dev/sda`**. Make sure you are resizing the correct disk.

### 1) Confirm the Filesystem Type

```bash
findmnt -no FSTYPE /mnt/longhorn
# -> ext4
lsblk -f
```

### 2) Rescan the Disk in the Guest

After resizing the disk in the hypervisor, the guest OS should detect the new size:

```bash
lsblk
echo 1 | sudo tee /sys/class/block/sda/device/rescan
lsblk
```

### 3) Extend the Partition

Preferred method:

```bash
# Example package install for RHEL-like systems
sudo yum install -y cloud-utils-growpart
sudo growpart /dev/sda 1
```

Without `growpart`:

```bash
sudo parted /dev/sda ---pretend-input-tty <<<'resizepart 1 100%'
```

### 4) Reload the Partition Table

```bash
sudo partprobe /dev/sda
```

### 5) Grow the ext4 Filesystem Online

```bash
sudo resize2fs /dev/sda1
```

> `e2fsck` is not required for online growth. It is relevant when shrinking a filesystem, which is not part of this guide.

### 6) Verify

```bash
df -h /mnt/longhorn
lsblk
```

---

## XFS Variant

If you later switch this filesystem to XFS, do not use `resize2fs`. The disk and partition steps stay the same, but the filesystem growth command changes to:

```bash
sudo xfs_growfs /mnt/longhorn
```

---

## LVM or LUKS Variant

If `/mnt/longhorn` is backed by **LVM** or **LUKS**, the workflow changes:

1. Grow the disk in the hypervisor
2. Resize the physical volume with `sudo pvresize /dev/sdaX`
3. Extend the logical volume with `sudo lvextend -r -l +100%FREE <VG>/<LV>`
4. For XFS without `-r`, run `sudo xfs_growfs /mnt/...`

This specific guide assumes a plain ext4 partition, so the LVM/LUKS section is informational only.

---

## Backups and Longhorn

- Take a backup or snapshot before starting
- Make sure Longhorn is not performing maintenance operations such as replica movement during the resize

---

## Common Problems

### `growpart: NOCHANGE: partition 1 is size ... it cannot be grown`

Cause:
The hypervisor resize was not applied, or the guest rescan did not pick it up.

Fix:

```bash
echo 1 | sudo tee /sys/class/block/sda/device/rescan
lsblk
```

### `resize2fs: Device or resource busy`

Cause:
Usually a temporary state after partition changes.

Fix:

```bash
sudo partprobe /dev/sda
sudo resize2fs /dev/sda1
```

### `parted` asks about `fix/ignore` or warns about GPT/MBR

If you have GPT and a single partition, `growpart` usually handles this more cleanly. Make sure you are targeting the correct disk and partition.

### Size did not change in `df -h`

Cause:
The filesystem growth step was missed.

Fix:
Run `resize2fs` for ext4 or `xfs_growfs` for XFS.

---

## Quick Copy-Paste Script

Adjust the disk and partition names if they are different from `/dev/sda` and `/dev/sda1`.

```bash
#!/usr/bin/env bash
set -euo pipefail

DISK=/dev/sda
PART=/dev/sda1
MOUNT=/mnt/longhorn

echo "[1/5] Rescanning disk..."
echo 1 | sudo tee /sys/class/block/$(basename "$DISK")/device/rescan >/dev/null || true

echo "[2/5] Extending partition..."
if command -v growpart >/dev/null 2>&1; then
  sudo growpart "$DISK" 1
else
  sudo parted "$DISK" ---pretend-input-tty <<<'resizepart 1 100%'
fi

echo "[3/5] Running partprobe..."
sudo partprobe "$DISK" || true

echo "[4/5] Growing ext4 filesystem..."
sudo resize2fs "$PART"

echo "[5/5] Verifying..."
df -h "$MOUNT"
lsblk
echo "Done."
```

---

**Author:** prepared for an ext4-based `/mnt/longhorn` environment  
**Date:** 2025-08-28
