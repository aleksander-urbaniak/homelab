# provision-new-lxc

Provision a new Proxmox LXC container from an existing template file ID or by downloading a template directly through the Proxmox API.

## What this stack does

- pins Terraform and the `bpg/proxmox` provider
- supports API token or username/password authentication
- downloads an LXC template with `proxmox_virtual_environment_download_file` when `template_file_id` is not supplied
- creates a production-oriented unprivileged container
- injects SSH keys and a password during initialization
- supports static or DHCP networking, tags, pool placement, startup order, and extra mount points

## Usage

```powershell
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Notes

- `root_disk_datastore_id` is where the container root filesystem is created.
- `template_datastore_id` is where the LXC template is stored.
- Downloading a template with `proxmox_virtual_environment_download_file` requires Proxmox permissions for `Datastore.AllocateTemplate`, `Sys.Audit`, and `Sys.Modify` on the relevant node and storage path.
- The target datastore must allow the `Container template` / `vztmpl` content type in Proxmox.
- If your environment already has a curated template, set `template_file_id` and leave the download variables unset.
- Keep real `terraform.tfvars` files out of git.
