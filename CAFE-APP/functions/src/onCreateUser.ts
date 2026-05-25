import * as functionsV1 from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

export const onCreateUser = functionsV1.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  const membershipBarcode = uuidv4();

  await db.collection("loyalty_accounts").doc(user.uid).set({
    customerId: user.uid,
    membershipBarcode,
    totalPoints: 0,
    orderCount: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  functionsV1.logger.info(`onCreateUser: created loyalty account for ${user.uid}`);
});
