# 🔐 AWS Security Core Lab
## KMS + CloudTrail + Config + GuardDuty — A Production-Grade Security Baseline

---

## 📋 Overview

This Terraform project implements a **comprehensive AWS security foundation** that transforms an AWS account from a basic "things are running" state into a **fully auditable, encrypted, monitored, and governed** environment.

This is not four isolated demos — it's a **single cohesive security architecture** that represents the baseline security posture expected in production environments.

---

## 🎯 What This Setup Achieves

| Security Goal | How It's Achieved |
|---------------|-------------------|
| **Every API call is logged** | CloudTrail captures all management events across all regions |
| **Every configuration change is tracked** | AWS Config records resource configurations and changes over time |
| **Sensitive data is encrypted with your own keys** | Customer-managed KMS key encrypts all security logs |
| **Suspicious activity is automatically detected** | GuardDuty analyzes logs for threat intelligence |

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User / AWS Service                          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │   AWS API Call   │
                          └─────────────────┘
                                    │
            ┌───────────────────────┼───────────────────────┐
            ▼                       ▼                       ▼
   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
   │   CloudTrail    │    │   AWS Config    │    │   GuardDuty     │
   │ (API Logging)   │    │ (Config Drift)  │    │ (Threat Intel)  │
   └────────┬────────┘    └────────┬────────┘    └────────┬────────┘
            │                      │                      │
            ▼                      ▼                      ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │                    S3 Bucket (Encrypted)                        │
   │              🔐 Customer-Managed KMS Key                        │
   │                                                                  │
   │  ├── AWSLogs/<account-id>/CloudTrail/   ← API audit logs        │
   │  └── AWSLogs/<account-id>/Config/       ← Configuration history │
   └─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────┐
                    │   Compliance & Forensics  │
                    │   - Audit trails          │
                    │   - Change history        │
                    │   - Threat findings       │
                    └───────────────────────────┘
```

---

## 🧩 Components Breakdown

### 1️⃣ AWS KMS (Key Management Service)

**Purpose:** Customer-owned encryption for all security logs

**What it does:**
- Creates a **symmetric encryption key** with automatic annual rotation
- Grants permissions to CloudTrail, Config, and S3 to use the key
- Ensures you own the encryption, not AWS

**Key Configuration:**
```hcl
- Key Type: Symmetric (Encrypt/Decrypt)
- Rotation: Enabled (annual)
- Deletion Window: 7 days
- Alias: security-logs-key-25-1-26
```

**Why it matters:**
> Without a customer-managed key, AWS manages encryption — you lose control. With KMS, you can revoke access, audit key usage, and meet compliance requirements (HIPAA, PCI-DSS, SOC2).

---

### 2️⃣ S3 Bucket (Secure Log Storage)

**Purpose:** Centralized, immutable storage for all security logs

**Security Features:**
| Feature | Setting |
|---------|---------|
| Server-Side Encryption | KMS (Customer-managed) |
| Versioning | Enabled |
| Public Access | Completely blocked |
| Bucket Key | Enabled (cost optimization) |

**Bucket Policy Grants:**
- CloudTrail: `GetBucketAcl`, `PutObject`
- Config: `GetBucketAcl`, `ListBucket`, `PutObject`

**Storage Structure:**
```
s3://aws-security-logs-25-1-26/
├── AWSLogs/
│   └── <account-id>/
│       ├── CloudTrail/           # API activity logs
│       │   └── us-west-2/
│       │       └── 2026/01/25/
│       └── Config/               # Resource configurations
│           └── ConfigHistory/
```

---

### 3️⃣ AWS CloudTrail

**Purpose:** Complete audit trail of every AWS API call

**Configuration:**
| Setting | Value |
|---------|-------|
| Multi-Region | ✅ Yes |
| Global Service Events | ✅ Included |
| Management Events | Read + Write |
| Encryption | KMS |

**What gets logged:**
- **Who** made the call (IAM user/role)
- **What** API was called
- **When** it happened (timestamp)
- **Where** (source IP, region)
- **Result** (success/failure)

**Example Log Entry:**
```json
{
  "eventSource": "ec2.amazonaws.com",
  "eventName": "RunInstances",
  "userIdentity": { "userName": "admin" },
  "sourceIPAddress": "203.0.113.50",
  "eventTime": "2026-01-25T14:30:00Z"
}
```

---

### 4️⃣ AWS Config

**Purpose:** Track configuration changes and compliance over time

**What it records:**
- Current state of all AWS resources
- Historical configurations (who changed what, when)
- Relationship between resources

**IAM Role Setup:**
- Service role with `AWS_ConfigRole` managed policy
- Custom S3 write permissions for delivery channel

**Use Cases:**
| Scenario | How Config Helps |
|----------|------------------|
| Security group modified | See before/after states |
| Compliance audit | Prove configurations at any point in time |
| Troubleshooting | "What changed before the outage?" |

---

### 5️⃣ AWS GuardDuty

**Purpose:** Intelligent threat detection using ML and threat intelligence

**Data Sources Analyzed:**
- CloudTrail event logs
- VPC Flow Logs
- DNS query logs

**Finding Types:**
| Category | Examples |
|----------|----------|
| **Reconnaissance** | Port scanning, API probing |
| **Instance Compromise** | Crypto mining, malware C2 |
| **Account Compromise** | Unusual API calls, credential exfiltration |
| **Data Exfiltration** | Unusual S3 access patterns |

**Configuration:**
```hcl
- Finding Frequency: Every 15 minutes
- Auto-enabled: Current region
```

---

## 🚀 How to Deploy

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform v1.0+ installed
- IAM permissions for KMS, S3, CloudTrail, Config, GuardDuty, IAM

### Deployment Steps

```bash
# 1. Initialize Terraform
terraform init

# 2. Preview changes
terraform plan

# 3. Apply configuration
terraform apply

# 4. Confirm with 'yes'
```

### Outputs After Deployment
| Output | Description |
|--------|-------------|
| `kms_key_id` | KMS Key ID for security logs |
| `kms_key_arn` | Full ARN of the KMS key |
| `s3_bucket_name` | Name of the security logs bucket |
| `cloudtrail_name` | CloudTrail trail identifier |
| `config_recorder_name` | AWS Config recorder name |
| `guardduty_detector_id` | GuardDuty detector identifier |

---

## 🧪 Testing the Setup

### CloudTrail Verification
1. Create or delete a security group
2. Go to **CloudTrail → Event History**
3. Verify you see the API call with user, IP, and timestamp

### AWS Config Verification
1. Modify a security group rule
2. Go to **Config → Resources → Security Groups**
3. View the timeline showing before/after states

### GuardDuty Verification
1. Go to **GuardDuty → Settings**
2. Enable **Sample Findings**
3. Review simulated threat findings (safe — no real threats)

---

## ⏱️ Important: Log Delivery Delays

AWS security services do **not** provide instant logging. Expect the following delays:

| Service | Typical Delay | Why? |
|---------|---------------|------|
| **CloudTrail Event History** | 5-15 minutes | Events are batched and delivered periodically |
| **CloudTrail S3 Delivery** | 5-15 minutes | Logs are compressed and written in batches |
| **AWS Config** | 3-10 minutes | Configuration snapshots are taken periodically |
| **GuardDuty Findings** | Minutes to hours | ML analysis requires data aggregation |

**Why this matters:**
- Security monitoring is **near real-time**, not instant
- Don't panic if you don't see logs immediately after an action
- For incident response, account for these delays when correlating events
- Critical alerts may still take minutes to surface

> 💡 **Pro Tip:** If testing, perform an action (e.g., create a security group), then wait 10-15 minutes before checking CloudTrail or Config.

---

## 💰 Cost Considerations

| Service | Pricing Model | Typical Cost |
|---------|---------------|--------------|
| KMS | $1/month per key + $0.03/10K requests | ~$1-2/month |
| S3 | Storage + requests | Minimal for logs |
| CloudTrail | First trail free, $2/100K events after | Often free |
| Config | $0.003 per configuration item recorded | ~$5-10/month |
| GuardDuty | Based on data analyzed | ~$3-5/month (small account) |

**Total estimate for a small account:** ~$10-20/month

---

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Recommended approach:**
- Keep CloudTrail enabled (critical for security)
- Stop Config recorder if not needed
- Disable GuardDuty if cost-sensitive

---

## 🎓 What You've Learned

By deploying this setup, you now understand:

| Concept | Real-World Application |
|---------|------------------------|
| **Shared Responsibility Model** | AWS secures the cloud; you secure what's IN the cloud |
| **Audit Trails vs Monitoring** | CloudTrail = what happened; GuardDuty = is it bad? |
| **Preventive vs Detective Security** | KMS prevents access; GuardDuty detects threats |
| **Compliance Requirements** | Why auditors love AWS Config |

---

## 📁 File Structure

```
KMS+CT+Config-25-1-26/
├── main.tf          # All Terraform resources
├── setup.txt        # Manual setup guide (reference)
└── README.md        # This documentation
```

---

## 🏷️ Tags Used

All resources are tagged with:
```hcl
tags = {
  Name = "<resource>-25-1-26"
  Lab  = "AWS-Security-Core"
}
```

---

## 📚 References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/)
- [AWS CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [AWS Config Documentation](https://docs.aws.amazon.com/config/)
- [AWS GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)

---

**Author:** Cloud Security Lab  
**Date:** January 25, 2026  
**Region:** us-west-2
