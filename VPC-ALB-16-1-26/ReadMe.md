# AWS ALB + Auto Scaling + Private EC2 (Production-Style Setup)

## 📌 Overview

This project demonstrates a **real-world, production-grade AWS backend architecture** using:

* Application Load Balancer (ALB)
* EC2 instances in **private subnets**
* Auto Scaling Group (ASG)
* NAT Gateway for outbound internet access
* CloudWatch for monitoring & scaling
* Frontend load testing via ALB

The goal was **not just to deploy infrastructure**, but to **understand how it behaves under real traffic, failures, and scaling conditions**.

---

## 🏗️ Architecture

```
User (Browser / Load Test)
        |
        v
+----------------------+
| Application Load     |
| Balancer (Public)    |
+----------------------+
        |
        v
+----------------------+      +----------------------+
| EC2 Instance         |      | EC2 Instance         |
| (Private Subnet)     | ...  | (Private Subnet)     |
| Nginx Web Server     |      | Nginx Web Server     |
+----------------------+      +----------------------+
        ^                       ^
        |                       |
        +------ Auto Scaling Group ------+
```

### Key Characteristics

* EC2 instances **do NOT have public IPs**
* Users **cannot access EC2 directly**
* Only the **ALB can reach the EC2s**
* Instances are **ephemeral and replaceable**
* Scaling is **horizontal**, not vertical

---

## 🌐 Networking Setup

### VPC

* Custom VPC with CIDR: `10.0.0.0/16`

### Subnets

* **Public Subnets**

  * ALB
  * Bastion Host
* **Private Subnets**

  * EC2 instances (ASG)

### Internet Access

* Internet Gateway → Public subnets
* **NAT Gateway** → Private subnets (critical)

---

## 🔐 Security Groups

### ALB Security Group

* Inbound:

  * HTTP (80) from `0.0.0.0/0`
* Outbound:

  * HTTP (80) to EC2 security group

### EC2 Security Group

* Inbound:

  * HTTP (80) **only from ALB SG**
  * SSH (22) **only from Bastion SG**
* Outbound:

  * All traffic (needed for updates, package installs)

---

## 🚀 Compute Layer

### Launch Template

* Amazon Linux AMI
* Instance type: `t3.micro` (later tested with larger sizes)
* Nginx installed via `user_data`
* Instance metadata (ID, private IP) fetched via IMDSv2

Each instance serves a page like:

```
Hello from EC2
Instance ID: i-0abcd1234
Private IP: 10.0.x.x
```

This proves:

* Load balancing is working
* Requests are rotating across instances

---

## ⚖️ Load Balancer (ALB)

* Public-facing
* Routes traffic to a Target Group
* Health checks on `/`
* Automatically removes unhealthy instances
* Works transparently with Auto Scaling Group

---

## 📈 Auto Scaling Group

* Manages EC2 lifecycle
* Replaces unhealthy instances
* Scales horizontally when triggered
* Instances are **never manually managed**

---

## 🔍 Observability (CloudWatch)

Monitored:

* CPUUtilization
* ALB RequestCount
* Target group health
* ASG activity history

---

## 🧪 Frontend Load Testing

### Tool Used

* `hey` (HTTP load generator)

Example command:

```bash
hey -z 2m -c 500 http://<ALB-DNS>/
```

This sends **concurrent HTTP requests through the ALB**, exactly like real users.

---

## ❗ Major Issues Faced (And What Was Learned)

### 1️⃣ ALB Health Checks Failing Repeatedly

**Symptom**

* Instances kept being marked unhealthy
* ASG kept terminating and recreating them

**Root Cause**

* Private EC2 instances had **no NAT Gateway**
* Could not install Nginx or fetch updates
* Health check endpoint never came up

**Fix**

* Added NAT Gateway
* Updated private route tables

✅ Lesson:

> **Private EC2s still need outbound internet access.**

---

### 2️⃣ Could Not SSH into Private EC2 Instances

**Symptom**

* SSH command hung or failed
* Even when instances were "running"

**Root Cause**

* EC2 security group did not allow SSH **from Bastion SG**
* Route tables worked correctly, SG did not

**Fix**

* Allowed SSH from Bastion security group

✅ Lesson:

> **Routing ≠ Security. SG rules matter more than routes.**

---

### 3️⃣ CPU Stayed at ~5% Even Under Heavy Load

**Symptom**

* CPUUtilization stayed around 5%
* Yet response times reached **15–17 seconds**

**Why This Happens**

* Static Nginx pages are **extremely cheap**
* Requests queued in Nginx connection backlog
* CPU idle ≠ system idle

**Important Insight**

> **Latency can increase without CPU increasing.**

CPU is NOT the only bottleneck.

---

### 4️⃣ High Latency but Low CPU

**Root Causes**

* Nginx connection limits
* Burstable instance network limits
* Request queueing
* Small instance type (`t3.micro`)

**Fixes**

* Increased concurrency awareness
* Added CPU-heavy request handling
* Tuned Nginx workers
* Considered scaling on ALB metrics instead of CPU

---

## 🔥 Forcing Real CPU Load via Frontend

To properly test horizontal scaling:

* Each HTTP request performs **CPU work**
* Requests are sent **through the ALB**
* CPU spikes naturally
* CloudWatch alarms trigger scaling

This mimics **real production traffic**, not artificial SSH-based stress.

---

## ✅ Final Result

* Load balancer distributes traffic correctly
* EC2 instances are healthy and replaceable
* ASG scales horizontally under load
* Private networking works securely
* Latency stays controlled when scaling kicks in
* Frontend load accurately reflects backend behavior

---

## 🧠 Key Takeaways

* CPU is **not the only scaling metric**
* Latency often comes from **queueing, not compute**
* NAT Gateway is mandatory for private workloads
* ALB + ASG is **the backbone of modern web backends**
* Observability matters more than assumptions
* Hands-on failure teaches more than diagrams

---

## 📦 Future Improvements

* Scale on `RequestCountPerTarget` instead of CPU
* Add HTTPS with ACM
* Add blue/green deployments
* Convert full setup to Terraform-only
* Add structured logging and tracing

---

## 🏁 Conclusion

This was not a toy setup.

This was a **real cloud engineering exercise** that exposed:

* Hidden bottlenecks
* Misleading metrics
* Real scaling behavior
* Production realities

Exactly how modern systems behave.

---

If you want, I can also:

* Shorten this for recruiters
* Add diagrams
* Convert this into a blog post
* Or tune it for a GitHub portfolio README

Just tell me 👍

