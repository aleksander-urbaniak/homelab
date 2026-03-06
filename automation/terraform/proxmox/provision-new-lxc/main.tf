resource "random_password" "lxc_admin" {
  count = var.admin_password == null ? 1 : 0

  length           = 24
  special          = true
  override_special = "_%@"
}

resource "proxmox_virtual_environment_download_file" "lxc_template" {
  count = var.template_file_id == null ? 1 : 0

  content_type       = "vztmpl"
  datastore_id       = var.template_datastore_id
  node_name          = var.template_node_name
  url                = var.template_url
  file_name          = var.template_file_name
  checksum           = var.template_checksum
  checksum_algorithm = var.template_checksum_algorithm
  overwrite          = var.template_overwrite
  verify             = var.template_verify_tls
}

resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  pool_id       = var.pool_id
  description   = var.description
  protection    = var.protection
  start_on_boot = var.start_on_boot
  started       = var.started
  tags          = local.tags
  unprivileged  = var.unprivileged

  lifecycle {
    precondition {
      condition     = var.template_file_id != null || (var.template_url != null && var.template_file_name != null)
      error_message = "Set template_file_id or provide both template_url and template_file_name."
    }
  }

  cpu {
    architecture = var.cpu_architecture
    cores        = var.cpu_cores
    units        = var.cpu_units
  }

  memory {
    dedicated = var.memory_dedicated_mb
    swap      = var.memory_swap_mb
  }

  disk {
    datastore_id  = var.root_disk_datastore_id
    size          = var.root_disk_size_gb
    mount_options = var.root_disk_mount_options
  }

  operating_system {
    template_file_id = local.effective_template_file_id
    type             = var.operating_system_type
  }

  features {
    nesting = var.enable_nesting
    fuse    = var.enable_fuse
    keyctl  = var.enable_keyctl
    mount   = length(var.mount_features) == 0 ? null : var.mount_features
  }

  initialization {
    hostname = var.hostname

    dynamic "dns" {
      for_each = local.has_dns_settings ? [1] : []

      content {
        domain  = var.dns_search_domain
        servers = var.dns_servers
      }
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_address == "dhcp" ? null : var.ipv4_gateway
      }

      dynamic "ipv6" {
        for_each = var.ipv6_address == null ? [] : [var.ipv6_address]

        content {
          address = ipv6.value
          gateway = contains(["auto", "dhcp"], ipv6.value) ? null : var.ipv6_gateway
        }
      }
    }

    user_account {
      keys     = var.ssh_public_keys
      password = local.lxc_password
    }
  }

  network_interface {
    name       = var.network_interface_name
    bridge     = var.network_bridge
    firewall   = var.network_firewall
    mtu        = var.network_mtu
    rate_limit = var.network_rate_limit_mb
    vlan_id    = var.network_vlan_id
  }

  dynamic "mount_point" {
    for_each = var.mount_points

    content {
      path          = mount_point.value.path
      volume        = mount_point.value.volume
      size          = try(mount_point.value.size, null)
      acl           = try(mount_point.value.acl, null)
      backup        = try(mount_point.value.backup, null)
      mount_options = try(mount_point.value.mount_options, null)
      quota         = try(mount_point.value.quota, null)
      read_only     = try(mount_point.value.read_only, null)
      replicate     = try(mount_point.value.replicate, null)
      shared        = try(mount_point.value.shared, null)
    }
  }

  environment_variables = var.environment_variables

  startup {
    order      = tostring(var.startup_order)
    up_delay   = tostring(var.startup_up_delay_seconds)
    down_delay = tostring(var.startup_down_delay_seconds)
  }

  wait_for_ip {
    ipv4 = var.wait_for_ipv4
    ipv6 = var.wait_for_ipv6
  }
}
