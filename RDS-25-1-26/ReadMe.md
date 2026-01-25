# AWS RDS MySQL Setup with Terraform

A complete Infrastructure as Code (IaC) setup for deploying a secure RDS MySQL database with an EC2 bastion host on AWS using Terraform.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VPC (10.0.0.0/16)                              │
│                                                                             │
│  ┌──────────────────────────────┐    ┌──────────────────────────────────┐  │
│  │     Public Subnet (AZ-a)     │    │      Private Subnets (RDS)       │  │
│  │        10.0.1.0/24           │    │                                  │  │
│  │                              │    │  ┌────────────┐  ┌────────────┐  │  │
│  │  ┌────────────────────────┐  │    │  │   AZ-a     │  │   AZ-b     │  │  │
│  │  │    EC2 App Server      │  │    │  │10.0.10.0/24│  │10.0.20.0/24│  │  │
│  │  │    (t3.micro)          │──┼────┼──│            │  │            │  │  │
│  │  │                        │  │    │  └─────┬──────┘  └────────────┘  │  │
│  │  └────────────────────────┘  │    │        │                         │  │
│  │             │                │    │  ┌─────▼──────────────────────┐  │  │
│  └─────────────┼────────────────┘    │  │     RDS MySQL 8.0          │  │  │
│                │                     │  │     (db.t3.micro)          │  │  │
│                │                     │  │     Port: 3306             │  │  │
│       ┌────────▼────────┐            │  └────────────────────────────┘  │  │
│       │ Internet Gateway│            └──────────────────────────────────┘  │
│       └────────┬────────┘                                                  │
└────────────────┼───────────────────────────────────────────────────────────┘
                 │
            ┌────▼────┐
            │ Internet│
            └─────────┘
```

---

## 📋 Components

### Networking
| Resource | Details |
|----------|---------|
| **VPC** | CIDR: `10.0.0.0/16`, DNS hostnames enabled |
| **Internet Gateway** | Enables internet access for public subnet |
| **Public Subnet** | `10.0.1.0/24` in `us-west-2a` - Hosts EC2 |
| **Private Subnet A** | `10.0.10.0/24` in `us-west-2a` - Hosts RDS |
| **Private Subnet B** | `10.0.20.0/24` in `us-west-2b` - RDS subnet group requirement |

### Security Groups

#### EC2 Security Group
| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Inbound | 22 | TCP | 0.0.0.0/0 | SSH Access |
| Outbound | All | All | 0.0.0.0/0 | Internet Access |

#### RDS Security Group
| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Inbound | 3306 | TCP | EC2 Security Group | MySQL from EC2 only |
| Outbound | All | All | 0.0.0.0/0 | - |

### RDS MySQL Instance
| Setting | Value |
|---------|-------|
| Engine | MySQL 8.0 |
| Instance Class | db.t3.micro (Free Tier) |
| Storage | 20 GB gp3 (encrypted) |
| Database Name | appdb |
| Username | admin |
| Multi-AZ | Disabled (Free Tier) |
| Backup Retention | 0 days (Free Tier) |
| Public Access | ❌ Disabled |

### EC2 App Server
| Setting | Value |
|---------|-------|
| AMI | Amazon Linux 2023 (latest) |
| Instance Type | t3.micro |
| Key Pair | bastion-11-1-26 |
| Pre-installed | MariaDB client (mysql) |

---

## 🚀 Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- Existing key pair: `bastion-11-1-26`

### Commands

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Destroy when done
terraform destroy
```

---

## 🔌 Connecting to RDS

### Step 1: SSH into EC2
```bash
ssh -i bastion-11-1-26.pem ec2-user@<EC2_PUBLIC_IP>
```

### Step 2: Connect to MySQL
```bash
mysql -h <RDS_ENDPOINT> -u admin -p
```

The RDS endpoint and EC2 IP are provided as Terraform outputs after deployment.

---

## 📤 Terraform Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `ec2_public_ip` | Public IP of EC2 instance |
| `ec2_instance_id` | EC2 Instance ID |
| `rds_endpoint` | Full RDS endpoint (host:port) |
| `rds_address` | RDS hostname only |
| `rds_port` | MySQL port (3306) |
| `connection_command` | Ready-to-use mysql command |

---

## 🔒 Security Best Practices Implemented

- ✅ RDS in private subnets (no public access)
- ✅ Security group restricts MySQL access to EC2 only
- ✅ Storage encryption enabled
- ✅ EC2 acts as bastion/jump host
- ✅ Separate public and private route tables

---

## 💰 Cost Optimization (Free Tier)

- `db.t3.micro` instance class
- `t3.micro` EC2 instance
- Backup retention set to 0 days
- Multi-AZ disabled
- Single NAT Gateway avoided (private subnets have no internet)

---

## 📁 File Structure

```
RDS-25-1-26/
├── main.tf              # Complete Terraform configuration
├── terraform.tfstate    # State file (do not edit manually)
├── setup.txt            # Setup notes
└── README.md            # This file
```

---

## ⚠️ Important Notes

1. **Password**: Change `YourStrongPassword123!` in production
2. **SSH Key**: Ensure `bastion-11-1-26.pem` is available locally
3. **Region**: Configured for `us-west-2`
4. **Cleanup**: Run `terraform destroy` to avoid ongoing charges

---

*Infrastructure deployed with Terraform on AWS*
