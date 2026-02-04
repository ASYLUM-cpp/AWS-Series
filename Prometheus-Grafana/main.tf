# Kubernetes Cluster Terraform Configuration
# Created: February 3, 2026

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-cluster-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-cluster-igw"
  }
}

# Public Subnet
resource "aws_subnet" "k8s_public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "k8s_public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-public-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "k8s_public_rta" {
  subnet_id      = aws_subnet.k8s_public_subnet.id
  route_table_id = aws_route_table.k8s_public_rt.id
}

# Security Group for Kubernetes Cluster
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for Kubernetes cluster"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API server"
  }

  # etcd server client API
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "etcd server client API"
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Kubelet API"
  }

  # kube-scheduler
  ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kube-scheduler"
  }

  # kube-controller-manager
  ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "kube-controller-manager"
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Services"
  }

  # Flannel VXLAN
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Flannel VXLAN"
  }

  # Allow all internal traffic within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "All internal VPC traffic"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "k8s-cluster-sg"
  }
}

# Key Pair
resource "aws_key_pair" "k8s_key" {
  key_name   = "bastion-11-1-26"
  public_key = file("${path.module}/bastion-11-1-26.pub")

  tags = {
    Name = "k8s-cluster-keypair"
  }
}

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Kubernetes Master Node
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m7i-flex.large"
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log) 2>&1
              
              # Set hostname
              hostnamectl set-hostname k8s-master
              echo "127.0.0.1 k8s-master" >> /etc/hosts
              
              # Disable swap
              swapoff -a
              sed -i '/swap/d' /etc/fstab
              
              # Load required kernel modules
              cat <<MODULES | tee /etc/modules-load.d/k8s.conf
              overlay
              br_netfilter
              MODULES
              
              modprobe overlay
              modprobe br_netfilter
              
              # Set sysctl parameters
              cat <<SYSCTL | tee /etc/sysctl.d/k8s.conf
              net.bridge.bridge-nf-call-iptables  = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward                 = 1
              SYSCTL
              
              sysctl --system
              
              # Install containerd
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update
              apt-get install -y containerd.io
              
              # Configure containerd
              mkdir -p /etc/containerd
              containerd config default | tee /etc/containerd/config.toml
              sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
              systemctl restart containerd
              systemctl enable containerd
              
              # Install Kubernetes components
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
              
              echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
              
              apt-get update
              apt-get install -y kubelet kubeadm kubectl
              apt-mark hold kubelet kubeadm kubectl
              
              systemctl enable kubelet
              
              echo "Kubernetes prerequisites installed successfully on master node" > /var/log/k8s-setup-complete.log
              EOF

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

# Kubernetes Worker Node 1
resource "aws_instance" "k8s_worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m7i-flex.large"
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log) 2>&1
              
              # Set hostname
              hostnamectl set-hostname k8s-worker-1
              echo "127.0.0.1 k8s-worker-1" >> /etc/hosts
              
              # Disable swap
              swapoff -a
              sed -i '/swap/d' /etc/fstab
              
              # Load required kernel modules
              cat <<MODULES | tee /etc/modules-load.d/k8s.conf
              overlay
              br_netfilter
              MODULES
              
              modprobe overlay
              modprobe br_netfilter
              
              # Set sysctl parameters
              cat <<SYSCTL | tee /etc/sysctl.d/k8s.conf
              net.bridge.bridge-nf-call-iptables  = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward                 = 1
              SYSCTL
              
              sysctl --system
              
              # Install containerd
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update
              apt-get install -y containerd.io
              
              # Configure containerd
              mkdir -p /etc/containerd
              containerd config default | tee /etc/containerd/config.toml
              sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
              systemctl restart containerd
              systemctl enable containerd
              
              # Install Kubernetes components
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
              
              echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
              
              apt-get update
              apt-get install -y kubelet kubeadm kubectl nginx
              apt-mark hold kubelet kubeadm kubectl
              
              systemctl enable kubelet
              systemctl enable nginx
              
              echo "Kubernetes prerequisites installed successfully on worker-1" > /var/log/k8s-setup-complete.log
              EOF

  tags = {
    Name = "k8s-worker-1"
    Role = "worker"
  }
}

# Kubernetes Worker Node 2
resource "aws_instance" "k8s_worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m7i-flex.large"
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.k8s_public_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log) 2>&1
              
              # Set hostname
              hostnamectl set-hostname k8s-worker-2
              echo "127.0.0.1 k8s-worker-2" >> /etc/hosts
              
              # Disable swap
              swapoff -a
              sed -i '/swap/d' /etc/fstab
              
              # Load required kernel modules
              cat <<MODULES | tee /etc/modules-load.d/k8s.conf
              overlay
              br_netfilter
              MODULES
              
              modprobe overlay
              modprobe br_netfilter
              
              # Set sysctl parameters
              cat <<SYSCTL | tee /etc/sysctl.d/k8s.conf
              net.bridge.bridge-nf-call-iptables  = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward                 = 1
              SYSCTL
              
              sysctl --system
              
              # Install containerd
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update
              apt-get install -y containerd.io
              
              # Configure containerd
              mkdir -p /etc/containerd
              containerd config default | tee /etc/containerd/config.toml
              sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
              systemctl restart containerd
              systemctl enable containerd
              
              # Install Kubernetes components
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
              
              echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
              
              apt-get update
              apt-get install -y kubelet kubeadm kubectl nginx
              apt-mark hold kubelet kubeadm kubectl
              
              systemctl enable kubelet
              systemctl enable nginx
              
              echo "Kubernetes prerequisites installed successfully on worker-2" > /var/log/k8s-setup-complete.log
              EOF

  tags = {
    Name = "k8s-worker-2"
    Role = "worker"
  }
}
