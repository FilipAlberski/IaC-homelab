resource "proxmox_virtual_environment_vm" "docker_01" {
  name        = "docker-01"
  description = "Docker Host - Production Environment"
  node_name   = "pve"
  vm_id       = 1001

  clone {
    vm_id = 9000
    full  = true
  }

  # VM Settings
  started = true

  agent {
    enabled = true
    timeout = "10s"
  }

  startup {
    order = 1
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 100
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.40.50/24"
        gateway = "192.168.40.1"
      }
    }
  }

  tags = ["production", "docker", "container-host"]
}

output "docker_01_ip" {
  value       = proxmox_virtual_environment_vm.docker_01.ipv4_addresses
  description = "IP addresses of docker-01"
}

output "docker_01_id" {
  value       = proxmox_virtual_environment_vm.docker_01.vm_id
  description = "VM ID of docker-01"
}
