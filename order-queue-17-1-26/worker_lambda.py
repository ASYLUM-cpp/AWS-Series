import json
import time
import boto3
import random

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("ORDER_TABLE_NAME")  # Replace with your DynamoDB table name

def lambda_handler(event, context):
    print("📥 Received SQS event")
    
    total_records = len(event["Records"])
    success_count = 0
    failure_count = 0
    processed_order_ids = []

    for idx, record in enumerate(event["Records"], start=1):
        try:
            body = json.loads(record["body"])
            order_id = body.get("order_id", f"unknown-{idx}")

            print(f"\n🧾 [{idx}/{total_records}] Processing order_id: {order_id}")
            print(json.dumps(body, indent=2))

            # 🔥 Simulate processing time (important for testing)
            processing_time = random.randint(2, 5)
            print(f"⏳ Processing order {order_id} for {processing_time}s")
            time.sleep(processing_time)

            item = {
                "order_id": order_id,
                "customer_email": body["customer_email"],
                "items": body["items"],
                "status": "PROCESSED",
                "created_at": body["created_at"],
                "processed_at": int(time.time())
            }

            table.put_item(Item=item)
            success_count += 1
            processed_order_ids.append(order_id)

            print(f"✅ Order {order_id} saved to DynamoDB")

        except Exception as e:
            failure_count += 1
            print(f"❌ Failed to process message [{order_id}]: {str(e)}")
            # Raising exception tells Lambda this message FAILED (optional)
            raise e

    # Summary log for the batch
    print("\n📊 Batch Summary:")
    print(f"Total messages received: {total_records}")
    print(f"✅ Successfully processed: {success_count}")
    print(f"❌ Failed: {failure_count}")
    print(f"Processed order IDs: {processed_order_ids}")

    # Returning summary (can be helpful for testing via Lambda console)
    return {
        "status": "ok",
        "total_received": total_records,
        "success_count": success_count,
        "failure_count": failure_count,
        "processed_order_ids": processed_order_ids
    }
