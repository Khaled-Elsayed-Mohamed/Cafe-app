import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

export const onOrderStatusUpdate = functionsV1.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "completed" && after.status === "completed") {
      const { customerId, items, totalPointsEarned } = after as {
        customerId: string;
        items: Array<{ menuItemId: string; name: string; pointValue: number }>;
        totalPointsEarned: number;
      };
      const db = admin.firestore();
      const batch = db.batch();
      const now = admin.firestore.FieldValue.serverTimestamp();

      const loyaltyRef = db.collection("loyalty_accounts").doc(customerId);
      batch.update(loyaltyRef, {
        totalPoints: admin.firestore.FieldValue.increment(totalPointsEarned),
        orderCount: admin.firestore.FieldValue.increment(1),
        updatedAt: now,
      });

      const txRef = db.collection("point_transactions").doc();
      batch.set(txRef, {
        customerId,
        orderId: context.params.orderId,
        itemBreakdown: items.map((item) => ({
          itemId: item.menuItemId,
          itemName: item.name,
          pointsEarned: item.pointValue,
        })),
        totalPointsEarned,
        source: "pre_order",
        createdAt: now,
      });

      await batch.commit();

      const loyaltySnap = await loyaltyRef.get();
      const orderCount = (loyaltySnap.data()?.orderCount ?? 0) as number;

      if (orderCount % 10 === 0) {
        const claimDate = new Date();
        const expiryDate = new Date(claimDate);
        expiryDate.setDate(expiryDate.getDate() + 30);

        await db.collection("rewards").add({
          customerId,
          type: "free_coffee",
          monetaryValue: 5.0,
          claimDate: admin.firestore.Timestamp.fromDate(claimDate),
          expiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
          redemptionStatus: "unredeemed",
          redeemedAt: null,
        });

        functionsV1.logger.info(`onOrderStatusUpdate: free coffee reward for ${customerId}`);
      }
    }
  });
