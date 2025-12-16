# Terraform Outputs

output "master_ip" {
  description = "IP address of K3s master"
  value       = var.master_ip
}

output "worker_ips" {
  description = "IP addresses of K3s workers"
  value       = local.worker_ips
}

output "all_ips" {
  description = "All node IP addresses"
  value       = concat([var.master_ip], local.worker_ips)
}

output "master_name" {
  description = "Name of master VM"
  value       = proxmox_vm_qemu.k3s_master[0].name
}

output "worker_names" {
  description = "Names of worker VMs"
  value       = [for vm in proxmox_vm_qemu.k3s_worker : vm.name]
}

output "kubeconfig_command" {
  description = "Command to export kubeconfig"
  value       = "export KUBECONFIG=$(pwd)/kubeconfig"
}

output "ssh_master_command" {
  description = "Command to SSH to master"
  value       = "ssh ${var.ssh_user}@${var.master_ip}"
}

output "dashboard_url" {
  description = "Kubernetes Dashboard URL"
  value       = "http://${var.master_ip}:30090"
}

output "traefik_url" {
  description = "Traefik Dashboard URL"
  value       = "http://${var.master_ip}:30880"
}
