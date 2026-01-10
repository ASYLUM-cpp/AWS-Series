# Hands-On AWS API Gateway & JWT Authentication Journey

## Overview

This document chronicles my **AWS hands-on series** — Week 2, Day 6 — where I attempted to **deep dive into APIs, Lambda, and JWT authentication**.  

The goal was simple on paper: create a **secure, functional CRUD API** for a frontend website.  
The journey was chaotic, frustrating, and full of learning moments — but immensely rewarding.

---

## Initial Goals

1. Build a **CRUD API** for products:  
   - Create, Read, Update, Delete products  
   - Accessible from a frontend website  

2. Explore **API Gateway, Lambda, and DynamoDB** hands-on.  

3. Incorporate **production-style security measures** like API keys, JWT authentication, and filtering.

---

## Step 1: Backend Setup

**Resources created:**

- **DynamoDB table** for storing product data  
- **CRUD Lambda function** for backend logic  
- **API Gateway** to expose CRUD endpoints  

At this stage, the API worked for basic CRUD operations **without authentication**.

---

## Step 2: Security Concerns

I asked myself:

> *"What if someone DDoSes my API? How do I protect the backend?"*

To simulate **production-ready API security**, I designed a **proxy API + proxy Lambda** layer.

**Intended flow:**

# Hands-On AWS API Gateway & JWT Authentication Journey

## Overview

This document chronicles my **AWS hands-on series** — Week 2, Day 3 — where I attempted to **deep dive into APIs, Lambda, and JWT authentication**.  

The goal was simple on paper: create a **secure, functional CRUD API** for a frontend website.  
The journey was chaotic, frustrating, and full of learning moments — but immensely rewarding.

---

## Initial Goals

1. Build a **CRUD API** for products:  
   - Create, Read, Update, Delete products  
   - Accessible from a frontend website  

2. Explore **API Gateway, Lambda, and DynamoDB** hands-on.  

3. Incorporate **production-style security measures** like API keys, JWT authentication, and filtering.

---

## Step 1: Backend Setup

**Resources created:**

- **DynamoDB table** for storing product data  
- **CRUD Lambda function** for backend logic  
- **API Gateway** to expose CRUD endpoints  

At this stage, the API worked for basic CRUD operations **without authentication**.

---

## Step 2: Security Concerns

I asked myself:

> *"What if someone DDoSes my API? How do I protect the backend?"*

To simulate **production-ready API security**, I designed a **proxy API + proxy Lambda** layer.

**Intended flow:**

Frontend → Proxy API (JWT-protected) → Proxy Lambda (filters users & injects API key) → CRUD API → CRUD Lambda → DynamoDB → Frontend


**Proxy Lambda responsibilities:**

- Store **API key securely** (so it isn’t hard-coded into the frontend)  
- Filter users based on **role**:  
  - Admin → access all products  
  - Non-admin → search products by ID only  

**Rationale:**  
Hardcoding API keys in the frontend is a **bad practice**. Using a proxy ensures sensitive data never reaches the client.

---

## Step 3: JWT Authentication with Cognito

I wanted only authorized users to access my API.

**Steps:**

1. Created a **Cognito User Pool**  
2. Added a **test user**  
3. Attached a **JWT Authorizer** to the proxy API  

**Outcome:** The backend could now validate JWT tokens for authenticated requests.

---

## Step 4: Frontend Setup

Initially, there was **no frontend**. To test the flow, I created:  

- `index.html` → main page, redirects unauthenticated users to Cognito login UI  
- `callback.html` → receives the **authorization code** from Cognito, exchanges it for JWT tokens, stores tokens, and redirects back to `index.html`  

**Hosted as a static website on S3.**  

**Flow:**

User → index.html → Cognito login → callback.html → Proxy API → Proxy Lambda → CRUD API → DynamoDB → callback.html → index.html


---

## Step 5: Challenges & Errors

This was where the fun (and frustration) began.

### 5.1 CORS Errors

Error: 

No 'Access-Control-Allow-Origin' header is present on the requested resource


**Fixes attempted:**

- Enabled CORS on **API Gateway method 200 responses** → only partially fixed  
- Added CORS headers in **Lambda responses** → still insufficient  
- Real solution: **Enable CORS on ALL method responses** (`default 4XX`, `default 5XX`)  

---

### 5.2 Token Expiry & Refresh

- Initially stored only **ID token** in local storage  
- Result: JWT token expired quickly → authentication failed  

**Solution:**  

- Implemented **refresh token flow**  
- Store **ID token + Access token + Refresh token** in local storage  
- Frontend uses **refresh token to renew access token** without re-login  

---

### 5.3 Payload Mismatch

- Proxy Lambda expected a **specific product object pattern**  
- Frontend was sending a different structure → requests failed silently  
- Fix: aligned frontend payload structure with what Lambda expected (`productId`, `productName`, `description`)

---

### 5.4 Lambda Debugging Nightmare

- Monitored **CloudWatch logs** constantly  
- Fixing CORS required updating **all responses including errors**  
- Encountered **indentation errors**, misconfigured headers, and mismatched method responses  

---

### 5.5 Auth Flow Complexity

Proxy API originally expected **JWT token**, but for **authorization code exchange**:

- Needed a **public auth endpoint** → `auth/exchange`  
- Proxy Lambda now had **dual functionality**:  
  1. Accept authorization code → generate JWT tokens → return to `callback.html`  
  2. Accept authenticated requests → enforce role-based access → forward to CRUD API  

---

### 5.6 Miscellaneous Issues

- Client secret missing in Lambda → caused auth failures  
- Callback redirect URL misconfigured → code not received properly  
- Frontend redirect and token storage logic had subtle bugs  

---

## Step 6: Final Flow

After hours of debugging, the system works as intended:


**Fixes attempted:**

- Enabled CORS on **API Gateway method 200 responses** → only partially fixed  
- Added CORS headers in **Lambda responses** → still insufficient  
- Real solution: **Enable CORS on ALL method responses** (`default 4XX`, `default 5XX`)  

---

### 5.2 Token Expiry & Refresh

- Initially stored only **ID token** in local storage  
- Result: JWT token expired quickly → authentication failed  

**Solution:**  

- Implemented **refresh token flow**  
- Store **ID token + Access token + Refresh token** in local storage  
- Frontend uses **refresh token to renew access token** without re-login  

---

### 5.3 Payload Mismatch

- Proxy Lambda expected a **specific product object pattern**  
- Frontend was sending a different structure → requests failed silently  
- Fix: aligned frontend payload structure with what Lambda expected (`productId`, `productName`, `description`)

---

### 5.4 Lambda Debugging Nightmare

- Monitored **CloudWatch logs** constantly  
- Fixing CORS required updating **all responses including errors**  
- Encountered **indentation errors**, misconfigured headers, and mismatched method responses  

---

### 5.5 Auth Flow Complexity

Proxy API originally expected **JWT token**, but for **authorization code exchange**:

- Needed a **public auth endpoint** → `auth/exchange`  
- Proxy Lambda now had **dual functionality**:  
  1. Accept authorization code → generate JWT tokens → return to `callback.html`  
  2. Accept authenticated requests → enforce role-based access → forward to CRUD API  

---

### 5.6 Miscellaneous Issues

- Client secret missing in Lambda → caused auth failures  
- Callback redirect URL misconfigured → code not received properly  
- Frontend redirect and token storage logic had subtle bugs  

---

## Step 6: Final Flow

After hours of debugging, the system works as intended:

User visits index.html

Redirected to Cognito login if unauthenticated

Cognito returns authorization code to callback.html

Callback.html sends code to public proxy endpoint

Proxy Lambda exchanges code for tokens (ID, Access, Refresh)

Tokens stored in local storage

Frontend sends API request with Access token to Proxy API

Proxy Lambda verifies JWT & filters users

Proxy Lambda adds API key & forwards request to CRUD API

CRUD Lambda handles logic → DynamoDB

Response flows back through Proxy Lambda → Proxy API → Frontend

Token refresh handled automatically if Access token expires



---

## Step 7: Lessons Learned

- **CORS headers** must be configured for **all responses**, not just 200  
- **Payload structures** must align between frontend & Lambda  
- **JWT + refresh token** is essential for smooth frontend experience  
- AWS debugging requires **CloudWatch patience**  
- Using a **proxy API** for API key security & role filtering is highly practical  
- Sometimes, **a single missing client secret** can break the whole auth flow  
- Hands-on work beats tutorials for deep learning  

---

## Workflow Diagram

```mermaid
flowchart LR
    subgraph Frontend
        A[index.html] --> B[Cognito Login UI]
        C[callback.html] --> D[Local Storage: ID + Refresh + Access Tokens]
    end

    subgraph Proxy Layer
        E[Proxy API] --> F[Proxy Lambda]
    end

    subgraph Backend
        G[CRUD API] --> H[CRUD Lambda] --> I[DynamoDB]
    end

    B -->|Authorization Code| C
    C -->|JWT Request| E
    F -->|API Key| G
    G --> H --> I
    H --> F --> C
    C --> A
