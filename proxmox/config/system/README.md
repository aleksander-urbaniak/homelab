# 🖥️ System Configuration

This folder contains host-level system tuning snippets for Proxmox nodes.

## File

- [grub.cfg](grub.cfg): redacted GRUB defaults focused on boot and hardware stability.

## What It Does

The GRUB command line includes kernel parameters used to reduce power-management related instability:

- `usbcore.autosuspend=-1`: disables USB autosuspend, useful when USB NICs or adapters are sensitive to power saving.
- `pcie_aspm=off`: disables PCIe Active State Power Management to avoid problematic link state transitions.
- `e1000e.SmartPowerDownEnable=0`: disables Intel e1000e smart power-down behavior on affected NICs.

## Operational Notes

After changing GRUB on a real Proxmox node, run `update-grub` and reboot during a maintenance window. Validate the active command line with `cat /proc/cmdline` after boot.
