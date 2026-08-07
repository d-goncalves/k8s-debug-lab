output "vm_id" {
  value = proxmox_virtual_environment_vm.lab.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.lab.name
}

output "vm_address" {
  description = "Static address assigned to the lab VM"
  value       = split("/", var.vm_address)[0]
}

output "ssh_user" {
  value = var.vm_user
}
