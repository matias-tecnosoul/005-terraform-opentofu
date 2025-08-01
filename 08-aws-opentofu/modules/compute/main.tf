# modules/compute/main.tf

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-keypair"
  public_key = var.public_key_content

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-keypair"
  })
}

# EC2 Instance
resource "aws_instance" "web" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]

  user_data = var.user_data_script

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-server-${count.index + 1}"
    Type = "WebServer"
  })
}

# Elastic IP (opcional)
resource "aws_eip" "web" {
  count = var.create_eip ? var.instance_count : 0

  instance = aws_instance.web[count.index].id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-eip-${count.index + 1}"
  })

  depends_on = [aws_instance.web]
}