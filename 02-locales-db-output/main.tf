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

  databases = ["db-01", "db-02"]
  webservers = ["user-01", "user-02" ]
}

output "db_ips" {
  value = [
    for db in local.databases :
    "${db}: ${local.hosts[db].user}@${local.hosts[db].ip_address}"
  ]
}
