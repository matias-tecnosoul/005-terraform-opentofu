# main.tf - Múltiples VMs con Linked Clones

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

variable "vm_hostnames" {
  description = "Lista de hostnames para las VMs"
  type        = list(string)
  default     = ["web-01", "web-02", "db-01"]
}

variable "root_disk_bytes" {
  description = "Tamaño del disco en bytes"
  type        = number
  default     = 21474836480  # 20GB
}

variable "memory_mb" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 1024  # Reducido para poder crear múltiples VMs
}

variable "vcpu" {
  description = "Número de vCPUs"
  type        = number
  default     = 1  # Reducido para poder crear múltiples VMs
}

# Provider
provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Crear el template base (solo UNA vez para todas las VMs)
resource "libvirt_volume" "base_template" {
  name   = var.base_volume_name
  pool   = var.base_volume_pool
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Crear volúmenes usando Linked Clone (uno por VM)
resource "libvirt_volume" "os_image" {
  count = length(var.vm_hostnames)
  
  name = "${var.vm_hostnames[count.index]}.qcow2"
  pool = var.base_volume_pool
  size = var.root_disk_bytes
  
  # Configuración de linked clone - ¡TODAS apuntan al MISMO template!
  base_volume_pool = var.base_volume_pool
  base_volume_name = libvirt_volume.base_template.name
  
  depends_on = [libvirt_volume.base_template]
}

# 3. Cloud-init config (uno por VM con configuración específica)
resource "libvirt_cloudinit_disk" "commoninit" {
  count = length(var.vm_hostnames)
  
  name = "${var.vm_hostnames[count.index]}-cloudinit.iso"
  pool = var.base_volume_pool
  
  user_data = <<-EOF
    #cloud-config
    hostname: ${var.vm_hostnames[count.index]}
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
      # Instalar nginx solo en VMs web
      ${contains(["web-01", "web-02"], var.vm_hostnames[count.index]) ? "- nginx" : ""}
      # Instalar mysql solo en VMs db
      ${contains(["db-01"], var.vm_hostnames[count.index]) ? "- mysql-server" : ""}
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - resize2fs /dev/vda1
      # Configurar nginx en web servers
      ${contains(["web-01", "web-02"], var.vm_hostnames[count.index]) ? "- echo '<h1>Server: ${var.vm_hostnames[count.index]}</h1><p>Linked Clone Demo</p>' > /var/www/html/index.html" : ""}
      ${contains(["web-01", "web-02"], var.vm_hostnames[count.index]) ? "- systemctl enable nginx" : ""}
      ${contains(["web-01", "web-02"], var.vm_hostnames[count.index]) ? "- systemctl start nginx" : ""}
    EOF
}

# 4. Crear las VMs
resource "libvirt_domain" "vm" {
  count = length(var.vm_hostnames)
  
  name   = var.vm_hostnames[count.index]
  memory = var.memory_mb
  vcpu   = var.vcpu
  type   = "qemu"  # Usar emulación

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  disk {
    volume_id = libvirt_volume.os_image[count.index].id
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
output "vm_details" {
  description = "Details of all VMs"
  value = {
    for i, vm in libvirt_domain.vm : vm.name => {
      ip_address = length(vm.network_interface) > 0 && length(vm.network_interface[0].addresses) > 0 ? vm.network_interface[0].addresses[0] : "pending"
      hostname   = var.vm_hostnames[i]
      volume     = libvirt_volume.os_image[i].name
      role       = contains(["web-01", "web-02"], var.vm_hostnames[i]) ? "webserver" : "database"
    }
  }
}

output "template_info" {
  description = "Base template information"
  value = {
    name = libvirt_volume.base_template.name
    pool = var.base_volume_pool
    size_mb = libvirt_volume.base_template.size / 1024 / 1024
  }
}

output "web_urls" {
  description = "URLs to test nginx on web servers"
  value = [
    for i, vm in libvirt_domain.vm : 
    contains(["web-01", "web-02"], var.vm_hostnames[i]) && length(vm.network_interface) > 0 && length(vm.network_interface[0].addresses) > 0 ? 
    "http://${vm.network_interface[0].addresses[0]} (${var.vm_hostnames[i]})" : null
  ]
}

output "disk_usage_analysis" {
  description = "Analysis for disk usage comparison"
  value = {
    traditional_approach = "3 VMs × 500MB = 1.5GB total"
    linked_clone_approach = "500MB (template) + 3 × ~100KB (clones) ≈ 500MB total"
    savings = "~1GB saved (67% reduction)"
  }
}