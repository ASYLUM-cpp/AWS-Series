/**
 * Inventory Lambda (Step Functions + connectionId + live update)
 */

import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand
} from "@aws-sdk/lib-dynamodb";
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";

const TABLE_NAME = "inventory-19-1-26";
const DEFAULT_INITIAL_STOCK = 5;

const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient({}));

const wsClient = new ApiGatewayManagementApiClient({
  endpoint: process.env.WS_ENDPOINT
});

export const handler = async (event) => {
  const payload = event?.Payload || event;
  console.log("Incoming payload:", JSON.stringify(payload));

  const { sku, orderId, connectionId } = payload;

  if (!sku || !orderId || !connectionId) {
    return { ...payload, status: "INVALID_INPUT" };
  }

  // Check inventory
  const getCmd = new GetCommand({ TableName: TABLE_NAME, Key: { sku } });
  const getResult = await ddbClient.send(getCmd);

  if (!getResult.Item) {
    try {
      await ddbClient.send(
        new PutCommand({
          TableName: TABLE_NAME,
          Item: { sku, available: DEFAULT_INITIAL_STOCK, reserved: 0 },
          ConditionExpression: "attribute_not_exists(sku)"
        })
      );
    } catch (error) {
      if (error.name !== "ConditionalCheckFailedException") throw error;
    }
  }

  // Try reserving
  let inventorySnapshot;
  let newStatus;
  try {
    const updateCmd = new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { sku },
      UpdateExpression: "SET available = available - :one, reserved = reserved + :one",
      ConditionExpression: "available >= :one",
      ExpressionAttributeValues: { ":one": 1 },
      ReturnValues: "ALL_NEW"
    });
    const updateResult = await ddbClient.send(updateCmd);
    inventorySnapshot = updateResult.Attributes;
    newStatus = "RESERVED";
  } catch (error) {
    if (error.name === "ConditionalCheckFailedException") {
      inventorySnapshot = null;
      newStatus = "REFUND"; // mark for Step Functions to go refund
      await sendWsMessage(connectionId, { orderId, status: "OUT_OF_STOCK" }).catch(() => {});
    } else {
      throw error;
    }
  }

  // Notify frontend
  await sendWsMessage(connectionId, { orderId, status: newStatus, sku, inventorySnapshot }).catch(() => {});

  // Return payload for Step Functions downstream
  return {
    ...payload,
    status: newStatus,
    inventorySnapshot
  };
};

async function sendWsMessage(connectionId, messagePayload) {
  const command = new PostToConnectionCommand({
    ConnectionId: connectionId,
    Data: JSON.stringify(messagePayload)
  });
  try {
    await wsClient.send(command);
    console.log("WS message sent:", messagePayload);
  } catch (err) {
    if (err.name === "GoneException") {
      console.log(`Connection ${connectionId} is gone.`);
    } else {
      throw err;
    }
  }
}
