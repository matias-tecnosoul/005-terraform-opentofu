# modules/compute/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be created"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to assign to instances"
  type        = string
}

variable "public_key_content" {
  description = "Content of the SSH public key"
  type        = string
}

variable "user_data_script" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 8
}

variable "create_eip" {
  description = "Whether to create and assign Elastic IPs"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}