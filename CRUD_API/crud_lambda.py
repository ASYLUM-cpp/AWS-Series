import json
import boto3
from decimal import Decimal
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("")

# Convert DynamoDB Decimals to float for JSON
def decimal_fix(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

# Standardized API response
def response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps(body, default=decimal_fix)
    }

# Type validation helper
def validate_product_data(data, require_all_fields=True):
    fields = {
        "product_id": str,
        "name": str,
        "price": (int, float, Decimal),
        "currency": str,
        "in_stock": (bool, int)
    }
    errors = []

    for key, typ in fields.items():
        if key not in data:
            if require_all_fields:
                errors.append(f"Missing '{key}'")
            continue
        if not isinstance(data[key], typ):
            errors.append(f"Invalid type for '{key}', expected {typ}")

    return errors

def lambda_handler(event, context):
    print("EVENT:", json.dumps(event))
    
    method = event.get("httpMethod")
    path_params = event.get("pathParameters") or {}
    product_id = path_params.get("product_id")

    body = {}
    if event.get("body"):
        try:
            body = json.loads(event["body"], parse_float=Decimal)
        except json.JSONDecodeError:
            return response(400, {"error": "Invalid JSON body"})

    # ---------------- CREATE ----------------
    if method == "POST":
        errors = validate_product_data(body, require_all_fields=True)
        if errors:
            return response(400, {"errors": errors})

        try:
            table.put_item(Item=body)
            return response(201, {"message": "Product created", "product": body})
        except ClientError as e:
            return response(500, {"error": str(e)})

    # ---------------- READ ALL ----------------
    if method == "GET" and not product_id:
        try:
            data = table.scan()
            return response(200, data.get("Items", []))
        except ClientError as e:
            return response(500, {"error": str(e)})

    # ---------------- READ ONE ----------------
    if method == "GET" and product_id:
        try:
            data = table.get_item(Key={"product_id": product_id})
            if "Item" not in data:
                return response(404, {"error": "Product not found"})
            return response(200, data["Item"])
        except ClientError as e:
            return response(500, {"error": str(e)})

    # ---------------- UPDATE ----------------
    if method == "PUT":
        if not product_id:
            return response(400, {"error": "Missing product_id in path"})

        if "product_id" in body and body["product_id"] != product_id:
            return response(400, {"error": "Cannot change product_id"})

        errors = validate_product_data(body, require_all_fields=False)
        if errors:
            return response(400, {"errors": errors})

        if not body:
            return response(400, {"error": "No fields to update"})

        update_expr = []
        expr_vals = {}
        for k, v in body.items():
            update_expr.append(f"{k} = :{k}")
            expr_vals[f":{k}"] = v

        try:
            table.update_item(
                Key={"product_id": product_id},
                UpdateExpression="SET " + ", ".join(update_expr),
                ExpressionAttributeValues=expr_vals
            )
            return response(200, {"message": "Product updated"})
        except ClientError as e:
            return response(500, {"error": str(e)})

    # ---------------- DELETE ----------------
    if method == "DELETE":
        if not product_id:
            return response(400, {"error": "Missing product_id in path"})
        try:
            table.delete_item(Key={"product_id": product_id})
            return response(200, {"message": "Product deleted"})
        except ClientError as e:
            return response(500, {"error": str(e)})

    # ---------------- FALLBACK ----------------
    return response(405, {"error": "Method not allowed"})
