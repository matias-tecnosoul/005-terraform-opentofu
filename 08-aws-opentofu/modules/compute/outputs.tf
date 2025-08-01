# modules/compute/outputs.tf

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = aws_instance.web[*].public_ip
}

output "instance_public_dns" {
  description = "Public DNS names of the EC2 instances"
  value       = aws_instance.web[*].public_dns
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = aws_instance.web[*].private_ip
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.main.key_name
}

output "elastic_ips" {
  description = "Elastic IP addresses (if created)"
  value       = aws_eip.web[*].public_ip
}