# Add a New Disk and Mount It at `/mnt/docker` (XFS **or** ext4)

> **Goal:** Prepare a new disk such as `/dev/sdb` and mount it **persistently** at `/mnt/docker`.  
> Below are two options: **XFS** for Docker `overlay2`, and **ext4**. In both cases, remember to run **`systemctl daemon-reload` after editing `/etc/fstab`**.

---

## Assumptions

- The new disk is **`/dev/sdb`**. Make sure this is the correct disk.
- The mount point is **`/mnt/docker`**.
- The examples were written for RHEL / Oracle / Rocky / Alma style systems, but the commands are usable on most Linux distributions.
- No Docker data migration is needed in this scenario.

---

## TL;DR

```bash
# 1) Create a partition on the whole disk (GPT)
sudo parted -s /dev/sdb mklabel gpt
sudo parted -s /dev/sdb mkpart primary 1MiB 100%

# 2a) XFS option: format with ftype=1
sudo mkfs.xfs -f -n ftype=1 /dev/sdb1

# 2b) ext4 option: format as ext4 instead
# sudo mkfs.ext4 -F /dev/sdb1

# 3) Create the mount point
sudo mkdir -p /mnt/docker

# 4) Add the correct UUID to /etc/fstab
UUID=$(blkid -s UUID -o value /dev/sdb1)
# For XFS:
echo "UUID=${UUID} /mnt/docker xfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
# For ext4:
# echo "UUID=${UUID} /mnt/docker ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab

# 5) Reload systemd config and mount
sudo systemctl daemon-reload
sudo mount -a

# 6) Verify
lsblk
df -h /mnt/docker
```

> If the disk is SSD/NVMe and you want TRIM during mount, add `,discard` to the mount options in `/etc/fstab`. In most environments, enabling `fstrim.timer` is the better approach.

---

## Step by Step

### 1) Identify the Disk and Create the Partition Table

```bash
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS
sudo parted -s /dev/sdb mklabel gpt
sudo parted -s /dev/sdb mkpart primary 1MiB 100%
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS
```

### 2) Format the Partition

#### Option A: XFS

XFS with `ftype=1` is recommended for Docker `overlay2`.

```bash
sudo mkfs.xfs -f -n ftype=1 /dev/sdb1
```

#### Option B: ext4

Default ext4 settings are usually fine.

```bash
sudo mkfs.ext4 -F /dev/sdb1
```

> If you want to optimize for lots of small files, you can consider flags like `-T news` or `-E lazy_itable_init=0`, but most setups do not need that extra tuning.

### 3) Create the Mount Point

```bash
sudo mkdir -p /mnt/docker
```

### 4) Add a Persistent Mount in `/etc/fstab`

Get the partition UUID and add it to `/etc/fstab`:

```bash
UUID=$(blkid -s UUID -o value /dev/sdb1)
# For XFS:
echo "UUID=${UUID} /mnt/docker xfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
# For ext4:
# echo "UUID=${UUID} /mnt/docker ext4 defaults,noatime 0 0" | sudo tee -a /etc/fstab
```

Useful extra options:

- `nofail` lets the system boot even if the disk is unavailable
- `x-systemd.device-timeout=30s` limits boot wait time for the device
- `discard` enables online TRIM for SSD/NVMe

Example:

```text
UUID=<...> /mnt/docker xfs defaults,noatime,nofail,x-systemd.device-timeout=30s 0 0
```

### 5) Reload systemd and Mount the Filesystem

```bash
sudo systemctl daemon-reload
sudo mount -a
```

### 6) Verify

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
df -h /mnt/docker
```

---

## Troubleshooting

- `mount: wrong fs type, bad option, bad superblock`
  Check that the filesystem type in `/etc/fstab` matches the actual filesystem and that the UUID is correct.
- The mount does not appear after reboot
  Confirm the `/etc/fstab` entry is valid, run `systemctl daemon-reload`, and inspect `journalctl -b`.
- You want to switch filesystems later
  Back up the data, reformat with `mkfs.*`, and update `/etc/fstab`.

---

## Safety and Good Practices

- Double-check that you are working on the correct disk, especially not the system disk.
- Back up `/etc/fstab` before changing it:

```bash
sudo cp -a /etc/fstab /etc/fstab.backup.$(date +%F-%H%M%S)
```

- Always validate both `mount -a` and `systemctl daemon-reload` after editing `/etc/fstab`.
- Consider `nofail` if the disk might be temporarily unavailable, for example with iSCSI or Ceph-backed setups.

---

**Author:** short tutorial for adding a new disk and mounting it at `/mnt/docker`  
**Date:** 2025-08-28
