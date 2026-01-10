import json
import urllib.parse
import urllib.request
import base64
import os

# -------------------------
# Environment variables
# -------------------------
CRUD_API_URL = ""
CRUD_API_KEY = ""
COGNITO_DOMAIN = ""
COGNITO_CLIENT_ID = ""
COGNITO_CLIENT_SECRET = ""
COGNITO_REDIRECT_URI = ""
ALLOWED_ORIGIN = "*"

# -------------------------
# Lambda handler
# -------------------------
def lambda_handler(event, context):
    print("DEBUG: Incoming event:", json.dumps(event))

    path = event.get("rawPath") or event.get("path")
    method = event.get("httpMethod", "")
    body = event.get("body", None)

    # -------------------------
    # 0️⃣ Handle CORS preflight
    # -------------------------
    if method.upper() == "OPTIONS":
        print("DEBUG: Handling CORS preflight")
        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps({"message": "CORS preflight OK"})
        }

    # -------------------------
    # 1️⃣ Handle /auth/exchange
    # -------------------------
    if path == "/auth/exchange" and method.upper() == "POST":
        return handle_auth_exchange(body)

    # -------------------------
    # 2️⃣ Extract user info
    # -------------------------
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    user_role = claims.get("custom:role", "user")
    user_sub = claims.get("sub", "unknown")
    print(f"DEBUG: User role={user_role}, sub={user_sub}")

    # -------------------------
    # 3️⃣ Authorization logic
    # -------------------------
    # Only GET /products restricted to admin
    if method.upper() == "GET" and path == "/products" and user_role != "admin":
        print("WARN: Non-admin attempted to view all products")
        return {
            "statusCode": 403,
            "headers": cors_headers(),
            "body": json.dumps({"error": "You are not authorized to view all products"})
        }

    # -------------------------
    # 4️⃣ Forward request to CRUD API
    # -------------------------
    try:
        data_bytes = body.encode("utf-8") if body else None
        req_url = f"{CRUD_API_URL}{path}"
        print(f"DEBUG: Forwarding {method} request to CRUD API at {req_url}")
        print("DEBUG: Request body:", body)

        req = urllib.request.Request(
            url=req_url,
            data=data_bytes,
            method=method
        )
        req.add_header("x-api-key", CRUD_API_KEY)
        req.add_header("Content-Type", "application/json")

        # Forward Authorization header if exists
        headers = event.get("headers") or {}
        auth_header = headers.get("Authorization") or headers.get("authorization")
        if auth_header:
            req.add_header("Authorization", auth_header)
            print("DEBUG: Forwarding Authorization header")

        with urllib.request.urlopen(req) as resp:
            resp_body = resp.read().decode()
            resp_status = resp.getcode()
            print(f"DEBUG: CRUD API response status={resp_status}, body={resp_body}")

    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"ERROR: HTTPError {e.code} - {error_body}")
        return {
            "statusCode": e.code,
            "headers": cors_headers(),
            "body": json.dumps({"error": error_body})
        }
    except Exception as e:
        print(f"ERROR: Exception forwarding request: {str(e)}")
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"error": f"Error forwarding request: {str(e)}"})
        }

    # -------------------------
    # 5️⃣ Return CRUD API response
    # -------------------------
    return {
        "statusCode": resp_status,
        "headers": cors_headers(),
        "body": resp_body
    }

# -------------------------
# Handle /auth/exchange
# -------------------------
def handle_auth_exchange(body):
    try:
        data = json.loads(body)
        code = data.get("code")
        print("DEBUG: Authorization code:", code)

        if not code:
            return {
                "statusCode": 400,
                "headers": cors_headers(),
                "body": json.dumps({"error": "Authorization code is required"})
            }

        token_url = f"{COGNITO_DOMAIN}/oauth2/token"
        post_data = urllib.parse.urlencode({
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": COGNITO_REDIRECT_URI
        }).encode("utf-8")

        auth_string = f"{COGNITO_CLIENT_ID}:{COGNITO_CLIENT_SECRET}"
        auth_header = base64.b64encode(auth_string.encode()).decode()

        req = urllib.request.Request(token_url, data=post_data)
        req.add_header("Content-Type", "application/x-www-form-urlencoded")
        req.add_header("Authorization", f"Basic {auth_header}")

        with urllib.request.urlopen(req) as response:
            resp_body = response.read().decode()
            print("DEBUG: Cognito response body:", resp_body)
            tokens = json.loads(resp_body)

        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps({
                "id_token": tokens.get("id_token"),
                "access_token": tokens.get("access_token"),
                "refresh_token": tokens.get("refresh_token")
            })
        }

    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print("ERROR HTTP:", e.code, error_body)
        return {
            "statusCode": e.code,
            "headers": cors_headers(),
            "body": json.dumps({"error": error_body})
        }
    except Exception as e:
        print("ERROR: Failed to exchange code:", str(e))
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"error": f"Failed to exchange code: {str(e)}"})
        }

# -------------------------
# CORS helper
# -------------------------
def cors_headers():
    return {
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "POST,GET,OPTIONS,PUT,DELETE",
        "Content-Type": "application/json"
    }
