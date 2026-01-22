import json
import boto3
import uuid
from datetime import datetime

eventbridge = boto3.client("events")

def lambda_handler(event, context):
    detail = {
        "eventVersion": "1.0",
        "order": {
            "orderId": f"ord-{uuid.uuid4()}",
            "currency": "USD",
            "totalAmount": 599.99,
            "items": [
                {
                    "sku": "sku-abc",
                    "quantity": 2,
                    "price": 199.99
                }
            ]
        },
        "customer": {
            "userId": "usr-42"
        },
        "payment": {
            "method": "CARD",
            "status": "PAID"
        },
        "metadata": {
            "createdAt": datetime.utcnow().isoformat() + "Z",
            "correlationId": context.aws_request_id
        }
    }

    response = eventbridge.put_events(
        Entries=[
            {
                "Source": "com.mycompany.orders",
                "DetailType": "OrderCreated",
                "Detail": json.dumps(detail),
                "EventBusName": "ecommerce-bus-21-1-26"
            }
        ]
    )

    return {
        "statusCode": 200,
        "body": response
    }
