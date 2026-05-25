import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

interface AwardItem {
  menuItemId: string;
  itemName: string;
  pointsEarned: number;
}

interface AwardInStorePointsData {
  barcode: string;
  items: AwardItem[];
}

export const awardInStorePoints = functionsV1.https.onCall(
  async (data: AwardInStorePointsData, context: functionsV1.https.CallableContext) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError("unauthenticated", "Must be signed in.");
    }

    const role = context.auth.token.role as string | undefined;
    if (role !== "worker" && role !== "owner") {
      throw new functionsV1.https.HttpsError("permission-denied", "Staff access required.");
    }

    const { barcode, items } = data;

    const db = admin.firestore();
    const snap = await db
      .collection("loyalty_accounts")
      .where("membershipBarcode", "==", barcode)
      .limit(1)
      .get();

    if (snap.empty) {
      throw new functionsV1.https.HttpsError("not-found", "Member not found.");
    }

    const loyaltyRef = snap.docs[0].ref;
    const loyaltyData = snap.docs[0].data();
    const customerId = snap.docs[0].id;
    const totalPoints = items.reduce((sum, i) => sum + i.pointsEarned, 0);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const batch = db.batch();
    batch.update(loyaltyRef, {
      totalPoints: admin.firestore.FieldValue.increment(totalPoints),
      orderCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });

    const txRef = db.collection("point_transactions").doc();
    batch.set(txRef, {
      customerId,
      orderId: "in_store",
      itemBreakdown: items.map((i) => ({
        itemId: i.menuItemId,
        itemName: i.itemName,
        pointsEarned: i.pointsEarned,
      })),
      totalPointsEarned: totalPoints,
      source: "in_store",
      createdAt: now,
    });

    await batch.commit();

    const updatedCount = ((loyaltyData.orderCount as number) ?? 0) + 1;
    if (updatedCount % 10 === 0) {
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
    }

    return { totalPointsAwarded: totalPoints };
  }
);
