# Outputs for Kubernetes Cluster

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.k8s_vpc.id
}

output "master_public_ip" {
  description = "Public IP of the Kubernetes master node"
  value       = aws_instance.k8s_master.public_ip
}

output "master_private_ip" {
  description = "Private IP of the Kubernetes master node"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_1_public_ip" {
  description = "Public IP of worker node 1"
  value       = aws_instance.k8s_worker_1.public_ip
}

output "worker_1_private_ip" {
  description = "Private IP of worker node 1"
  value       = aws_instance.k8s_worker_1.private_ip
}

output "worker_2_public_ip" {
  description = "Public IP of worker node 2"
  value       = aws_instance.k8s_worker_2.public_ip
}

output "worker_2_private_ip" {
  description = "Private IP of worker node 2"
  value       = aws_instance.k8s_worker_2.private_ip
}

output "ssh_command_master" {
  description = "SSH command to connect to master node"
  value       = "ssh -i bastion-11-1-26.pem ubuntu@${aws_instance.k8s_master.public_ip}"
}

output "ssh_command_worker_1" {
  description = "SSH command to connect to worker node 1"
  value       = "ssh -i bastion-11-1-26.pem ubuntu@${aws_instance.k8s_worker_1.public_ip}"
}

output "ssh_command_worker_2" {
  description = "SSH command to connect to worker node 2"
  value       = "ssh -i bastion-11-1-26.pem ubuntu@${aws_instance.k8s_worker_2.public_ip}"
}
