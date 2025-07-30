terraform {
  required_providers {
    libvirt = {
        source = "dmacvicar/libvirt"
        version = "0.8.1"
    }
  }
  required_version = "~> 1.10.0"
}

# Configurar el provider libvirt para tu configuración actual
provider "libvirt" {
  uri = "qemu:///session"  # o eliminar esta línea para usar default del sistema
}

# Crear el pool en la ubicación que ya usas
resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  target {
    path = "/mnt/datos1/00-Soft/libvirt/images"
  }
}

variable "root_pass" {
  default = "mikroways"
}
variable "hostname" {
  default = "tf-vm"
}
variable "ubuntu_cloudimg" {
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "ubuntu-2404_cloudimage" {
  name = "ubuntu2404-tpl.qcow2"
  pool = libvirt_pool.default.name
  source = var.ubuntu_cloudimg
  format = "qcow2"
}

locals {
  cloudinit_tpl = <<EOF
#cloud-config
hostname: $${hostname}
create_hostname_file: true
ssh_authorized_keys:
  - $${ssh}
ssh_pwauth: True
chpasswd:
  list: |
    root:$${root_pass}
  expire: False
EOF
}

resource "libvirt_cloudinit_disk" "vm" {
  name = "cloudinit-vm.iso"
  user_data = templatestring(local.cloudinit_tpl, {
    hostname  = var.hostname
    root_pass = var.root_pass
    ssh = file("~/.ssh/id_rsa.pub")
  })
}

# Virtual-Machine(s)
resource "libvirt_domain" "vm" {
  name   = var.hostname
  memory = "2048"
  vcpu   = 2
  autostart = false

  disk { volume_id = resource.libvirt_volume.ubuntu-2404_cloudimage.id }

  cloudinit = libvirt_cloudinit_disk.vm.id

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

}

output "node" {
  value = resource.libvirt_domain.vm.network_interface
}