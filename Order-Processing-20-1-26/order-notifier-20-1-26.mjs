// Lambda to notify frontend about order status - ES Module, Node 24.x
import { ApiGatewayManagementApiClient, PostToConnectionCommand } from "@aws-sdk/client-apigatewaymanagementapi";

// WebSocket API client - only base URL + stage
const wsClient = new ApiGatewayManagementApiClient({
  endpoint: `https://${process.env.WS_ENDPOINT}` // e.g., ""
});

export const handler = async (event) => {
  try {
    // Step Functions wraps the Lambda output in Payload
    const payload = event?.Payload || event;

    const { connectionId, orderId, status } = payload;

    if (!connectionId || !orderId || !status) {
      console.error("Missing required fields in payload:", payload);
      // Still return the full payload so Step Functions doesn't break
      return event;
    }

    const message = JSON.stringify({
      type: "ORDER_STATUS",
      orderId,
      status
    });

    try {
      await wsClient.send(
        new PostToConnectionCommand({
          ConnectionId: connectionId,
          Data: message
        })
      );
      console.log("Message sent to client:", message);
    } catch (error) {
      // 410 = stale connection
      if (error.$metadata?.httpStatusCode === 410 || error.name === "GoneException") {
        console.warn(`Connection ${connectionId} is gone. Consider removing it from DB.`);
      } else {
        console.error("Failed to send message:", error);
      }
    }

    // Return original input so Step Functions continues with the same payload
    return payload;
  } catch (err) {
    console.error("Unexpected error in notifier Lambda:", err);
    return payload; // always return the input to prevent breaking the SFN
  }
};
