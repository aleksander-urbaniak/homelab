locals {
  lxc_password = var.admin_password != null ? var.admin_password : random_password.lxc_admin[0].result
  tags         = sort([for tag in var.tags : lower(tag)])

  effective_template_file_id = var.template_file_id != null ? var.template_file_id : proxmox_virtual_environment_download_file.lxc_template[0].id
  has_dns_settings           = var.dns_search_domain != null || length(var.dns_servers) > 0
}
