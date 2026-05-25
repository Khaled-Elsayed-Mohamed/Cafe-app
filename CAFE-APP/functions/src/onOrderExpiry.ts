import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

export const onOrderExpiry = functionsV1.pubsub
  .schedule("every 15 minutes")
  .onRun(async (_context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expiredSnapshot = await db
      .collection("orders")
      .where("status", "==", "ready")
      .where("expiresAt", "<", now)
      .get();

    if (expiredSnapshot.empty) {
      functionsV1.logger.info("onOrderExpiry: no expired orders found.");
      return;
    }

    const batch = db.batch();
    expiredSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "expired",
        "statusTimestamps.expired": now,
      });
    });

    await batch.commit();
    functionsV1.logger.info(`onOrderExpiry: expired ${expiredSnapshot.size} orders.`);
  });
