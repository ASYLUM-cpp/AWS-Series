import json
import boto3
from datetime import datetime

eventbridge = boto3.client("events")

def lambda_handler(event, context):
    detail = event["detail"]
    order = detail["order"]

    out_of_stock_items = []

    for item in order["items"]:
        available = 5  # simulate out of stock
        if available < item["quantity"]:
            out_of_stock_items.append({
                "sku": item["sku"],
                "requestedQuantity": item["quantity"],
                "availableQuantity": available
            })

    if out_of_stock_items:
        failure_event = {
            "eventVersion": "1.0",
            "order": {
                "orderId": order["orderId"],
                "items": out_of_stock_items
            },
            "customer": {
                "userId": detail["customer"]["userId"]
            },
            "reason": "INSUFFICIENT_STOCK",
            "metadata": {
                "createdAt": datetime.utcnow().isoformat() + "Z",
                "correlationId": detail["metadata"]["correlationId"]
            }
        }

        eventbridge.put_events(
            Entries=[
                {
                    "Source": "com.mycompany.inventory",
                    "DetailType": "InventoryOutOfStock",
                    "Detail": json.dumps(failure_event),
                    "EventBusName": "ecommerce-bus-21-1-26"
                }
            ]
        )

        print("InventoryOutOfStock event emitted")
        return {"status": "out_of_stock"}

    print("Inventory updated successfully")
    return {"status": "inventory_ok"}
