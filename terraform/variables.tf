# Proxmox connection
variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://192.168.40.40:8006/api2/json)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., terraform@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

# VM Template
variable "vm_template" {
  description = "Cloud-init template name"
  type        = string
}

variable "vm_storage" {
  description = "Storage for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "vm_network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

# K3s Master
variable "master_count" {
  description = "Number of master nodes (keep 1 for simplicity)"
  type        = number
  default     = 1

  validation {
    condition     = var.master_count == 1
    error_message = "For this simple setup, use 1 master node."
  }
}

variable "master_cores" {
  description = "CPU cores for master"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "Memory for master (MB)"
  type        = number
  default     = 4096
}

variable "master_disk_size" {
  description = "Disk size for master"
  type        = string
  default     = "32G"
}

variable "master_ip" {
  description = "Static IP for master (e.g., 192.168.1.100)"
  type        = string
}

# K3s Workers
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "worker_cores" {
  description = "CPU cores for workers"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory for workers (MB)"
  type        = number
  default     = 4096
}

variable "worker_disk_size" {
  description = "Disk size for workers"
  type        = string
  default     = "32G"
}

variable "worker_ip_start" {
  description = "First IP for workers (e.g., 192.168.1.101). Workers get .101, .102, etc."
  type        = string
}

# Network
variable "network_gateway" {
  description = "Network gateway"
  type        = string
}

variable "network_dns" {
  description = "DNS server"
  type        = string
  default     = "8.8.8.8"
}

variable "network_cidr" {
  description = "Network CIDR bits"
  type        = number
  default     = 24
}

# SSH
variable "ssh_public_key" {
  description = "SSH public key for accessing VMs"
  type        = string
}

variable "ssh_user" {
  description = "Default user created by cloud-init"
  type        = string
  default     = "k8s"
}
