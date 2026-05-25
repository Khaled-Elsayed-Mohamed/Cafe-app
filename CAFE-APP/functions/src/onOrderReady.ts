import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

export const onOrderReady = functionsV1.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "ready" && after.status === "ready") {
      const { customerId } = after as { customerId: string };
      const orderId = context.params.orderId as string;

      const customerDoc = await admin.firestore()
        .collection("customers")
        .doc(customerId)
        .get();

      const fcmToken = customerDoc.data()?.fcmToken as string | undefined;

      if (!fcmToken) {
        functionsV1.logger.info(`onOrderReady: no FCM token for ${customerId}, skipping.`);
        return;
      }

      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title: "Order Ready",
          body: `Your order #${orderId.substring(0, 8).toUpperCase()} is ready for pickup!`,
        },
        data: { orderId },
        apns: {
          payload: {
            aps: { sound: "default", badge: 1 },
          },
        },
      };

      try {
        await admin.messaging().send(message);
        functionsV1.logger.info(`onOrderReady: push sent to ${customerId}`);
      } catch (err) {
        functionsV1.logger.error("onOrderReady: failed to send push", err);
      }
    }
  });
