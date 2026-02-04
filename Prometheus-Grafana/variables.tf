# Variables for Kubernetes Cluster

variable "aws_region" {
  description = "AWS region to deploy the Kubernetes cluster"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for all nodes"
  type        = string
  default     = "m7i-flex.large"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "bastion-11-1-26"
}
