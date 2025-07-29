terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "~> 0.8.3"
    }
  }
}

# Configurar el provider libvirt
provider "libvirt" {
  uri = "qemu:///system"
}

# Data source para obtener información del nodo libvirt
data "libvirt_node_info" "host" {}

# Mostrar el resultado obtenido por el data source
output "libvirt_node_info_result" {
  value = data.libvirt_node_info.host
}