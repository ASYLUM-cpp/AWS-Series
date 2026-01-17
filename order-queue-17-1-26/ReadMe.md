# Serverless Order Processing System with AWS

This project demonstrates a **scalable, decoupled order processing system** built entirely on AWS serverless services. It includes an **API**, **SQS queue**, **Lambda functions**, and **DynamoDB**. The system is designed to handle bursts of incoming orders while ensuring reliability and observability.

---

## Architecture Overview

Frontend API
|
v
Ingest Lambda (validates & sends to SQS)
|
v
SQS Queue (buffer)
|
v
Worker Lambda (processes orders)
|
v
DynamoDB (stores processed orders)



### Components

1. **Frontend API**
   - Receives orders from clients.
   - Minimal validation (presence of `email` and `items`).

2. **Ingest Lambda**
   - Validates incoming orders in detail:
     - Ensures `items` is a non-empty array.
     - Validates each item has `sku` and `qty`.
   - Generates a unique `order_id`.
   - Pushes the order to the **SQS queue**.
   - Returns debug info:
     - Number of requests received
     - Number of requests validated
     - Number of requests enqueued

3. **SQS Queue**
   - Acts as a **buffer**, decoupling the ingestion rate from processing.
   - Orders stay in the queue until processed.
   - Provides automatic retries if a worker Lambda fails or times out.

4. **Worker Lambda**
   - Polls SQS for messages.
   - Simulates processing time (configurable delay).
   - Writes processed orders to **DynamoDB**.
   - Logs detailed debug info:
     - Order received
     - Processing time
     - Success or failure

5. **DynamoDB**
   - Stores all processed orders.
   - Serves as the final source of truth for order data.

---

## Setup Instructions

1. **Create AWS Resources**
   - DynamoDB table: `order-table-9-1-26`
   - SQS queue: `order-queue-17-1-26`
   - Two Lambda functions:
     - `IngestLambda` → triggered by API Gateway
     - `WorkerLambda` → triggered by SQS
   - API Gateway → route POST `/order` to `IngestLambda`

2. **Configure Lambda Permissions**
   - `IngestLambda` → `sqs:SendMessage` to your SQS queue
   - `WorkerLambda` → `dynamodb:PutItem` on your DynamoDB table

3. **Deploy Python Code**
   - Ingest Lambda: `lambda_ingest.py`  
   - Worker Lambda: `lambda_worker.py`  
   - Python scripts should include debugging counters to monitor requests.

4. **Test Load**
   - Use Python scripts (`asyncio + aiohttp`) to simulate concurrent orders.
   - Respect Lambda concurrency limits (10 by default on free-tier).

---

## Challenges & Learnings

1. **Concurrency Limits**
   - Free-tier Lambda limit = 10 concurrent executions.
   - Sending more requests than this caused throttling and `500` errors.

2. **Worker Lambda Timeouts**
   - Simulated processing (2–5 seconds) caused some Lambdas to **timeout** (default = 3s).
   - Result: orders received from SQS but **never written to DynamoDB**.
   - Fix: Increase Lambda timeout or reduce processing delay.

3. **Observability**
   - Without counters, it was unclear how many orders were:
     - Received
     - Successfully enqueued
     - Written to DynamoDB
   - Added debug info in both Lambdas for better monitoring.

4. **SQS as a Buffer**
   - Decouples ingestion from processing.
   - Handles bursts gracefully.
   - Automatic retries ensure reliability.

5. **Load Testing**
   - Sending hundreds of requests in one go often exceeded concurrency limits.
   - Adding **intervals between batches** helped, but free-tier limitations still bottlenecked throughput.
   - Proper load testing requires accounting for both **Lambda concurrency** and **SQS visibility timeouts**.

---

## Key Takeaways

- **Decoupled architecture** (API → Lambda → SQS → Lambda → DynamoDB) is reliable under load if concurrency and timeouts are properly configured.  
- **Monitoring and debugging** are essential — counters in Lambdas show where orders are being lost or delayed.  
- **SQS ensures no messages are lost**, even when workers fail or timeout.  
- Free-tier limitations are real bottlenecks; understanding them is key before scaling.

---

## Next Steps

- Optimize worker Lambda for faster processing (asynchronous or batch writes).  
- Increase Lambda concurrency limits on paid accounts.  
- Add **CloudWatch dashboards** to track queue depth, Lambda retries, and processing time.  
- Explore **dead-letter queues (DLQ)** for messages that fail repeatedly.

---

This setup is a **hands-on demonstration of serverless best practices** and real-world backend challenges like throttling, retries, and decoupled processing.


