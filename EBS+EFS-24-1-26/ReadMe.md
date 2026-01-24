# AWS EBS vs EFS Lab

A Terraform-based lab demonstrating the difference between AWS block storage (EBS) and file storage (EFS).

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  ebs-instance   │     │   EBS Volume    │
│   (t3.micro)    │────▶│     (5GB)       │
└─────────────────┘     └─────────────────┘
        │
        │ Exclusive access
        │
┌─────────────────┐
│  efs-instance   │──────┐
│   (t3.micro)    │      │
└─────────────────┘      │     ┌─────────────────┐
                         ├────▶│   EFS (Shared)  │
┌─────────────────┐      │     └─────────────────┘
│ efs-instance-2  │──────┘
│   (t3.micro)    │
└─────────────────┘
        │
        │ Shared access
```

## Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| EC2 Instance | ebs-instance-24-1-26 | Demonstrates EBS usage |
| EC2 Instance | efs-instance-24-1-26 | EFS client #1 |
| EC2 Instance | efs-instance-2-24-1-26 | EFS client #2 |
| EBS Volume | ebs-data-volume-24-1-26 | 5GB block storage |
| EFS File System | ebs-efs-lab-shared-24-1-26 | Shared network storage |
| Security Group | ebs-efs-lab-ec2-sg-24-1-26 | SSH access (port 22) |
| Security Group | ebs-efs-lab-efs-sg-24-1-26 | NFS access (port 2049) |

## Prerequisites

- AWS CLI configured
- Terraform installed
- Key pair `bastion-11-1-26.pem` in us-west-2

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Usage

### EBS Instance

SSH into the EBS instance and mount the attached volume:

```bash
ssh -i bastion-11-1-26.pem ec2-user@<EBS_INSTANCE_IP>

# Check attached volumes
lsblk

# Format the EBS volume (first time only)
sudo mkfs -t xfs /dev/xvdf

# Create mount point and mount
sudo mkdir /data-ebs
sudo mount /dev/xvdf /data-ebs

# Test write
echo "EBS DATA - Instance A" | sudo tee /data-ebs/test.txt
cat /data-ebs/test.txt
```

### EFS Instances

SSH into the first EFS instance:

```bash
ssh -i bastion-11-1-26.pem ec2-user@<EFS_INSTANCE_1_IP>

# Check if EFS is mounted (auto-mounted via user_data)
df -h | grep efs

# If not mounted, mount manually
sudo mount -t efs -o tls <EFS_ID>:/ /data-efs

# Write test file
echo "EFS DATA - Shared" | sudo tee /data-efs/shared.txt
```

SSH into the second EFS instance and verify shared access:

```bash
ssh -i bastion-11-1-26.pem ec2-user@<EFS_INSTANCE_2_IP>

# Read the same file
cat /data-efs/shared.txt
```

## EBS vs EFS Comparison

| Feature | EBS | EFS |
|---------|-----|-----|
| Storage Type | Block | File (NFS) |
| Access | Single EC2 | Multiple EC2s |
| Use Case | Databases, boot volumes | Shared content, web uploads |
| Availability | Single AZ | Multi-AZ |
| Scaling | Manual resize | Automatic |

## Clean Up

```bash
terraform destroy
```

## Region

Deployed in **us-west-2** (Oregon).
