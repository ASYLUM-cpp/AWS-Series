export const handler = async (event) => {
  // If called via Step Functions Lambda Invoke, extract Payload
  const payload = event.Payload || event;

  console.log("Refunding payment for order:", JSON.stringify(payload));

  const { orderId, connectionId, amount } = payload;

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
  // 1️⃣ Refund logic (mocked for now)
  // -----------------------------
  // TODO: integrate actual payment gateway if needed
  console.log(`Payment refunded: ${amount} for order ${orderId}`);

  // -----------------------------
  // 2️⃣ Return full event for Step Functions
  // -----------------------------
  return {
    ...payload,       // preserve everything for downstream
    status: "REFUNDED"
  };
};
