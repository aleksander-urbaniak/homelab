output "container_id" {
  description = "Cluster-wide VMID of the created LXC container."
  value       = proxmox_virtual_environment_container.this.vm_id
}

output "container_ipv4" {
  description = "IPv4 addresses reported by Proxmox for the container."
  value       = proxmox_virtual_environment_container.this.ipv4
}

output "container_ipv6" {
  description = "IPv6 addresses reported by Proxmox for the container."
  value       = proxmox_virtual_environment_container.this.ipv6
}

output "container_password" {
  description = "Root password used during initialization."
  value       = local.lxc_password
  sensitive   = true
}

output "template_file_id" {
  description = "Template file ID used to create the container."
  value       = local.effective_template_file_id
}

