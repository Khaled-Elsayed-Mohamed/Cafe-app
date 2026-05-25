import * as functionsV1 from "firebase-functions/v1";
import * as https from "https";

interface ChargeCardData {
  nonce: string;
  amount: number;
  currency: string;
}

interface SquareChargeResponse {
  payment?: { id: string; status: string };
  errors?: Array<{ code: string; detail: string; category: string }>;
}

export const chargeCard = functionsV1.https.onCall(
  async (data: ChargeCardData, context: functionsV1.https.CallableContext) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError(
        "unauthenticated",
        "Must be signed in to place an order."
      );
    }

    const { nonce, amount, currency } = data;
    if (!nonce || typeof amount !== "number" || amount <= 0) {
      throw new functionsV1.https.HttpsError(
        "invalid-argument",
        "nonce and positive amount required."
      );
    }

    const accessToken = functionsV1.config().square?.access_token as string | undefined;
    if (!accessToken) {
      throw new functionsV1.https.HttpsError("internal", "Square access token not configured.");
    }

    const amountMoney = {
      amount: Math.round(amount * 100),
      currency: currency ?? "USD",
    };

    const body = JSON.stringify({
      source_id: nonce,
      idempotency_key: `${context.auth.uid}-${Date.now()}`,
      amount_money: amountMoney,
    });

    const paymentReference = await new Promise<string>((resolve, reject) => {
      const req = https.request(
        {
          hostname: "connect.squareupsandbox.com",
          path: "/v2/payments",
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
            "Content-Length": Buffer.byteLength(body),
          },
        },
        (res) => {
          let raw = "";
          res.on("data", (chunk) => (raw += chunk));
          res.on("end", () => {
            const parsed: SquareChargeResponse = JSON.parse(raw);
            if (parsed.errors && parsed.errors.length > 0) {
              const err = parsed.errors[0];
              reject(
                new functionsV1.https.HttpsError("failed-precondition", err.detail ?? err.code)
              );
            } else if (parsed.payment?.id) {
              resolve(parsed.payment.id);
            } else {
              reject(new functionsV1.https.HttpsError("internal", "Unexpected Square response."));
            }
          });
        }
      );
      req.on("error", (e) =>
        reject(new functionsV1.https.HttpsError("internal", e.message))
      );
      req.write(body);
      req.end();
    });

    return { paymentReference };
  }
);
