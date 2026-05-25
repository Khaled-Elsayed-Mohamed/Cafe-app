#!/usr/bin/env node
/**
 * Sets a custom role claim on a Firebase Auth user.
 * Usage: node set-role.js <email> <role>
 * Roles:  customer | worker | owner
 *
 * Requires: GOOGLE_APPLICATION_CREDENTIALS env var pointing to a service account key JSON.
 * Example:
 *   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node set-role.js you@example.com owner
 */

const path = require("path");
const admin = require(path.resolve(__dirname, "functions/node_modules/firebase-admin"));

const [, , email, role] = process.argv;
const validRoles = ["customer", "worker", "owner"];

if (!email || !validRoles.includes(role)) {
  console.error(`Usage: node set-role.js <email> <${validRoles.join("|")}>`);
  process.exit(1);
}

admin.initializeApp();

(async () => {
  const user = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(user.uid, { role });
  console.log(`✅ Set role="${role}" on ${email} (uid: ${user.uid})`);
  console.log("   The user must sign out and sign back in for the new role to take effect.");
  process.exit(0);
})().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
