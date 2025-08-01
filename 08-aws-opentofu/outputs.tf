# outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = module.compute.instance_public_ips
}

output "instance_public_dns" {
  description = "Public DNS names of the EC2 instances"
  value       = module.compute.instance_public_dns
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = module.networking.web_security_group_id
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = module.compute.key_pair_name
}

output "web_urls" {
  description = "URLs to access the web servers"
  value       = [for ip in module.compute.instance_public_ips : "http://${ip}"]
}