import json

def lambda_handler(event, context):
    print("Analytics service invoked")

    detail = event["detail"]

    print("Recording analytics event:")
    print(json.dumps({
        "eventVersion": detail["eventVersion"],
        "orderId": detail["order"]["orderId"],
        "amount": detail["order"]["totalAmount"],
        "paymentStatus": detail["payment"]["status"]
    }))

    # Later: S3, DynamoDB, OpenSearch, Redshift

    return {"status": "analytics recorded"}
