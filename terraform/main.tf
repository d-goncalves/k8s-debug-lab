terraform {
  required_version = ">= 1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

# Cached on the Proxmox host, so a rebuild does not re-download 600MB.
# bpg requires a .img extension for qcow2 images imported as "iso" content.
resource "proxmox_virtual_environment_download_file" "rocky" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = var.rocky_image_url
  file_name    = "Rocky-9-GenericCloud.img"
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "lab" {
  name        = var.vm_name
  description = "k8s-debug-lab - disposable k3s box for fault injection practice"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id

  # i440fx, deliberately NOT q35.
  # q35 fails to boot the Rocky GenericCloud image on this platform: no serial
  # console output at all and the CPU pegs at 100%. Cost an hour to find.
  machine = "pc"

  agent {
    enabled = false
  }

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_download_file.rocky.id
    interface    = "scsi0"
    size         = var.vm_disk
    iothread     = true
    discard      = "on"
  }

  initialization {
    datastore_id = var.vm_datastore

    ip_config {
      ipv4 {
        address = var.vm_address
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.vm_nameservers
    }

    user_account {
      username = var.vm_user
      keys     = [var.ssh_public_key]
    }
  }

  network_device {
    bridge = var.vm_bridge
  }

  serial_device {}

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [disk[0].file_id]
  }
}
