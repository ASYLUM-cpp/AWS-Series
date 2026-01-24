# =============================================================================
# LAB 1: Stateful Compute on AWS (EBS vs EFS)
# Region: us-west-2
# =============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get available AZs in us-west-2
data "aws_availability_zones" "available" {
  state = "available"
}

# Get a public subnet from the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the first subnet details
data "aws_subnet" "first" {
  id = data.aws_subnets.default.ids[0]
}

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
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

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ebs-efs-lab-ec2-sg-24-1-26"
  description = "Security group for EBS/EFS lab EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ebs-efs-lab-ec2-sg-24-1-26"
  }
}

# Security group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "ebs-efs-lab-efs-sg-24-1-26"
  description = "Security group for EFS mount targets"
  vpc_id      = data.aws_vpc.default.id

  # NFS access from EC2 security group
  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ebs-efs-lab-efs-sg-24-1-26"
  }
}

# =============================================================================
# EBS INSTANCE (Instance A)
# =============================================================================

resource "aws_instance" "ebs_instance" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  key_name                    = "#"
  subnet_id                   = data.aws_subnet.first.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name = "ebs-instance-24-1-26"
  }
}

# Additional EBS volume for ebs-instance
resource "aws_ebs_volume" "data_volume" {
  availability_zone = data.aws_subnet.first.availability_zone
  size              = 5
  type              = "gp3"

  tags = {
    Name = "ebs-data-volume-24-1-26"
  }
}

# Attach EBS volume to ebs-instance
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.ebs_instance.id
}

# =============================================================================
# EFS FILE SYSTEM
# =============================================================================

resource "aws_efs_file_system" "shared_efs" {
  creation_token   = "ebs-efs-lab-shared-24-1-26"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = {
    Name = "ebs-efs-lab-shared-24-1-26"
  }
}

# EFS mount target in the subnet
resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.shared_efs.id
  subnet_id       = data.aws_subnet.first.id
  security_groups = [aws_security_group.efs_sg.id]
}

# =============================================================================
# EFS INSTANCES (Instance B and C)
# =============================================================================

resource "aws_instance" "efs_instance_1" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  key_name                    = "#"
  subnet_id                   = data.aws_subnet.first.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  # User data to install EFS utils and mount EFS
  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-efs-utils nfs-utils
              mkdir -p /data-efs
              # Wait for EFS mount target to be available
              for i in {1..30}; do
                mount -t efs -o tls ${aws_efs_file_system.shared_efs.id}:/ /data-efs && break
                echo "Mount attempt $i failed, retrying in 10 seconds..."
                sleep 10
              done
              echo "${aws_efs_file_system.shared_efs.id}:/ /data-efs efs _netdev,tls 0 0" >> /etc/fstab
              EOF

  tags = {
    Name = "efs-instance-24-1-26"
  }

  depends_on = [aws_efs_mount_target.efs_mount]
}

resource "aws_instance" "efs_instance_2" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  key_name                    = "#"
  subnet_id                   = data.aws_subnet.first.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  # User data to install EFS utils and mount EFS
  user_data = <<-EOF
              #!/bin/bash
              yum install -y amazon-efs-utils nfs-utils
              mkdir -p /data-efs
              # Wait for EFS mount target to be available
              for i in {1..30}; do
                mount -t efs -o tls ${aws_efs_file_system.shared_efs.id}:/ /data-efs && break
                echo "Mount attempt $i failed, retrying in 10 seconds..."
                sleep 10
              done
              echo "${aws_efs_file_system.shared_efs.id}:/ /data-efs efs _netdev,tls 0 0" >> /etc/fstab
              EOF

  tags = {
    Name = "efs-instance-2-24-1-26"
  }

  depends_on = [aws_efs_mount_target.efs_mount]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "ebs_instance_public_ip" {
  description = "Public IP of the EBS instance"
  value       = aws_instance.ebs_instance.public_ip
}

output "efs_instance_1_public_ip" {
  description = "Public IP of the first EFS instance"
  value       = aws_instance.efs_instance_1.public_ip
}

output "efs_instance_2_public_ip" {
  description = "Public IP of the second EFS instance"
  value       = aws_instance.efs_instance_2.public_ip
}

output "efs_file_system_id" {
  description = "EFS File System ID for mounting"
  value       = aws_efs_file_system.shared_efs.id
}

output "efs_dns_name" {
  description = "EFS DNS name for mounting"
  value       = aws_efs_file_system.shared_efs.dns_name
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    ebs_instance   = "ssh -i #m ec2-user@${aws_instance.ebs_instance.public_ip}"
    efs_instance_1 = "ssh -i # ec2-user@${aws_instance.efs_instance_1.public_ip}"
    efs_instance_2 = "ssh -i # ec2-user@${aws_instance.efs_instance_2.public_ip}"
  }
}

output "ebs_mount_commands" {
  description = "Commands to run on ebs-instance to mount EBS volume"
  value       = <<-EOT
    # On ebs-instance, run:
    lsblk
    sudo mkfs -t xfs /dev/xvdf
    sudo mkdir /data-ebs
    sudo mount /dev/xvdf /data-ebs
    echo "EBS DATA - Instance A" | sudo tee /data-ebs/test.txt
    cat /data-ebs/test.txt
  EOT
}

output "efs_mount_commands" {
  description = "Commands to run on efs-instances to mount EFS"
  value       = <<-EOT
    # On efs-instance and efs-instance-2, run:
    sudo mount -t efs ${aws_efs_file_system.shared_efs.id}:/ /data-efs
    
    # Test on efs-instance:
    echo "EFS DATA - Instance B" | sudo tee /data-efs/shared.txt
    cat /data-efs/shared.txt
    
    # Verify on efs-instance-2:
    cat /data-efs/shared.txt
  EOT
}

