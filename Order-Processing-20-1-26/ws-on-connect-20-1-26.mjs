// $connect Lambda - Node.js 24.x (ES Module)
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";

// DynamoDB DocumentClient
const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

// WebSocket API client - only base URL + stage
const wsClient = new ApiGatewayManagementApiClient({
  endpoint: `https://${process.env.WS_ENDPOINT}` // e.g., ""
});

export const handler = async (event) => {
  try {
    const connectionId = event?.requestContext?.connectionId;
    console.log("New connection event:", JSON.stringify(event));

    if (!connectionId) {
      console.error("Missing connectionId in requestContext:", event);
      return { statusCode: 400, body: "Missing connectionId" };
    }

    // Store connection in DynamoDB
    console.log("Storing connection in DynamoDB:", connectionId);
    try {
      await ddbClient.send(
        new PutCommand({
          TableName: process.env.CONNECTIONS_TABLE,
          Item: {
            connectionID: connectionId, // primary key
            connectedAt: Date.now()
          }
        })
      );
      console.log("Connection stored successfully:", connectionId);
    } catch (ddbErr) {
      console.error("Failed to store connection in DynamoDB:", ddbErr);
      return { statusCode: 500, body: "Failed to store connection" };
    }

    // Do NOT send connectionId here anymore.
    // The front end should send a "REGISTER" message to the $default route.
    console.log("Waiting for front-end REGISTER message to respond with connectionId");

    return { statusCode: 200, body: "Connected" };
  } catch (err) {
    console.error("Unexpected error in $connect Lambda:", err);
    return { statusCode: 500, body: "Internal Server Error" };
  }
};
