# Online Disk Partition and Filesystem Expansion

> **Goal:** To expand an existing disk partition and its filesystem (e.g., ext4 or XFS) without downtime (online).

---

## Prerequisites

This tutorial uses standard Linux utilities. If any are missing, you can install them using your distribution's package manager. The `growpart` command is highly recommended.

-   **For Debian / Ubuntu based distributions:**
    ```bash
    sudo apt-get update
    sudo apt-get install cloud-guest-utils parted
    ```
-   **For RHEL / CentOS / Fedora / Rocky Linux:**
    ```bash
    sudo dnf install cloud-utils-growpart parted
    ```
-   **For Arch Linux:**
    ```bash
    sudo pacman -S cloud-utils
    ```

This tutorial assumes you are running commands as a user with `sudo` privileges.

## Assumptions and context
- You are expanding a partition on a disk (e.g., `/dev/sda1` on `/dev/sda`).
- The environment is a **Virtual Machine** (vSphere/Proxmox/Hyper-V/cloud), where virtual disk sizes can be easily changed.
- The operation is performed **online** (without unmounting the filesystem).

> **Note on units:** `lsblk` shows sizes in binary units (GiB), while `df -H` often shows them in decimal units (GB). A 10% difference in reported numbers is normal.

---

## TL;DR – Quick commands
```bash
# --- Configuration ---
# !!! CHANGE THESE VALUES to match your system !!!
DISK="/dev/sda"
PARTITION_NUM="1"
MOUNT_POINT="/mnt/data" 
# --- End Configuration ---

# 0) In your hypervisor: increase the size of the virtual disk (e.g., from 100G to 200G)

# 1) Rescan the disk to make the kernel see the new size
lsblk
echo 1 | sudo tee /sys/class/block/$(basename $DISK)/device/rescan
lsblk

# 2) Expand the partition to fill the available space
sudo growpart $DISK $PARTITION_NUM

# 3) Reload the partition table for the kernel
sudo partprobe $DISK

# 4) Expand the filesystem
# For ext4:
sudo resize2fs ${DISK}${PARTITION_NUM}
# For XFS:
# sudo xfs_growfs $MOUNT_POINT

# 5) Verify the new size
df -h $MOUNT_POINT
lsblk
```
**Alternative to `growpart`:**
```bash
# Use with caution!
sudo parted $DISK ---pretend-input-tty <<EOF
resizepart $PARTITION_NUM 100%
EOF
# Then continue with partprobe and resize2fs/xfs_growfs
```

---

## Step by step with explanations

### 0) Increase the disk size in your hypervisor/cloud
In your virtualization platform's management interface, increase the size of the virtual disk you want to expand. Be sure to select the correct disk.

### 1) Identify your disk, partition, and filesystem type
Use `lsblk` or `df -h` to identify the correct disk, partition number, and mount point. Use `findmnt` to verify the filesystem type.
```bash
lsblk -f
# Or to find the specific mount point's FS type:
findmnt -no FSTYPE /path/to/mountpoint 
# Example output -> ext4
```

### 2) Rescan the disk in the operating system
After increasing the disk size in the hypervisor, the OS needs to be made aware of the new size.
```bash
# Replace 'sda' with your disk name if different
lsblk
echo 1 | sudo tee /sys/class/block/sda/device/rescan
lsblk # Verify the disk size has increased
```

### 3) Expand the partition
The `growpart` utility is the safest way to do this.
```bash
# Expands partition 1 on /dev/sda
sudo growpart /dev/sda 1
```
If you don't have `growpart`, you can use `parted`, but it's less interactive. The following command tells `parted` to resize partition 1 to fill 100% of the available space.
```bash
# Use with caution
sudo parted /dev/sda ---pretend-input-tty <<<'resizepart 1 100%'
```

### 4) Refresh the kernel's partition table
This command forces the kernel to re-read the partition table from the disk.
```bash
sudo partprobe /dev/sda
```

### 5) Expand the filesystem
This is the final step, where the filesystem is grown to fill the new partition size. The command depends on your filesystem type.

#### Option A: for ext4
```bash
# Use the partition path, e.g., /dev/sda1
sudo resize2fs /dev/sda1
```
> `e2fsck` is not required when expanding an ext4 filesystem online. It is only needed for shrinking.

#### Option B: for XFS
```bash
# Use the mount point path, e.g., /mnt/data
sudo xfs_growfs /mnt/data
```

### 6) Verification
Check that the size has been updated correctly.
```bash
df -h /mnt/data
lsblk
```

---

## Notes on LVM / LUKS
If your setup uses LVM or LUKS, the process is different. You would typically:
1.  Increase the physical disk size in the hypervisor.
2.  Resize the Physical Volume (PV): `sudo pvresize /dev/sdaX`.
3.  Resize the Logical Volume (LV): `sudo lvextend -r -l +100%FREE <VG>/<LV>`. The `-r` flag resizes the filesystem at the same time.
4.  If you didn't use `-r`, you would manually resize the filesystem as shown in step 5.

This guide focuses on a simple partition, so the LVM/LUKS information is for context only.

---

## Most common problems and solutions

### 1) `growpart: NOCHANGE: partition 1 is size ... it cannot be grown`
- **Cause:** The hypervisor hasn't actually increased the disk size, or the OS rescan didn't work.
- **Solution:** Double-check the disk size in your hypervisor's settings, then run the rescan command again: `echo 1 | sudo tee /sys/class/block/sda/device/rescan`

### 2) `resize2fs: Device or resource busy` (rare with online resizing)
- **Cause:** This can be a transient issue.
- **Solution:** Run `sudo partprobe /dev/sda` and then try the `resize2fs` command again.

### 3) `parted` asks to “fix/ignore” or warns about GPT/MBR
- **Cause:** The partition table might have inconsistencies.
- **Solution:** The `growpart` command is generally better at handling this automatically. If you must use `parted`, be very careful and ensure you are working on the correct disk.

### 4) Filesystem size doesn't change in `df -h`
- **Cause:** You forgot to run the final filesystem resize step (`resize2fs` for ext4 or `xfs_growfs` for XFS).
- **Solution:** Run the correct command for your filesystem type.

---

## Quick "copy-paste" script
> **Warning:** Review and edit the variables in the `Configuration` section before running.
```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
# !!! CHANGE THESE VALUES to match your system !!!
DISK="/dev/sda"
PARTITION_NUM="1"
MOUNT_POINT="/mnt/data" 
FILESYSTEM_TYPE="ext4" # Change to "xfs" if needed
# --- End Configuration ---

PARTITION_PATH="${DISK}${PARTITION_NUM}"

echo "[1/5] Rescanning the disk..."
echo 1 | sudo tee /sys/class/block/$(basename "$DISK")/device/rescan >/dev/null || true

echo "[2/5] Expanding the partition..."
if command -v growpart >/dev/null 2>&1; then
  sudo growpart "$DISK" "$PARTITION_NUM"
else
  echo "growpart not found, attempting with parted. This is less safe."
  sudo parted "$DISK" ---pretend-input-tty <<EOF
resizepart $PARTITION_NUM 100%
EOF
fi

echo "[3/5] Forcing kernel to re-read partition table..."
sudo partprobe "$DISK" || true

echo "[4/5] Expanding the filesystem (${FILESYSTEM_TYPE})..."
if [ "$FILESYSTEM_TYPE" = "ext4" ]; then
  sudo resize2fs "$PARTITION_PATH"
elif [ "$FILESYSTEM_TYPE" = "xfs" ]; then
  sudo xfs_growfs "$MOUNT_POINT"
else
  echo "Unsupported filesystem type: $FILESYSTEM_TYPE"
  exit 1
fi

echo "[5/5] Verification:"
df -h "$MOUNT_POINT"
lsblk
echo "Done ✅"
```

---

**Author:** Universal Linux Tutorial
**Date:** 2025-08-28