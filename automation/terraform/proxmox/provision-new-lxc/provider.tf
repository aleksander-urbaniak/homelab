provider "proxmox" {
  endpoint           = var.proxmox_endpoint
  insecure           = var.proxmox_insecure
  min_tls            = var.proxmox_min_tls
  api_token          = var.proxmox_api_token
  username           = var.proxmox_username
  password           = var.proxmox_password
  random_vm_ids      = var.proxmox_random_vm_ids
  random_vm_id_start = var.proxmox_random_vm_id_start
  random_vm_id_end   = var.proxmox_random_vm_id_end
}

