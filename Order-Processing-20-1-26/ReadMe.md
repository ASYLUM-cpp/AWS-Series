# 🧩 Event-Driven Order Processing System (AWS Step Functions + WebSockets)

This project is a **fully event-driven order lifecycle system** built on AWS, designed to validate orders, reserve inventory, issue refunds when needed, and **push real-time status updates to a frontend using WebSockets**.

What looks clean on an architecture diagram turned into **two days of deep debugging, payload battles, IAM confusion, and late-night problem solving** — and that's exactly what this README documents.

---

## 🚀 High-Level Overview

The system processes an order through the following stages:

1. **Validate Order**
2. **Notify frontend (order validated)**
3. **Check & reserve inventory**
4. **Decision: reserve or refund**
5. **Refund payment (if needed)**
6. **Notify frontend in real time**
7. **End workflow**

All orchestration is handled by **AWS Step Functions**, with each step executed by a **Lambda function**, and all user-facing updates delivered via **API Gateway WebSockets**.

---

## 🧠 Architecture

**Core AWS Services Used:**
- AWS Step Functions (workflow orchestration)
- AWS Lambda (business logic)
- API Gateway (WebSocket API)
- DynamoDB (inventory state)
- IAM (permissions)
- CloudWatch Logs (debugging & sanity)

**Key Design Principle:**  
👉 **Status is the single source of truth**, propagated consistently across all Lambdas.

---

## 🔄 Order Lifecycle Flow

```
Client → WebSocket → Step Functions
         ↓
    Validate Order
         ↓
    Notify (VALID)
         ↓
   Check Inventory
         ↓
    ┌───────────────┐
    │   RESERVED    │ → Notify → Success
    │               │
    │   REFUND      │ → Refund → Notify → End
    └───────────────┘
```

---

## 🧪 Lambda Functions Breakdown

### 1️⃣ Validate Order Lambda
- Validates incoming order payload
- Adds `status: VALID`
- Returns **entire payload** for Step Functions

**Key lesson:**  
If you don't return the full payload, Step Functions will silently drop data downstream.

---

### 2️⃣ Check Inventory Lambda
- Reads inventory from DynamoDB
- Performs atomic checks
- Updates inventory counts
- **Updates `status` instead of creating new fields**

🚨 **Major bug faced here**  
Initially, this Lambda created:
```json
"inventoryStatus": "RESERVED"
```

But the notifier Lambda only checked:
```json
"status"
```

➡️ Result: frontend *always* received `VALID`.

**Fix:**
All Lambdas must **read and write the same `status` attribute**.

---

### 3️⃣ Refund Payment Lambda
- Triggered when inventory is unavailable
- Mocked refund logic
- Updates:
```json
"status": "REFUNDED"
```

---

### 4️⃣ Order Notifier Lambda (WebSocket)
- Sends real-time messages to the client
- Reads payload from:
```js
event.Payload || event
```

**Handles:**
- VALID
- RESERVED
- REFUNDED

---

## 🧵 Step Functions State Machine

The workflow is driven entirely by **Choice states**, not errors.

### 🔴 Critical Design Fix

Originally, the workflow relied on **Lambda errors** (like `OUT_OF_STOCK`) to decide refunds.

This caused:
- Retry loops
- Confusing failures
- Incorrect branching

**Final design:**
- Lambdas always succeed
- Business outcome is expressed via `status`
- Step Functions uses:
```json
"Variable": "$.status"
```

---

## 🧨 Problems & Struggles (The Real Part)

### ❌ 1. WebSocket `AccessDeniedException` (Twice)
- First time: incorrect WebSocket endpoint URL
- Second time: API Gateway wasn't deployed

**Lesson:**
A WebSocket API *exists* ≠ it's *deployed*

---

### ❌ 2. Lambda Code Wasn't Deployed

At one point:
- Fixed the bug
- Redeployed Step Functions
- Retested
- Same error kept happening

Turns out:
👉 I **forgot to deploy the updated Lambda code**

I reset and retried the same broken execution **2–3 times** before realizing this.

---

### ❌ 3. Payload Shape Hell (`Payload.Payload`)

Step Functions wraps Lambda outputs as:
```json
{
  "Payload": { ... }
}
```

But only **some states used `OutputPath`**.

This caused:
- `Missing required fields`
- Notify Lambda receiving unexpected structures
- Debugging logs that looked "correct" but weren't

**Final Rule:**
Every Task either:
- Normalizes input with `OutputPath`
- Or notifier handles both shapes defensively

---

### ❌ 4. Status Never Updating

Frontend kept receiving:
```json
"status": "VALID"
```

Even after refund.

Cause:
- Inventory Lambda created a *new field*
- Status field never changed

This was subtle, painful, and took time to spot.

---

### ❌ 5. Mental Fatigue Is Real

I spent most of the time:
- Designing the state machine
- Wiring WebSocket logic
- Handling IAM + API Gateway quirks

By the end:
- It was late night
- Brain felt like mush
- Errors that should've been obvious took longer to spot

Still, I told myself:

> "This lab gets finished **tonight**, no matter how long it takes."

---

## 🕑 2:00 AM — Final Result

At **2 AM**, everything finally worked:
- Correct branching
- Correct status propagation
- Real-time WebSocket updates
- Clean Step Functions execution

🎉 **Big achievement unlocked**

---

## 📚 What I Learned

- Step Functions demand **strict payload discipline**
- WebSockets are simple *only after* you understand deployment + permissions
- Status-driven workflows are cleaner than error-driven ones
- Always log the **exact shape of your input**
- Late-night debugging teaches humility 😅

---

## 🧠 Final Advice

If you're building with Step Functions:

> **Design the payload first.
> Enforce contracts.
> Treat status as sacred.**

This lab alone taught me more about **serverless orchestration and WebSockets** than any tutorial ever could.

---

## 🔗 Links

- GitHub Repository: *(add your link here)*
- AWS Docs referenced:
  - Step Functions
  - API Gateway WebSockets
  - Lambda Invoke patterns

---

## 🏁 Final Note

This project is not perfect — and that's the point.
It reflects **real-world cloud engineering**, where most time is spent debugging edge cases, not writing happy-path code.

If you're reading this and struggling with something similar:
**You're doing it right.**

---

## 💡 Next Steps

If you want, we can:
- Trim this for **portfolio version**
- Add **architecture diagrams**
- Or convert it into a **case-study style README** for recruiters
