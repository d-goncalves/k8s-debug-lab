variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Name of the Proxmox node to build on"
  type        = string
  default     = "pve"
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (typical for a self-signed homelab cert)"
  type        = bool
  default     = true
}

variable "vm_id" {
  description = "Proxmox VMID. Must not already be in use."
  type        = number
  default     = 120
}

variable "vm_name" {
  type    = string
  default = "k8s-debug-lab"
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_memory" {
  description = "MB. k3s plus the demo stack needs ~3GB; 4096 is comfortable."
  type        = number
  default     = 4096
}

variable "vm_disk" {
  description = "GB. Several faults fill the disk deliberately, so leave headroom."
  type        = number
  default     = 30
}

variable "vm_datastore" {
  type    = string
  default = "local-lvm"
}

variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_user" {
  description = "cloud-init user created on the VM"
  type        = string
  default     = "rocky"
}

variable "ssh_public_key" {
  description = "Public key authorised for the cloud-init user and for root"
  type        = string
}

variable "vm_address" {
  description = "Static CIDR address for the VM. Must be free and outside your DHCP pool."
  type        = string
  default     = "192.168.1.60/24"
}

variable "vm_gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "vm_nameservers" {
  description = "Resolvers for the VM. Do NOT inherit a MagicDNS resolver here - see README."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "rocky_image_url" {
  type    = string
  default = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
}

variable "proxmox_ssh_user" {
  description = "SSH user on the Proxmox node for disk-import operations. Needs an agent key authorised in this user's authorized_keys."
  type        = string
  default     = "root"
}
