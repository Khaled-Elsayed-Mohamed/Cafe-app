import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";

interface LookupMemberData {
  barcode: string;
}

export const lookupMember = functionsV1.https.onCall(
  async (data: LookupMemberData, context: functionsV1.https.CallableContext) => {
    if (!context.auth) {
      throw new functionsV1.https.HttpsError("unauthenticated", "Must be signed in.");
    }

    const role = context.auth.token.role as string | undefined;
    if (role !== "worker" && role !== "owner") {
      throw new functionsV1.https.HttpsError("permission-denied", "Staff access required.");
    }

    const { barcode } = data;
    if (!barcode || typeof barcode !== "string") {
      throw new functionsV1.https.HttpsError("invalid-argument", "barcode is required.");
    }

    const db = admin.firestore();
    const snap = await db
      .collection("loyalty_accounts")
      .where("membershipBarcode", "==", barcode)
      .limit(1)
      .get();

    if (snap.empty) {
      throw new functionsV1.https.HttpsError("not-found", "Member not found.");
    }

    const uid = snap.docs[0].id;
    const loyaltyData = snap.docs[0].data();

    const customerDoc = await db.collection("customers").doc(uid).get();
    const displayName = (customerDoc.data()?.displayName as string) ?? "Unknown";

    return {
      displayName,
      totalPoints: (loyaltyData.totalPoints as number) ?? 0,
    };
  }
);
