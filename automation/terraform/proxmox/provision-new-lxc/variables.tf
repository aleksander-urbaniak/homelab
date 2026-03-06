variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint, for example https://pve.example.com:8006/."
  type        = string
  default     = null
  nullable    = true
}

variable "proxmox_insecure" {
  description = "Skip TLS validation for the Proxmox API."
  type        = bool
  default     = false
}

variable "proxmox_min_tls" {
  description = "Minimum TLS version for Proxmox API calls."
  type        = string
  default     = "1.3"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.proxmox_min_tls)
    error_message = "proxmox_min_tls must be one of 1.0, 1.1, 1.2, or 1.3."
  }
}

variable "proxmox_api_token" {
  description = "Proxmox API token. Prefer this over username/password in production."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "proxmox_username" {
  description = "Proxmox username when using password authentication."
  type        = string
  default     = null
  nullable    = true
}

variable "proxmox_password" {
  description = "Proxmox password when using password authentication."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "proxmox_random_vm_ids" {
  description = "Use randomly generated VMIDs when vm_id is not set."
  type        = bool
  default     = true
}

variable "proxmox_random_vm_id_start" {
  description = "Start of the random VMID range."
  type        = number
  default     = 10000
}

variable "proxmox_random_vm_id_end" {
  description = "End of the random VMID range."
  type        = number
  default     = 99999
}

variable "node_name" {
  description = "Target Proxmox node for the LXC."
  type        = string
}

variable "vm_id" {
  description = "Optional fixed VMID for the LXC."
  type        = number
  default     = null
  nullable    = true
}

variable "pool_id" {
  description = "Optional Proxmox pool assignment."
  type        = string
  default     = null
  nullable    = true
}

variable "hostname" {
  description = "Hostname assigned to the container."
  type        = string
}

variable "description" {
  description = "Description visible in Proxmox."
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "Tags to apply to the LXC."
  type        = set(string)
  default     = ["terraform", "lxc"]
}

variable "protection" {
  description = "Enable Proxmox protection for the container."
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start the container when the Proxmox node boots."
  type        = bool
  default     = true
}

variable "started" {
  description = "Whether the container should be started after apply."
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Create the LXC as unprivileged."
  type        = bool
  default     = true
}

variable "cpu_architecture" {
  description = "CPU architecture for the LXC."
  type        = string
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64", "armhf", "i386"], var.cpu_architecture)
    error_message = "cpu_architecture must be amd64, arm64, armhf, or i386."
  }
}

variable "cpu_cores" {
  description = "Number of CPU cores assigned to the LXC."
  type        = number
  default     = 2
}

variable "cpu_units" {
  description = "Relative CPU weight for the LXC."
  type        = number
  default     = 1024
}

variable "memory_dedicated_mb" {
  description = "Dedicated memory for the LXC in MiB."
  type        = number
  default     = 2048
}

variable "memory_swap_mb" {
  description = "Swap size for the LXC in MiB."
  type        = number
  default     = 512
}

variable "root_disk_datastore_id" {
  description = "Datastore that will hold the root filesystem."
  type        = string
}

variable "root_disk_size_gb" {
  description = "Root disk size in GiB."
  type        = number
  default     = 16
}

variable "root_disk_mount_options" {
  description = "Optional mount options for the root filesystem."
  type        = list(string)
  default     = []
}

variable "operating_system_type" {
  description = "Container OS family."
  type        = string
  default     = "debian"

  validation {
    condition = contains(
      ["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "nixos", "opensuse", "ubuntu", "unmanaged"],
      var.operating_system_type
    )
    error_message = "operating_system_type must match a supported Proxmox LXC OS type."
  }
}

variable "template_node_name" {
  description = "Node that stores the LXC template."
  type        = string
}

variable "template_datastore_id" {
  description = "Datastore that stores or will receive the LXC template."
  type        = string
}

variable "template_file_id" {
  description = "Existing Proxmox template file ID. If set, no download will happen."
  type        = string
  default     = null
  nullable    = true
}

variable "template_url" {
  description = "URL of the LXC template to download when template_file_id is not provided."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.template_url == null || can(regex("^https?://", var.template_url))
    error_message = "template_url must start with http:// or https://."
  }
}

variable "template_file_name" {
  description = "Filename to store for the downloaded template."
  type        = string
  default     = null
  nullable    = true
}

variable "template_checksum" {
  description = "Optional checksum for the downloaded template."
  type        = string
  default     = null
  nullable    = true
}

variable "template_checksum_algorithm" {
  description = "Optional checksum algorithm for the downloaded template."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.template_checksum_algorithm == null || contains(
      ["md5", "sha1", "sha224", "sha256", "sha384", "sha512"],
      var.template_checksum_algorithm
    )
    error_message = "template_checksum_algorithm must be one of md5, sha1, sha224, sha256, sha384, or sha512."
  }
}

variable "template_overwrite" {
  description = "Allow the provider to replace the downloaded template when the remote file changes."
  type        = bool
  default     = false
}

variable "template_verify_tls" {
  description = "Verify TLS certificates when downloading the template."
  type        = bool
  default     = true
}

variable "enable_nesting" {
  description = "Enable LXC nesting."
  type        = bool
  default     = true
}

variable "enable_fuse" {
  description = "Enable FUSE support inside the container."
  type        = bool
  default     = false
}

variable "enable_keyctl" {
  description = "Enable keyctl support inside the container."
  type        = bool
  default     = false
}

variable "mount_features" {
  description = "Optional mount feature allow-list, for example [\"nfs\"]."
  type        = list(string)
  default     = []
}

variable "network_interface_name" {
  description = "Container network interface name."
  type        = string
  default     = "eth0"
}

variable "network_bridge" {
  description = "Proxmox bridge attached to the LXC NIC."
  type        = string
  default     = "vmbr0"
}

variable "network_firewall" {
  description = "Enable Proxmox firewall on the container NIC."
  type        = bool
  default     = true
}

variable "network_mtu" {
  description = "Optional MTU override."
  type        = number
  default     = null
  nullable    = true
}

variable "network_rate_limit_mb" {
  description = "Optional NIC rate limit in MB/s."
  type        = number
  default     = null
  nullable    = true
}

variable "network_vlan_id" {
  description = "Optional VLAN tag for the container NIC."
  type        = number
  default     = null
  nullable    = true
}

variable "dns_search_domain" {
  description = "Optional DNS search domain."
  type        = string
  default     = null
  nullable    = true
}

variable "dns_servers" {
  description = "DNS servers passed into the container."
  type        = list(string)
  default     = []
}

variable "ipv4_address" {
  description = "IPv4 address in CIDR notation or dhcp."
  type        = string
  default     = "dhcp"
}

variable "ipv4_gateway" {
  description = "IPv4 gateway. Required when ipv4_address is static."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.ipv4_address == "dhcp" || var.ipv4_gateway != null
    error_message = "ipv4_gateway must be set when ipv4_address is static."
  }
}

variable "ipv6_address" {
  description = "Optional IPv6 address in CIDR notation, auto, or dhcp."
  type        = string
  default     = null
  nullable    = true
}

variable "ipv6_gateway" {
  description = "Optional IPv6 gateway for static IPv6."
  type        = string
  default     = null
  nullable    = true
}

variable "admin_password" {
  description = "Root password for the container. Leave null to generate one."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys injected into the container root account."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Environment variables for the container init process."
  type        = map(string)
  default     = {}
}

variable "mount_points" {
  description = "Additional mount points for the container."
  type = list(object({
    path          = string
    volume        = string
    size          = optional(string)
    acl           = optional(bool)
    backup        = optional(bool)
    mount_options = optional(list(string))
    quota         = optional(bool)
    read_only     = optional(bool)
    replicate     = optional(bool)
    shared        = optional(bool)
  }))
  default = []
}

variable "startup_order" {
  description = "Proxmox startup order for the container."
  type        = number
  default     = 30
}

variable "startup_up_delay_seconds" {
  description = "Delay before the next workload starts."
  type        = number
  default     = 30
}

variable "startup_down_delay_seconds" {
  description = "Delay before the next workload stops."
  type        = number
  default     = 15
}

variable "wait_for_ipv4" {
  description = "Wait for IPv4 allocation before Terraform finishes apply."
  type        = bool
  default     = true
}

variable "wait_for_ipv6" {
  description = "Wait for IPv6 allocation before Terraform finishes apply."
  type        = bool
  default     = false
}
