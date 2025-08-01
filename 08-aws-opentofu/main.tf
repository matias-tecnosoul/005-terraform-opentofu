# main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Local values for common configuration
locals {
  common_tags = {
    Organization = "Mikroways"
    Project      = var.project_name
    Environment  = var.environment
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>¡Hola desde Mikroways!</h1><p>Servidor: $(hostname)</p><p>Creado con módulos OpenTofu</p>" > /var/www/html/index.html
    EOF
}

# Networking module
module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_count = var.public_subnet_count
  allowed_ssh_cidrs  = ["${var.my_ip}/32"]
  common_tags        = local.common_tags
}

# Compute module
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  instance_count     = var.instance_count
  instance_type      = var.instance_type
  subnet_ids         = module.networking.public_subnet_ids
  security_group_id  = module.networking.web_security_group_id
  public_key_content = file(var.public_key_path)
  user_data_script   = base64encode(local.user_data)
  create_eip         = var.create_eip
  common_tags        = local.common_tags
}
