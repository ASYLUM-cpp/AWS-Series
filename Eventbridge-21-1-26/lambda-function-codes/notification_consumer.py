import json

def lambda_handler(event, context):
    print("Notification service invoked")

    detail = event["detail"]

    order_id = detail["order"]["orderId"]
    user_id = detail["customer"]["userId"]
    amount = detail["order"]["totalAmount"]

    print(f"Sending confirmation to user {user_id}")
    print(f"Order {order_id} for amount ${amount}")

    # Later: SES / SNS / WhatsApp / SMS

    return {"status": "notification sent"}
