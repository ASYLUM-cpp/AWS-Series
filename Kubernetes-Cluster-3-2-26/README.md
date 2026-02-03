# 🚀 Kubernetes Cluster on AWS with Terraform

A fully automated, production-ready Kubernetes cluster deployment on AWS using Infrastructure as Code.

![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=flat&logo=amazonaws&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=flat&logo=ubuntu&logoColor=white)

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Setup Guide](#-detailed-setup-guide)
- [Deploying Applications](#-deploying-applications)
- [File Structure](#-file-structure)
- [Network Configuration](#-network-configuration)
- [Troubleshooting](#-troubleshooting)
- [Cleanup](#-cleanup)
- [Contributing](#-contributing)

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                   │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                              │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │              Public Subnet (10.0.1.0/24)                    │  │  │
│  │  │                                                             │  │  │
│  │  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │  │  │
│  │  │   │ k8s-master  │  │k8s-worker-1 │  │k8s-worker-2 │        │  │  │
│  │  │   │             │  │             │  │             │        │  │  │
│  │  │   │ • API Server│  │ • Kubelet   │  │ • Kubelet   │        │  │  │
│  │  │   │ • etcd      │  │ • Containerd│  │ • Containerd│        │  │  │
│  │  │   │ • Scheduler │  │ • NGINX     │  │ • NGINX     │        │  │  │
│  │  │   │ • Controller│  │ • Pods      │  │ • Pods      │        │  │  │
│  │  │   └─────────────┘  └─────────────┘  └─────────────┘        │  │  │
│  │  │         │                 │                 │               │  │  │
│  │  │         └────────────────┼────────────────┘               │  │  │
│  │  │                          │                                  │  │  │
│  │  │              ┌───────────┴───────────┐                     │  │  │
│  │  │              │   Flannel Network     │                     │  │  │
│  │  │              │   (10.244.0.0/16)     │                     │  │  │
│  │  │              └───────────────────────┘                     │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                              │                                     │  │
│  │                    ┌─────────┴─────────┐                          │  │
│  │                    │ Internet Gateway  │                          │  │
│  │                    └─────────┬─────────┘                          │  │
│  └──────────────────────────────┼────────────────────────────────────┘  │
│                                 │                                        │
└─────────────────────────────────┼────────────────────────────────────────┘
                                  │
                            🌐 Internet
```

### Infrastructure Components

| Component | Specification | Purpose |
|-----------|--------------|---------|
| **VPC** | 10.0.0.0/16 | Isolated network environment |
| **Public Subnet** | 10.0.1.0/24 | Host all K8s nodes |
| **Internet Gateway** | Attached to VPC | Enable internet access |
| **Security Group** | Custom rules | Control traffic flow |
| **EC2 Instances** | m7i-flex.large | K8s master and worker nodes |

### Node Specifications

| Node | Instance Type | vCPU | RAM | Role |
|------|--------------|------|-----|------|
| k8s-master | m7i-flex.large | 2 | 8 GB | Control Plane |
| k8s-worker-1 | m7i-flex.large | 2 | 8 GB | Workload |
| k8s-worker-2 | m7i-flex.large | 2 | 8 GB | Workload |

---

## ✨ Features

- **🔧 Fully Automated**: All software pre-installed via user-data scripts
- **🏗 Infrastructure as Code**: Reproducible deployments with Terraform
- **🔒 Security First**: Properly configured security groups with minimal exposure
- **🌐 Production Ready**: Flannel CNI for pod networking
- **📦 Container Runtime**: Containerd with SystemdCgroup enabled
- **🔄 Easy Scaling**: Add more workers by duplicating Terraform resources
- **💰 Cost Effective**: Uses AWS free tier eligible instances

---

## 📝 Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| AWS CLI | v2.x | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| Terraform | >= 1.0 | [Install Guide](https://developer.hashicorp.com/terraform/downloads) |
| SSH Client | Any | Built-in on most systems |

### AWS Configuration

```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

### SSH Key Pair

Ensure you have the `bastion-11-1-26.pem` file in the project directory.

---

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd Kubernetes_Cluster-3-2-16

# 2. Generate public key from PEM file
ssh-keygen -y -f bastion-11-1-26.pem > bastion-11-1-26.pub

# 3. Initialize and deploy
terraform init
terraform apply -auto-approve

# 4. Wait 3-5 minutes for software installation, then SSH to master
ssh -i bastion-11-1-26.pem ubuntu@<MASTER_PUBLIC_IP>

# 5. Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 6. Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 7. Install Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 8. Get join command for workers
kubeadm token create --print-join-command
```

---

## 📖 Detailed Setup Guide

### Step 1: Generate SSH Public Key

```bash
ssh-keygen -y -f bastion-11-1-26.pem > bastion-11-1-26.pub
```

### Step 2: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 3: Review Infrastructure Plan

```bash
terraform plan
```

This will show you all resources that will be created:
- 1 VPC
- 1 Internet Gateway
- 1 Public Subnet
- 1 Route Table
- 1 Security Group
- 1 Key Pair
- 3 EC2 Instances

### Step 4: Deploy Infrastructure

```bash
terraform apply -auto-approve
```

Wait for completion. Note the output values:
```
master_public_ip = "x.x.x.x"
worker_1_public_ip = "x.x.x.x"
worker_2_public_ip = "x.x.x.x"
```

### Step 5: Wait for Software Installation

The user-data scripts automatically install:
- containerd (container runtime)
- kubeadm, kubelet, kubectl
- Required kernel modules
- NGINX (on workers)

Check installation progress:
```bash
ssh -i bastion-11-1-26.pem ubuntu@<MASTER_IP>
tail -f /var/log/user-data.log
```

Wait until you see: `Kubernetes prerequisites installed successfully`

### Step 6: Initialize Kubernetes Master

```bash
# SSH to master
ssh -i bastion-11-1-26.pem ubuntu@<MASTER_IP>

# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

### Step 7: Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 8: Install Flannel Network Plugin

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### Step 9: Join Worker Nodes

Get the join command from master:
```bash
kubeadm token create --print-join-command
```

SSH to each worker and run the join command:
```bash
# Worker 1
ssh -i bastion-11-1-26.pem ubuntu@<WORKER_1_IP>
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>

# Worker 2
ssh -i bastion-11-1-26.pem ubuntu@<WORKER_2_IP>
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Step 10: Verify Cluster

```bash
# On master node
kubectl get nodes
```

Expected output:
```
NAME           STATUS   ROLES           AGE   VERSION
k8s-master     Ready    control-plane   5m    v1.30.x
k8s-worker-1   Ready    <none>          2m    v1.30.x
k8s-worker-2   Ready    <none>          1m    v1.30.x
```

---

## 🚀 Deploying Applications

### Deploy NGINX Web Server

#### 1. Create Deployment

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
EOF
```

#### 2. Create NodePort Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
EOF
```

#### 3. Configure NGINX Reverse Proxy (on workers)

SSH to each worker and edit `/etc/nginx/sites-available/default`:

**Worker 1:**
```nginx
server {
    listen 80;
    server_name <WORKER_1_PUBLIC_IP>;

    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Restart NGINX:
```bash
sudo systemctl restart nginx
```

#### 4. Access Your Application

Open in browser:
- `http://<WORKER_1_PUBLIC_IP>`
- `http://<WORKER_2_PUBLIC_IP>`

---

## 📁 File Structure

```
Kubernetes_Cluster-3-2-16/
├── main.tf              # Main Terraform configuration
│                        # - VPC, Subnet, Internet Gateway
│                        # - Security Groups
│                        # - EC2 Instances with user-data
├── variables.tf         # Variable definitions
│                        # - AWS region
│                        # - Instance type
│                        # - Key name
├── outputs.tf           # Output definitions
│                        # - Public/Private IPs
│                        # - SSH commands
├── k8s-setup.sh         # Kubernetes setup script (reference)
├── master-init.sh       # Master initialization script (reference)
├── bastion-11-1-26.pem  # SSH private key
├── bastion-11-1-26.pub  # SSH public key (generated)
└── README.md            # This documentation
```

---

## 🔐 Network Configuration

### Security Group Rules

| Type | Port Range | Protocol | Source | Purpose |
|------|------------|----------|--------|---------|
| SSH | 22 | TCP | 0.0.0.0/0 | Remote access |
| HTTP | 80 | TCP | 0.0.0.0/0 | Web traffic |
| HTTPS | 443 | TCP | 0.0.0.0/0 | Secure web traffic |
| K8s API | 6443 | TCP | 0.0.0.0/0 | Kubernetes API server |
| NodePort | 30000-32767 | TCP | 0.0.0.0/0 | K8s NodePort services |
| etcd | 2379-2380 | TCP | VPC | etcd communication |
| Kubelet | 10250 | TCP | VPC | Kubelet API |
| Flannel | 8472 | UDP | VPC | VXLAN overlay |
| All | All | All | VPC | Internal communication |

### Pod Network

- **CIDR**: 10.244.0.0/16
- **CNI Plugin**: Flannel
- **Mode**: VXLAN

---

## 🔧 Troubleshooting

### Check User-Data Script Execution

```bash
# View installation logs
cat /var/log/user-data.log

# Check cloud-init status
cloud-init status
```

### Verify Containerd

```bash
sudo systemctl status containerd
sudo ctr containers list
```

### Verify Kubelet

```bash
sudo systemctl status kubelet
sudo journalctl -xeu kubelet
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Nodes not Ready | Wait for Flannel pods to be Running |
| kubeadm init fails | Check swap is disabled: `free -h` |
| Pods stuck in Pending | Check node resources: `kubectl describe node` |
| Cannot reach NodePort | Verify security group allows port 30000-32767 |

### Reset Kubernetes (if needed)

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube
```

---

## 🧹 Cleanup

### Destroy All Resources

```bash
terraform destroy -auto-approve
```

This will remove:
- All EC2 instances
- Security groups
- Subnets
- Internet Gateway
- VPC
- Key pair

---

## 📊 Cost Estimation

| Resource | Type | Estimated Cost |
|----------|------|----------------|
| EC2 (3x) | m7i-flex.large | Free tier / ~$0.10/hr each |
| EBS (3x) | 20GB gp3 | ~$5/month total |
| Data Transfer | Outbound | Varies |

**Note**: m7i-flex.large is eligible for AWS free tier (750 hours/month for 12 months).

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Flannel CNI](https://github.com/flannel-io/flannel)

---

**Happy Clustering! 🎉**
