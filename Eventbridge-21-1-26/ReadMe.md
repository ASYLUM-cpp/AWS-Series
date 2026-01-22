# Event-Driven eCommerce Architecture

This document explains the **end-to-end event-driven eCommerce architecture** built using **AWS EventBridge, Lambda, and related services**, including the step-by-step setup, challenges faced, and solutions applied.

---

## 🧱 High-Level Architecture

```
Client / API
    |
v
Order Service (Lambda)
    |
v
Amazon EventBridge
    |
    +--> Inventory Lambda
    |
    +--> Notification Lambda
    |
    +--> Analytics Lambda
    |
    +--> Refund Lambda (via InventoryOutOfStock event)
```

Key principles:

* **Decoupled services**: No service calls another directly.
* **Event-driven**: All communication happens via events.
* **Parallel execution**: Multiple consumers react independently.

---

## Step 1: Order Producer (Lambda)

**Responsibilities:**

* Validate orders
* Emit `OrderCreated` events to EventBridge

**Key points:**

* Does **not** handle inventory, notifications, analytics, or refunds.
* Emits structured JSON events with a `detail-type` and `eventVersion`.

**Sample event:**

```json
{
  "source": "com.mycompany.orders",
  "detail-type": "OrderCreated",
  "detail": {
    "eventVersion": "2.0",
    "order": {
      "orderId": "ord-123",
      "totalAmount": 599.99,
      "currency": "USD",
      "items": [{"sku": "sku-abc", "quantity": 2, "price": 199.99}],
      "channel": "WEB"
    },
    "customer": {"userId": "usr-42", "isRefundEligible": true},
    "payment": {"method": "CARD", "status": "PAID"},
    "metadata": {"createdAt": "2026-01-22T11:45:00Z", "correlationId": "req-7f9c"}
  }
}
```

---

## Step 2: Amazon EventBridge

**Responsibilities:**

* Acts as the **central event bus**
* Routes events to **all matching targets**
* Performs **content-based routing** using rules

**Key insight:**

* EventBridge **does not execute business logic**
* Each rule evaluates events and triggers **one or more Lambda targets**

**Challenge faced:**

* Initially, Lambda targets were not invoked because **resource-based permissions** were missing.
* Fixed by adding a Lambda permission allowing `events.amazonaws.com` to invoke each Lambda.

---

## Step 3: EventBridge Rules & Consumers

### 3.1 Inventory Lambda

* **Consumes:** `OrderCreated`
* **Responsibilities:**

  * Deduct inventory
  * Emit `InventoryOutOfStock` event if stock insufficient
* **Problems faced:**

  * Rule initially had a shared role, preventing invocation of other Lambdas
  * Solved by **creating dedicated IAM roles per target**
  * Ensured **Lambda resource policy** allowed EventBridge invocation

### 3.2 Notification Lambda

* **Consumes:** `OrderCreated`
* Sends confirmation emails
* Independent; failure does not block other consumers

### 3.3 Analytics Lambda

* **Consumes:** `OrderCreated`
* Logs and stores events for reporting and analytics
* Purely observational; does not affect order flow

### 3.4 Refund Lambda

* **Consumes:** `InventoryOutOfStock`
* Automatically issues refunds if inventory check fails
* **Flow:**

  * Inventory consumer emits `InventoryOutOfStock`
  * Refund consumer triggers based on this event
* **Challenge:**

  * Introduced **event chaining** while keeping consumers decoupled
  * Used **correlation IDs** for tracking events

---

## Step 4: Event Versioning

* Introduced `eventVersion` field in event `detail`:

  * v1: Original events
  * v2: Added optional fields (e.g., `channel`, `isRefundEligible`)
* **Backward compatibility**:

  * Old consumers ignore new fields
  * New consumers can opt-in based on version
* Avoided breaking existing flows

---

## Step 5: Failure Engineering

**Principles applied:**

1. Lambda exceptions are re-raised to trigger EventBridge retries
2. Each target has **its own Dead Letter Queue (DLQ)**
3. Idempotency enforced for retries (e.g., DynamoDB deduplication)
4. Poison messages isolated in DLQs
5. Observability through CloudWatch Logs and alarms
6. Manual re-drive strategy implemented for DLQ messages

**Example:**

* Inventory Lambda fails → EventBridge retries → If still failing, event goes to DLQ
* Refund Lambda can process DLQ messages manually

---

## Step 6: Terraform Implementation

**Highlights:**

* Created **dedicated roles per rule**, solving the earlier IAM confusion
* EventBridge bus, rules, targets, DLQs, and Lambda permissions fully codified
* Ensured **reproducibility** and **environment parity**
* Applied in correct order:

  1. EventBridge bus
  2. DLQs
  3. IAM roles
  4. Rules
  5. Lambda targets
  6. Lambda permissions

**Benefits:**

* DevOps-friendly
* Easy to maintain and extend
* Supports multiple environments (staging, prod)

---

## Lessons Learned / Challenges

1. **Lambda invocation fails if EventBridge permission missing** → solved via Lambda resource-based policy
2. **Shared IAM roles break other targets** → always create dedicated roles per rule/target
3. **Event pattern mistakes** → must match `source` and `detail-type` exactly
4. **Failure handling** → DLQs + retries essential
5. **Event versioning** → backward compatibility ensures safe schema evolution

---

## Summary

This setup demonstrates **production-grade event-driven architecture**:

* Fully decoupled services
* Multi-stage event flows with business logic (inventory → refund)
* Event versioning for safe evolution
* Resilient failure handling with DLQs and retries
* Reproducible infrastructure via Terraform

It mirrors **real-world patterns** used in companies like Amazon, Stripe, and Netflix.

---

**Next Steps:**

* Extend with `RefundCompleted` events for full saga pattern
* Introduce cross-account EventBridge for multi-tenant systems
* Module-ize Terraform for reusable deployments
* Add monitoring dashboards and automated alerting
