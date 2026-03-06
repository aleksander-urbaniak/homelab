# Proxmox Terraform Stacks

This directory contains two standalone Terraform root modules for provisioning workloads on Proxmox VE with the `bpg/proxmox` provider:

- `provision-new-lxc` creates a new LXC container from a template.
- `provision-new-lxc-web-server` creates a new LXC container and installs nginx automatically.
- `provision-new-vm` creates a new VM from a cloud image.

Both stacks are written to work with API access only by default. Credentials can be passed with `terraform.tfvars` or environment variables supported by the provider such as:

- `PROXMOX_VE_ENDPOINT`
- `PROXMOX_VE_API_TOKEN`
- `PROXMOX_VE_USERNAME`
- `PROXMOX_VE_PASSWORD`

Each stack also includes:

- `terraform.tfvars.example`
- `backend.tf.example`
- `README.md`

The provider version is pinned to the current `0.97.x` line.
