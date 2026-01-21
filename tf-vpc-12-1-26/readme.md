
# Terraform Bastion Host Architecture (AWS)

This document explains the **end-to-end AWS infrastructure** that was built using **Terraform**, the design decisions behind it, and the lessons learned while validating and tearing it down.

The goal of this setup was **not just to make things work**, but to encode correct cloud architecture in a **reproducible, auditable, and cost-aware** way.

---

## 🎯 Objective

Build a secure AWS architecture where:

* A **bastion host** is the *only* entry point from the internet
* A **private EC2 instance** is fully isolated from direct internet access
* SSH access to the private instance is allowed **only via the bastion**
* The entire setup can be **created and destroyed reliably** using Terraform

---

## 🧱 High-Level Architecture

```
Internet
   |
[ Internet Gateway ]
   |
[ Public Subnet ]
   |
[ Bastion EC2 ]
   |
[ Private Subnet ]
   |
[ Private EC2 ]
```

Key principles:

* Public resources are explicitly public
* Private resources are explicitly isolated
* Access paths are intentional and enforced

---

## 🗂️ Project Structure

```
terraform-bastion-project/
├─ providers.tf        # Terraform & AWS provider configuration
├─ variables.tf        # Input variables (CIDRs, instance types, region)
├─ main.tf             # Networking, security groups, and EC2 resources
├─ outputs.tf          # Outputs like IP addresses (optional)
├─ terraform.tfvars    # Variable values (key pair name, region overrides)
```

This separation keeps the codebase readable and closer to real-world Terraform repositories.

---

## 🌐 Networking Layer

### VPC

* A dedicated VPC is created using a `/16` CIDR block
* DNS support and hostnames are enabled (required for EC2 usability)

### Subnets

* **Public Subnet**

  * Used only for the bastion host
  * Automatically assigns public IPs

* **Private Subnet**

  * Used for the application EC2
  * No public IP assignment

Both subnets are placed in the same availability zone for simplicity.

---

## 🌍 Internet Gateway & Routing

### Internet Gateway (IGW)

* Attached to the VPC
* Required for internet access from the public subnet

### Route Tables

* **Public Route Table**

  * Routes `0.0.0.0/0` traffic to the Internet Gateway
  * Associated only with the public subnet

* **Private Subnet Routing**

  * No route to the internet
  * No NAT Gateway used (intentional)

This ensures:

* Bastion has internet access
* Private EC2 is completely isolated from outbound and inbound internet traffic

---

## 🔐 Security Groups (Critical Design)

### Bastion Security Group

* **Ingress**:

  * SSH (port 22) allowed **only from the developer's public IP**
* **Egress**:

  * Allowed to all destinations (required to reach private EC2)

Purpose:

* Prevents open SSH access from the internet
* Enforces least-privilege access

---

### Private EC2 Security Group

* **Ingress**:

  * SSH (port 22) allowed **only from the bastion security group**
* **Egress**:

  * Allowed to all destinations (even though no internet route exists)

Purpose:

* Private EC2 cannot be accessed directly from the internet
* Even if it had a public IP, security groups would still block access

This SG-to-SG trust model is a **production-standard bastion pattern**.

---

## 🖥️ Compute Layer (EC2)

### AMI Selection

* Amazon Linux 2 AMI is fetched dynamically using a data source
* Avoids hardcoding AMI IDs
* Ensures region compatibility

---

### Bastion EC2

* Launched in the **public subnet**
* Has a **public IP address**
* Uses the bastion security group
* SSH key pair specified via variable

This instance acts as the **single controlled entry point**.

---

### Private EC2

* Launched in the **private subnet**
* **No public IP assigned**
* Uses the private EC2 security group
* Reachable only from the bastion

This instance represents a protected backend or application server.

---

## 🔑 SSH Access Flow

```
Laptop
  │
  └── SSH → Bastion (Public IP)
               │
               └── SSH → Private EC2 (Private IP)
```

* Direct SSH to private EC2 from the internet: ❌ blocked
* SSH to private EC2 via bastion: ✅ allowed

---

## 💰 Cost Considerations

* **No NAT Gateway** was used
* This avoids unnecessary hourly and data processing charges
* Suitable for learning, labs, and controlled environments

If private instances need outbound internet access in the future, a NAT Gateway can be added explicitly.

---

## 🔄 Terraform Lifecycle Validation

The following commands were tested successfully:

* `terraform init`
* `terraform plan`
* `terraform apply`
* `terraform destroy`

Results:

* Infrastructure created exactly as defined
* No orphaned resources
* Clean teardown without manual cleanup

This validates that the setup is **fully reproducible and safe to iterate on**.

---

## 🧠 Key Learnings

* Console-built infrastructure can hide subtle misconfigurations
* Terraform forces you to **declare intent explicitly**
* Security group design matters more than public/private IPs alone
* Cost awareness is part of good cloud architecture

Most importantly:

> If it can be destroyed and recreated reliably, it can be trusted.

---

## ✅ Conclusion

This project demonstrates a **correct bastion-host architecture** implemented using **Infrastructure as Code**.

It reflects real-world cloud engineering principles:

* Least privilege
* Explicit networking
* Reproducibility
* Cost control

This setup serves as a strong foundation for extending into:

* NAT Gateways
* Auto Scaling
* Load Balancers
* CI/CD-driven Terraform workflows
