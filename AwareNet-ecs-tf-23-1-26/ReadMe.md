# AwareNet - AWS ECS Fargate Deployment Guide

## 🚀 Project Overview

**AwareNet** is a comprehensive cybersecurity awareness training platform built using a microservices architecture. This document details the complete AWS deployment setup using ECS Fargate, Terraform Infrastructure as Code, and modern DevOps practices.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Microservices Breakdown](#microservices-breakdown)
4. [Infrastructure Components](#infrastructure-components)
5. [Deployment Process](#deployment-process)
6. [Security Considerations](#security-considerations)
7. [Monitoring & Logging](#monitoring--logging)
8. [Lessons Learned](#lessons-learned)

---

## 🏗️ Architecture Overview

```
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │                        AWS Cloud                            │
                                    │  ┌─────────────────────────────────────────────────────┐   │
                                    │  │                      VPC (10.0.0.0/16)               │   │
                                    │  │                                                       │   │
        ┌──────────┐               │  │   ┌─────────────┐         ┌─────────────┐            │   │
        │  Users   │───────────────┼──┼──▶│     ALB     │────────▶│  Frontend   │            │   │
        └──────────┘               │  │   │ (Port 80)   │         │  (Port 3000)│            │   │
                                    │  │   └──────┬──────┘         └─────────────┘            │   │
                                    │  │          │                                            │   │
                                    │  │          │ /api/*                                     │   │
                                    │  │          ▼                                            │   │
                                    │  │   ┌─────────────┐                                    │   │
                                    │  │   │ API Gateway │                                    │   │
                                    │  │   │ (Port 8080) │                                    │   │
                                    │  │   └──────┬──────┘                                    │   │
                                    │  │          │                                            │   │
                                    │  │          │ Service Discovery (AWS Cloud Map)         │   │
                                    │  │          ▼                                            │   │
                                    │  │   ┌─────────────────────────────────────────────┐   │   │
                                    │  │   │              Backend Services               │   │   │
                                    │  │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │   │
                                    │  │   │  │  Auth   │ │  Forum  │ │  Quiz   │       │   │   │
                                    │  │   │  │ :5001   │ │ :5002   │ │ :5003   │       │   │   │
                                    │  │   │  └────┬────┘ └────┬────┘ └────┬────┘       │   │   │
                                    │  │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │   │
                                    │  │   │  │Writeup  │ │  FAQ    │ │Phishing │       │   │   │
                                    │  │   │  │ :5004   │ │ :5005   │ │ :5006   │       │   │   │
                                    │  │   │  └────┬────┘ └────┬────┘ └────┬────┘       │   │   │
                                    │  │   │  ┌─────────┐ ┌─────────┐                   │   │   │
                                    │  │   │  │ Report  │ │ Profile │                   │   │   │
                                    │  │   │  │ :5007   │ │ :5008   │                   │   │   │
                                    │  │   │  └────┬────┘ └─────────┘                   │   │   │
                                    │  │   └───────┼─────────────────────────────────────┘   │   │
                                    │  │           │                                          │   │
                                    │  │           ▼                                          │   │
                                    │  │   ┌─────────────┐         ┌─────────────┐           │   │
                                    │  │   │    EFS      │         │ ElastiCache │           │   │
                                    │  │   │ (SQLite DB) │         │   (Redis)   │           │   │
                                    │  │   └─────────────┘         └─────────────┘           │   │
                                    │  │                                                       │   │
                                    │  └─────────────────────────────────────────────────────┘   │
                                    │                                                             │
                                    │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
                                    │  │     ECR     │    │ CloudWatch  │    │   Cloud Map │    │
                                    │  │  (Images)   │    │   (Logs)    │    │  (Discovery)│    │
                                    │  └─────────────┘    └─────────────┘    └─────────────┘    │
                                    └─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Backend
| Component | Technology |
|-----------|------------|
| Runtime | Python 3.11 |
| Framework | Flask |
| Database | SQLite (on EFS) |
| Caching | Redis (ElastiCache) |
| Authentication | JWT Tokens |

### Frontend
| Component | Technology |
|-----------|------------|
| Template Engine | Jinja2 |
| Styling | Tailwind CSS |
| JavaScript | Vanilla JS |
| UI Theme | Cyberpunk/Neon |

### Infrastructure
| Component | Technology |
|-----------|------------|
| IaC | Terraform |
| Container Orchestration | AWS ECS Fargate |
| Container Registry | Amazon ECR |
| Load Balancing | Application Load Balancer |
| Service Discovery | AWS Cloud Map |
| Persistent Storage | Amazon EFS |
| Caching Layer | Amazon ElastiCache (Redis) |
| Logging | CloudWatch Logs |

---

## 🔧 Microservices Breakdown

### 1. Frontend Service (Port 3000)
- Serves static files and HTML templates
- Handles client-side routing
- Communicates with API Gateway for all backend operations

### 2. API Gateway (Port 8080)
- Central entry point for all API requests
- JWT token validation via Auth Service
- Rate limiting using Redis
- Request proxying to backend services

### 3. Auth Service (Port 5001)
- User registration and login
- JWT token generation and verification
- Password hashing with bcrypt
- User management (CRUD operations)

### 4. Forum Service (Port 5002)
- Discussion posts (create, read, update, delete)
- Comments system
- Like/Save functionality
- Post moderation (admin approval)

### 5. Quiz Service (Port 5003)
- Security awareness quizzes
- Multiple difficulty levels
- Score tracking and history
- Leaderboard functionality

### 6. Writeup Service (Port 5004)
- Security writeups and tutorials
- Bookmark functionality
- Reading progress tracking
- Category-based organization

### 7. FAQ Service (Port 5005)
- Frequently asked questions
- Category filtering
- Helpful/Not helpful feedback
- Admin CRUD operations

### 8. Phishing Service (Port 5006)
- Phishing simulation exercises
- Email template management
- User response tracking
- Educational feedback

### 9. Report Service (Port 5007)
- Security incident reporting
- Report status tracking
- Admin review workflow
- Statistics dashboard

### 10. Profile Service (Port 5008)
- User profile aggregation
- Activity statistics from all services
- Centralized user data view

---

## 🏢 Infrastructure Components

### VPC Configuration
```hcl
CIDR Block: 10.0.0.0/16

Public Subnets (2 AZs):
  - 10.0.1.0/24 (us-west-2a)
  - 10.0.2.0/24 (us-west-2b)

Private Subnets (2 AZs):
  - 10.0.10.0/24 (us-west-2a)
  - 10.0.11.0/24 (us-west-2b)
```

### ECS Cluster
- **Launch Type**: Fargate (serverless)
- **Task CPU**: 256 units (0.25 vCPU)
- **Task Memory**: 512 MB
- **Desired Count**: 2 tasks per service (HA)

### Load Balancer
- **Type**: Application Load Balancer
- **Listeners**: HTTP (Port 80)
- **Target Groups**:
  - Frontend (Port 3000) - Default route
  - API Gateway (Port 8080) - `/api/*` routes

### EFS (Elastic File System)
- **Purpose**: Persistent SQLite database storage
- **Access Point**: UID/GID 1000 with proper permissions
- **Mount Path**: `/mnt/efs`
- **Encryption**: In-transit enabled

### ElastiCache (Redis)
- **Node Type**: cache.t3.micro
- **Purpose**: API rate limiting
- **Engine Version**: Redis 7.x

### Service Discovery (Cloud Map)
- **Namespace**: `awarenet-23-1-26.local`
- **DNS Resolution**: Private DNS within VPC
- **Service Names**: `{service-name}.awarenet-23-1-26.local`

---

## 📦 Deployment Process

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform installed (v1.0+)
3. Docker installed and running
4. PowerShell (Windows) or Bash (Linux/Mac)

### Step 1: Initialize Terraform
```bash
cd aws-deployment/terraform
terraform init
```

### Step 2: Review and Apply Infrastructure
```bash
terraform plan
terraform apply
```

### Step 3: Build and Push Docker Images
```powershell
# Windows
.\aws-deployment\scripts\build-and-push.ps1

# Linux/Mac
./aws-deployment/scripts/build-and-push.sh
```

### Step 4: Verify Deployment
```bash
# Check ECS services
aws ecs list-services --cluster awarenet-23-1-26-cluster

# Get ALB DNS
aws elbv2 describe-load-balancers --names awarenet-23-1-26-alb \
  --query 'LoadBalancers[0].DNSName' --output text
```

### Step 5: Populate Databases (Optional)
```powershell
.\aws-deployment\scripts\populate-databases-simple.ps1
```

---

## 🔒 Security Considerations

### Network Security
- ✅ Private subnets for ECS tasks (no public IPs)
- ✅ NAT Gateway for outbound internet access
- ✅ Security groups with least-privilege rules
- ✅ ALB in public subnet as single entry point

### Application Security
- ✅ JWT token authentication
- ✅ Password hashing with bcrypt
- ✅ Rate limiting on API endpoints
- ✅ CORS configuration
- ✅ Security headers (X-Frame-Options, X-XSS-Protection, etc.)

### Data Security
- ✅ EFS encryption in transit
- ✅ Redis in private subnet (no public access)
- ✅ IAM roles with least-privilege access

### Areas for Improvement
- ⚠️ Add HTTPS with ACM certificate
- ⚠️ Enable Redis AUTH token
- ⚠️ Implement AWS WAF
- ⚠️ Add secrets management (AWS Secrets Manager)

---

## 📊 Monitoring & Logging

### CloudWatch Logs
All ECS tasks send logs to CloudWatch with the following structure:
```
Log Group: /ecs/awarenet-23-1-26
Log Streams: {service-name}/{task-id}
```

### Health Checks
Each service implements:
1. **Container Health Check**: Python urllib check to `/health` endpoint
2. **ALB Health Check**: HTTP GET to `/health` with 30s interval

### Key Metrics to Monitor
- ECS Service CPU/Memory utilization
- ALB request count and latency
- Target group healthy host count
- ElastiCache cache hits/misses

---

## 📝 Lessons Learned

### Challenge 1: EFS Permissions
**Problem**: SQLite databases couldn't be created due to permission issues.
**Solution**: Created an EFS Access Point with POSIX user ID 1000 and proper directory permissions.

### Challenge 2: Redis URL Parsing
**Problem**: Special characters in Redis password broke URL parsing.
**Solution**: Used ElastiCache without AUTH (VPC-secured) or URL-encoded passwords.

### Challenge 3: Service Discovery DNS
**Problem**: Services couldn't resolve each other's hostnames.
**Solution**: Used AWS Cloud Map with `.local` namespace and FQDN in environment variables.

### Challenge 4: Health Check Grace Period
**Problem**: Services marked unhealthy before fully starting.
**Solution**: Added `health_check_grace_period_seconds = 120` to ECS services.

### Challenge 5: Dynamic API URLs
**Problem**: Frontend JS files had hardcoded `localhost:8080`.
**Solution**: Implemented dynamic URL detection based on `window.location.hostname`.

---

## 🗂️ Project Structure

```
AwareNet/
├── services/
│   ├── api-gateway/
│   ├── auth-service/
│   ├── forum-service/
│   ├── quiz-service/
│   ├── writeup-service/
│   ├── faq-service/
│   ├── phishing-service/
│   ├── report-service/
│   ├── profile-service/
│   └── frontend-service/
├── aws-deployment/
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── vpc.tf
│   │   ├── ecs.tf
│   │   ├── ecs-auth-service.tf
│   │   ├── ecs-api-frontend.tf
│   │   ├── ecs-backend-services.tf
│   │   ├── ecr.tf
│   │   ├── alb.tf
│   │   ├── elasticache.tf
│   │   ├── efs.tf
│   │   ├── service-discovery.tf
│   │   └── terraform.tfvars
│   └── scripts/
│       ├── build-and-push.ps1
│       └── populate-databases-simple.ps1
└── docker-compose.yml (local development)
```

---

## 🔗 Useful Commands

### Terraform
```bash
# View current state
terraform show

# Destroy infrastructure
terraform destroy

# View outputs
terraform output
```

### AWS CLI
```bash
# List ECS services
aws ecs list-services --cluster awarenet-23-1-26-cluster --region us-west-2

# Force new deployment
aws ecs update-service --cluster awarenet-23-1-26-cluster \
  --service awarenet-23-1-26-api-gateway \
  --force-new-deployment --region us-west-2

# View logs
aws logs tail /ecs/awarenet-23-1-26 --follow --region us-west-2
```

### Docker
```bash
# Build single service
docker build -t awarenet-auth-service ./services/auth-service

# Run locally
docker-compose up -d
```

---

## 📈 Cost Estimation

| Resource | Monthly Cost (Estimate) |
|----------|------------------------|
| ECS Fargate (10 services × 2 tasks) | ~$50 |
| Application Load Balancer | ~$20 |
| NAT Gateway | ~$35 |
| ElastiCache (t3.micro) | ~$15 |
| EFS | ~$5 |
| CloudWatch Logs | ~$5 |
| **Total** | **~$130/month** |

*Note: Costs vary by region and usage. Consider reserved capacity for production.*

---

## 👥 Authors

- **Project**: AwareNet - Cybersecurity Awareness Platform
- **Course**: FSE (Foundations of Software Engineering)
- **University**: FAST National University
- **Semester**: 3rd Semester, Cyber Security

---

## 📄 License

This project is developed for educational purposes as part of the FSE course curriculum.

---

*Last Updated: January 23, 2026*
