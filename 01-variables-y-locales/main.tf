terraform {
  required_version = "~> 1.10.0"
}

variable "name" {
  type    = string
  default = "Mikroways"
}

locals {
  name = "Hello ${var.name}"
}

output "message" {
  value = local.name
}
