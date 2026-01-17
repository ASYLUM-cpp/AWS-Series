import json
import uuid
import time
import boto3
import os

sqs = boto3.client("sqs")
QUEUE_URL = "ORDER_QUEUE_URL"  # Replace with your SQS queue URL or use environment variable

# Counters for debugging
total_requests_received = 0
total_requests_validated = 0
total_requests_enqueued = 0

def lambda_handler(event, context):
    global total_requests_received, total_requests_validated, total_requests_enqueued
    
    total_requests_received += 1
    print("🔍 Received event keys:", list(event.keys()))

    # Parse body
    if "body" in event:
        body = json.loads(event["body"])
    else:
        body = event

    print("📦 Parsed body:", json.dumps(body, indent=2))

    # Validation
    validation_error = validate_order(body)
    if validation_error:
        return error_response(validation_error)

    total_requests_validated += 1

    # Create order
    try:
        order_id = str(uuid.uuid4())

        order = {
            "order_id": order_id,
            "customer_email": body["email"],
            "items": body["items"],
            "status": "CREATED",
            "created_at": int(time.time())
        }

        print("📨 Sending order to SQS:", json.dumps(order, indent=2))

        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(order)
        )

        total_requests_enqueued += 1
        print(f"✅ Order enqueued successfully: {order_id}")

        return {
            "statusCode": 201,
            "headers": cors_headers(),
            "body": json.dumps({
                "message": "Order accepted",
                "order_id": order_id,
                "debug": {
                    "total_requests_received": total_requests_received,
                    "total_requests_validated": total_requests_validated,
                    "total_requests_enqueued": total_requests_enqueued
                }
            })
        }

    except Exception as e:
        print("❌ SQS Error:", str(e))
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({
                "error": f"Failed to enqueue order: {str(e)}",
                "debug": {
                    "total_requests_received": total_requests_received,
                    "total_requests_validated": total_requests_validated,
                    "total_requests_enqueued": total_requests_enqueued
                }
            })
        }

# ----------------- Helper Functions -----------------

def validate_order(body):
    if "items" not in body:
        return "Missing 'items' in order"
    
    if "email" not in body:
        return "Missing 'email' in order"
    
    if not isinstance(body["items"], list):
        return "'items' must be an array"
    
    if len(body["items"]) == 0:
        return "'items' array cannot be empty"
    
    for i, item in enumerate(body["items"]):
        if not isinstance(item, dict):
            return f"Item at index {i} must be an object"
        if "sku" not in item:
            return f"Item at index {i} missing 'sku' field"
        if "qty" not in item:
            return f"Item at index {i} missing 'qty' field"
        if not isinstance(item["qty"], int) or item["qty"] <= 0:
            return f"Item at index {i} has invalid quantity"
    
    return None

def cors_headers():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "POST,OPTIONS"
    }
