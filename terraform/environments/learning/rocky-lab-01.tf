resource "proxmox_virtual_environment_vm" "rocky_lab_01" {
  name        = "rocky-lab-01"
  description = "Rocky Linux Lab 01 - Learning Environment"
  node_name   = "pve"
  vm_id       = 7001

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
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 25
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.40.100/24"
        gateway = "192.168.40.1"
      }
    }

    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
  }

  tags = ["learning", "rocky", "lab"]
}

output "rocky_lab_01_ip" {
  value = proxmox_virtual_environment_vm.rocky_lab_01.ipv4_addresses
}
