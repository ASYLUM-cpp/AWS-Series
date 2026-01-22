import json

def lambda_handler(event, context):
    print("Refund service invoked")

    detail = event["detail"]

    order_id = detail["order"]["orderId"]
    user_id = detail["customer"]["userId"]
    reason = detail["reason"]

    print(f"Issuing refund for order {order_id}")
    print(f"User: {user_id}")
    print(f"Reason: {reason}")

    # Later:
    # - Payment gateway refund
    # - Ledger update
    # - RefundCompleted event

    return {"status": "refund_initiated"}
