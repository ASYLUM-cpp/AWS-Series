# ECS Fargate Service with Application Load Balancer

This document explains the complete ECS + Fargate setup that was built, including **load balancing, health checks, logging, security, and auto scaling**. The goal of this setup is to run a **long-running containerized web application** in a production-style, AWS-native way without managing servers.

---

## 1. High-Level Architecture

```
User
  ↓
Application Load Balancer (ALB)
  ↓
ECS Service
  ↓
Fargate Tasks (Containers)
```

Key characteristics:

* No EC2 instances are managed manually
* Containers are always running
* Traffic is routed only to healthy containers
* ECS maintains desired state and availability

---

## 2. Core Components and Their Roles

### 2.1 ECS Cluster

The ECS cluster is a **logical grouping** used by ECS to place and manage tasks. With Fargate, the cluster does not contain EC2 instances — it only acts as a control boundary for services and tasks.

---

### 2.2 Task Definition

The **task definition** is the blueprint for running the container. It defines:

* Docker image
* CPU and memory allocation
* Container port (3000)
* Logging configuration
* Environment variables
* IAM task role (if required)

The task definition answers the question:

> "How should this container run?"

---

### 2.3 Task

A **task** is a running instance of a task definition. Each task:

* Runs exactly one copy of the container
* Has its own networking interface (awsvpc mode)
* Registers itself with the ALB target group

Tasks are ephemeral — they can be stopped and replaced at any time.

---

### 2.4 ECS Service

The ECS service is responsible for **maintaining the desired number of tasks**.

Responsibilities:

* Ensures the desired task count is always met
* Replaces failed or unhealthy tasks
* Integrates with the load balancer
* Acts as the scaling target

The service is the "brain" of the system.

---

### 2.5 Fargate

Fargate is the **execution engine**. It:

* Launches containers
* Provides compute, memory, and networking
* Handles isolation and runtime

Fargate does **not** make decisions — it only runs what ECS tells it to run.

---

## 3. Load Balancing

### 3.1 Application Load Balancer (ALB)

The ALB is the **only public entry point** into the system.

Configuration:

* Listener: HTTP :80
* Target type: IP
* Target port: 3000

The ALB forwards incoming requests to healthy ECS tasks.

---

### 3.2 Target Group

The target group contains **IP addresses of running tasks**.

* Tasks are automatically registered when they start
* Tasks are automatically deregistered when they stop
* Health checks determine whether traffic is sent

A task must pass health checks before receiving traffic.

---

### 3.3 Health Checks and Grace Period

* Health checks verify the application is ready
* Grace period allows containers time to boot before checks begin

Without a grace period, tasks may be killed before startup completes.

---

## 4. Networking and Security

### 4.1 VPC and Subnets

* ALB runs in **public subnets**
* ECS tasks can run in public or private subnets
* Tasks use **awsvpc networking**, giving each task its own ENI

---

### 4.2 Security Groups

**ALB Security Group**:

* Inbound: HTTP (80) from 0.0.0.0/0
* Outbound: All

**ECS Task Security Group**:

* Inbound: Port 3000 **only from ALB security group**
* Outbound: All

This ensures:

* Tasks are never publicly accessible
* Only the ALB can reach containers

---

## 5. Logging and Observability

### 5.1 Container Logs

* Containers send stdout/stderr to **CloudWatch Logs**
* Each task writes logs under a shared log group

This allows:

* Debugging application issues
* Verifying startup and health behavior

---

### 5.2 Metrics

Key metrics used:

* ECS service CPU utilization
* ECS service memory utilization
* ALB target health

These metrics drive scaling and operational visibility.

---

## 6. Auto Scaling

### 6.1 ECS Service Auto Scaling

Scaling is configured using **Application Auto Scaling**.

* Minimum tasks: ensures availability
* Maximum tasks: controls cost
* Desired count adjusted automatically

Scaling is **task-based**, not server-based.

---

### 6.2 Scaling Policy

A target tracking policy is used:

* Metric: ECS service average CPU utilization
* Target value: 60%

Behavior:

* CPU > 60% → ECS increases task count
* CPU < 60% → ECS reduces task count gradually

Fargate launches or stops tasks as instructed.

---

## 7. Failure Handling and Self-Healing

* If a task crashes, ECS replaces it automatically
* If a task fails health checks, ALB stops routing traffic
* ECS launches a new task to maintain desired count

No manual intervention is required.

---

## 8. End-to-End Request Flow

```
User Request
   ↓
ALB Listener (:80)
   ↓
Target Group
   ↓
Healthy ECS Task (port 3000)
   ↓
Containerized Application
```

---

## 9. Summary

This setup demonstrates:

* Long-running containerized services on AWS
* Serverless container execution with Fargate
* Load-balanced, self-healing architecture
* Secure networking with minimal exposure
* Automatic scaling based on real usage

This architecture forms the foundation for production ECS-based systems and can be extended with private subnets, IAM task roles, multiple services, and Infrastructure as Code.
