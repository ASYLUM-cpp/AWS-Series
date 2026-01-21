export const handler = async (event) => {
  console.log("Validating order:", JSON.stringify(event));

  const { orderId, connectionId, amount } = event;

  // -----------------------------
  // 0️⃣ Validate input
  // -----------------------------
  if (!orderId) {
    throw new Error("INVALID_ORDER");
  }

  if (!connectionId) {
    throw new Error("MISSING_CONNECTION_ID");
  }

  // -----------------------------
  // 1️⃣ Return full event for Step Functions
  // -----------------------------
  // Preserve everything needed downstream, including connectionId
  return {
    ...event,          // orderId, connectionId, amount, sku, quantity, etc.
    status: "VALID"
  };
};
