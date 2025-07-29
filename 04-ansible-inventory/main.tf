locals {
  hosts = {
    "web-01" = {
      ip_address = "192.168.10.2"
      user       = "mikroways"
    }
    "desktop-01" = {
      ip_address = "192.168.1.50"
      user       = "car"
    }
    "web-02" = {
      ip_address = "192.168.10.3"
      user       = "webadm"
    }
    "db-01" = {
      ip_address = "192.168.20.34"
      user       = "dbadm"
    }
    "db-02" = {
      ip_address = "192.168.20.41"
      user       = "dbadmin"
    }
  }

  webservers = ["web-01", "web-02"]
  databases  = ["db-01", "db-02"]

  yaml_inventory = <<EOT
all:
  children:
    web:
${join("\n", [for h in local.webservers : "      ${h}:\n        ansible_host: ${local.hosts[h].ip_address}\n        ansible_user: ${local.hosts[h].user}"])}
    db:
${join("\n", [for h in local.databases : "      ${h}:\n        ansible_host: ${local.hosts[h].ip_address}\n        ansible_user: ${local.hosts[h].user}"])}
EOT

  ini_inventory = <<EOT
[web]
${join("\n", [for h in local.webservers : "${h} ansible_host=${local.hosts[h].ip_address} ansible_user=${local.hosts[h].user}"])}

[db]
${join("\n", [for h in local.databases : "${h} ansible_host=${local.hosts[h].ip_address} ansible_user=${local.hosts[h].user}"])}
EOT
}

output "inventario_ansible" {
  value = var.formato == "yaml" ? local.yaml_inventory : local.ini_inventory
}
