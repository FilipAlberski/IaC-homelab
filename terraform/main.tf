# K3s Cluster Infrastructure

locals {
  # Oblicz IP dla workerów
  worker_ips = [for i in range(var.worker_count) :
    cidrhost("${var.worker_ip_start}/${var.network_cidr}", i)
  ]
}

# K3s Master Node
resource "proxmox_vm_qemu" "k3s_master" {
  count = var.master_count

  name        = "k3s-master-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template
  agent       = 1

  cores   = var.master_cores
  sockets = 1
  cpu     = "host"
  memory  = var.master_memory

  # Disk
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.vm_storage
          size    = var.master_disk_size
          iothread = true
          discard = true
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = var.vm_network_bridge
  }

  # Cloud-init
  ipconfig0 = "ip=${var.master_ip}/${var.network_cidr},gw=${var.network_gateway}"

  nameserver = var.network_dns
  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  # Boot order
  boot = "order=scsi0"

  # Tags
  tags = "k3s;master;terraform"

  # Start on create
  oncreate = true

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# K3s Worker Nodes
resource "proxmox_vm_qemu" "k3s_worker" {
  count = var.worker_count

  name        = "k3s-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.vm_template
  agent       = 1

  cores   = var.worker_cores
  sockets = 1
  cpu     = "host"
  memory  = var.worker_memory

  # Disk
  disks {
    scsi {
      scsi0 {
        disk {
          storage = var.vm_storage
          size    = var.worker_disk_size
          iothread = true
          discard = true
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = var.vm_network_bridge
  }

  # Cloud-init
  ipconfig0 = "ip=${local.worker_ips[count.index]}/${var.network_cidr},gw=${var.network_gateway}"

  nameserver = var.network_dns
  ciuser     = var.ssh_user
  sshkeys    = var.ssh_public_key

  # Boot order
  boot = "order=scsi0"

  # Tags
  tags = "k3s;worker;terraform"

  # Start on create
  oncreate = true

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disk,
    ]
  }
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    master_name = proxmox_vm_qemu.k3s_master[0].name
    master_ip   = var.master_ip
    worker_nodes = [for i in range(var.worker_count) : {
      name = proxmox_vm_qemu.k3s_worker[i].name
      ip   = local.worker_ips[i]
    }]
    ssh_user        = var.ssh_user
    k3s_master_ip   = var.master_ip
  })

  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"
}
