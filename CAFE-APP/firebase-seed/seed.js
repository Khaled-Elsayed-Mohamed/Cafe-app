#!/usr/bin/env node
/**
 * Seeds Firestore with menu_items and cafe_config from seed.json.
 *
 * Usage:
 *   Emulator:    node seed.js            (default — targets localhost:8080)
 *   Production:  node seed.js --prod     (requires GOOGLE_APPLICATION_CREDENTIALS)
 */

const path = require("path");
// Reuse firebase-admin already installed in the functions directory
const admin = require(path.resolve(__dirname, "../functions/node_modules/firebase-admin"));

const isProd = process.argv.includes("--prod");

if (isProd) {
  console.log("⚠️  Seeding PRODUCTION Firestore. Ctrl+C within 3s to cancel.");
  setTimeout(run, 3000);
} else {
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || "localhost:8080";
  console.log("🌱 Seeding emulator at", process.env.FIRESTORE_EMULATOR_HOST);
  run();
}

async function run() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: isProd ? undefined : "demo-cafeapp" });
  }

  const db = admin.firestore();
  const seed = require("./seed.json");

  for (const [collection, docs] of Object.entries(seed)) {
    for (const [docId, data] of Object.entries(docs)) {
      await db.collection(collection).doc(docId).set(resolveTimestamps(data));
      console.log(`  ✓ ${collection}/${docId}`);
    }
  }

  console.log("\n✅ Seed complete.");
  process.exit(0);
}

function resolveTimestamps(obj) {
  if (obj === null || typeof obj !== "object") return obj;
  if (obj.__datatype__ === "timestamp") {
    return admin.firestore.Timestamp.fromDate(new Date(obj.value));
  }
  const out = Array.isArray(obj) ? [] : {};
  for (const [k, v] of Object.entries(obj)) out[k] = resolveTimestamps(v);
  return out;
}
