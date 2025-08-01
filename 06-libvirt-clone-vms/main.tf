# main.tf - VM con Linked Clone

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# Variables
variable "base_volume_pool" {
  description = "Pool donde está el template"
  type        = string
  default     = "default"
}

variable "base_volume_name" {
  description = "Nombre del volumen template"
  type        = string
  default     = "ubuntu-22.04-template.qcow2"
}

variable "hostname" {
  description = "Hostname de la VM"
  type        = string
  default     = "test-vm"
}

variable "root_disk_bytes" {
  description = "Tamaño del disco en bytes"
  type        = number
  default     = 21474836480  # 20GB
}

variable "memory_mb" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "vcpu" {
  description = "Número de vCPUs"
  type        = number
  default     = 2
}

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Crear el template base (solo se descarga una vez)
resource "libvirt_volume" "base_template" {
  name   = var.base_volume_name
  pool   = var.base_volume_pool
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Crear volumen usando Linked Clone
resource "libvirt_volume" "os_image" {
  name = "${var.hostname}.qcow2"
  pool = var.base_volume_pool
  size = var.root_disk_bytes
  
  # Configuración de linked clone
  base_volume_pool = var.base_volume_pool
  base_volume_name = libvirt_volume.base_template.name
  
  depends_on = [libvirt_volume.base_template]
}

# 3. Cloud-init config
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.hostname}-cloudinit.iso"
  pool = var.base_volume_pool
  
  user_data = <<-EOF
    #cloud-config
    hostname: ${var.hostname}
    users:
      - name: ubuntu
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${file("~/.ssh/id_rsa.pub")}
    packages:
      - qemu-guest-agent
      - htop
      - curl
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - resize2fs /dev/vda1
    EOF
}

# 4. Crear la VM
resource "libvirt_domain" "vm" {
  name   = var.hostname
  memory = var.memory_mb
  vcpu   = var.vcpu
  type = "qemu"

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.os_image.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Outputs
output "vm_ip" {
  description = "IP address of the VM"
  value       = libvirt_domain.vm.network_interface[0].addresses[0]
}

output "vm_name" {
  description = "Name of the VM"
  value       = libvirt_domain.vm.name
}

output "base_template_path" {
  description = "Path to base template"
  value       = libvirt_volume.base_template.name
}

output "linked_clone_path" {
  description = "Path to linked clone volume"
  value       = libvirt_volume.os_image.name
}