# Adding and Mounting a New Disk in Linux (XFS or ext4)

> **Goal:** To prepare a new disk (e.g., `/dev/sdb`) for use and mount it **permanently** under `/mnt/data`.  
> Below are two paths: **XFS** and **ext4**. For modern systems using `systemd`, remember to run **`systemctl daemon-reload` after editing `/etc/fstab`**.

---

## Prerequisites

This tutorial uses standard Linux utilities. If any are missing, you can install them using your distribution's package manager.

-   **For Debian / Ubuntu based distributions:**
    ```bash
    sudo apt-get update
    sudo apt-get install parted xfsprogs fdisk
    ```
-   **For RHEL / CentOS / Fedora / Rocky Linux:**
    ```bash
    sudo dnf install parted xfsprogs util-linux
    ```
-   **For Arch Linux:**
    ```bash
    sudo pacman -S parted xfsprogs
    ```

This tutorial assumes you are running commands as a user with `sudo` privileges.

## Assumptions
- The new disk is **`/dev/sdb`** (make sure this is the correct disk by checking the output of `lsblk` or `fdisk -l`).
- The desired mount point is **`/mnt/data`**.
- The host uses a modern Linux distribution. The commands are universal, with specific notes for `systemd` vs. non-`systemd` systems.

---

## TL;DR – Quick commands (XFS **or** ext4)
```bash
# 1) Create a partition on the entire disk (GPT)
sudo parted -s /dev/sdb mklabel gpt
sudo parted -s /dev/sdb mkpart primary 1MiB 100%

# 2a) (XFS variant) Format with ftype=1
sudo mkfs.xfs -f -n ftype=1 /dev/sdb1

# 2b) (ext4 variant) Alternatively, format as ext4
# sudo mkfs.ext4 -F /dev/sdb1

# 3) Create the mount point
sudo mkdir -p /mnt/data

# 4) Add an entry to /etc/fstab (use the correct UUID)
UUID=$(blkid -s UUID -o value /dev/sdb1)
# For XFS:
echo "UUID=${UUID} /mnt/data xfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
# For ext4 (instead of the XFS line):
# echo "UUID=${UUID} /mnt/data ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab

# 5) Mount the filesystem (systemd vs. non-systemd)
# On systemd systems:
sudo systemctl daemon-reload
sudo mount -a
# On non-systemd systems, simply run:
# sudo mount /mnt/data

# 6) Verification
lsblk
df -h /mnt/data
```

> If the disk is an SSD/NVMe and you want to enable TRIM on mount: add `,discard` to the options in `/etc/fstab`. Alternatively, enable `fstrim.timer` (recommended in most environments).

---

## Step by step

### 1) Disk identification and partition preparation (GPT)
```bash
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS
sudo parted -s /dev/sdb mklabel gpt
sudo parted -s /dev/sdb mkpart primary 1MiB 100%
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS
```

### 2) Formatting – choose a file system

#### Option A: **XFS**
We use `ftype=1` which is required by some applications (e.g. container overlay filesystems).
```bash
sudo mkfs.xfs -f -n ftype=1 /dev/sdb1
```

#### Option B: **ext4**
Default parameters are good enough for general use.
```bash
sudo mkfs.ext4 -F /dev/sdb1
```
> If you want maximum speed with many small files, consider `-T news` / `-E lazy_itable_init=0` (at the cost of longer formatting). For most cases, this is not necessary.

### 3) Mount point
```bash
sudo mkdir -p /mnt/data
```

### 4) Permanent mount – `/etc/fstab`
Identify the **UUID** of the new partition and add the entry:
```bash
UUID=$(blkid -s UUID -o value /dev/sdb1)
# For XFS:
echo "UUID=${UUID} /mnt/data xfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
# For ext4 (instead of the above line):
# echo "UUID=${UUID} /mnt/data ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab
```

> Additional useful options:
> - `nofail` – the system will start even if the disk is not available.
> - `x-systemd.device-timeout=30s` – limits the time to wait for the device during boot.
> - `discard` – online TRIM (on SSD/NVMe). Alternative: `fstrim.timer`.
>
> Example with options (XFS):  
> `UUID=<...> /mnt/data xfs defaults,noatime,nofail,x-systemd.device-timeout=30s 0 0`

### 5) **Mount the new partition**
How you mount depends on whether your system uses `systemd`.

#### Option A: On systemd systems (most modern distros)
Reload the systemd manager configuration to make it aware of the changes to `/etc/fstab`, then mount all filesystems listed there.
```bash
sudo systemctl daemon-reload
sudo mount -a
```

#### Option B: On non-systemd systems
You can mount the filesystem directly. The entry in `/etc/fstab` will be used on the next reboot.
```bash
sudo mount /mnt/data
```

### 6) Verification
```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
df -h /mnt/data
```

---

## Troubleshooting

- **`mount: wrong fs type, bad option, bad superblock`** – Check that the filesystem type (e.g., `xfs`, `ext4`) in `/etc/fstab` is correct and that the `UUID` matches your partition.
- **The partition does not mount after reboot** – 
    - Double-check the syntax of your `/etc/fstab` entry.
    - On systemd systems, check for errors from the boot process with `journalctl -b` and look for messages related to the mount point.
    - On all systems, check system logs (e.g., `/var/log/syslog` or `/var/log/messages`) for errors.
    - Ensure you ran `systemctl daemon-reload` if you are on a systemd system.
- **You want to change the file system** – Back up your data, reformat (`mkfs.*`), and update the entry in `/etc/fstab`.

---

## Security and best practices
- Double-check that you are working on the **correct disk** (`/dev/sdb`!), not the system disk `/dev/sda`.
- Before adding to `/etc/fstab`, make a copy:
  ```bash
  sudo cp -a /etc/fstab /etc/fstab.backup.$(date +%F-%H%M%S)
  ```
- After editing `/etc/fstab`, always verify that the filesystem can be mounted. On `systemd` systems, run `systemctl daemon-reload` before `mount -a`. On non-systemd systems, you can test with `mount /mnt/data`.
- Consider `nofail` in environments where the disk might be temporarily unavailable (e.g., iSCSI/ceph/RHV).

---

**Author:** Linux Tutorial  
**Date:** 2025-08-28