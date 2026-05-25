#!/usr/bin/env node
/**
 * Seeds Firestore menu_items with the full Macchiato & Co menu.
 * Usage: GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json node seed-menu.js
 */

const path = require("path");
const admin = require(path.resolve(__dirname, "functions/node_modules/firebase-admin"));

admin.initializeApp();
const db = admin.firestore();

const items = [
  // ── COFFEE ────────────────────────────────────────────────────────────────
  { name: "Cappuccino", description: "Medium cappuccino with steamed milk and foam.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Latte", description: "Medium latte with silky steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Flat White", description: "Double ristretto with velvety micro-foam milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Long Black", description: "Double espresso over hot water.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: [] },
  { name: "Piccolo", description: "Single ristretto topped with silky milk in a small glass.", inStorePrice: 3.80, category: "Coffee", pointValue: 3, allergens: ["dairy"] },
  { name: "Macchiato", description: "Espresso stained with a dash of milk foam.", inStorePrice: 3.80, category: "Coffee", pointValue: 3, allergens: ["dairy"] },
  { name: "Mocha", description: "Espresso with chocolate and steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "White Chocolate", description: "Espresso with white chocolate and steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Chai Latte", description: "Spiced chai blend with steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Matcha Latte", description: "Ceremonial grade matcha with steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },
  { name: "Hot Chocolate", description: "Rich premium chocolate with steamed milk.", inStorePrice: 5.50, category: "Coffee", pointValue: 5, allergens: ["dairy"] },

  // ── DRINKS — Iced ─────────────────────────────────────────────────────────
  { name: "Iced Latte", description: "Espresso over ice with cold milk.", inStorePrice: 7.00, category: "Drinks", pointValue: 7, allergens: ["dairy"] },
  { name: "Iced Mocha", description: "Espresso, chocolate, milk and ice.", inStorePrice: 7.00, category: "Drinks", pointValue: 7, allergens: ["dairy"] },
  { name: "Iced Long Black", description: "Double espresso over ice.", inStorePrice: 7.00, category: "Drinks", pointValue: 7, allergens: [] },
  { name: "Iced Coffee", description: "Chilled coffee with milk and ice.", inStorePrice: 7.00, category: "Drinks", pointValue: 7, allergens: ["dairy"] },
  { name: "Milkshake", description: "Classic milkshake. Available in Vanilla, Chocolate, Caramel or Strawberry.", inStorePrice: 7.00, category: "Drinks", pointValue: 7, allergens: ["dairy"] },

  // ── DRINKS — Frappes ──────────────────────────────────────────────────────
  { name: "Chai Frappe", description: "Blended chai frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy"] },
  { name: "Espresso Mocha Frappe", description: "Blended espresso and chocolate frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy"] },
  { name: "White Chocolate Frappe", description: "Blended white chocolate frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy"] },
  { name: "Oreo Frappe", description: "Blended Oreo cookie frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy", "gluten"] },
  { name: "Tim Tam Frappe", description: "Blended Tim Tam biscuit frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy", "gluten"] },
  { name: "Chocolate Frappe", description: "Blended rich chocolate frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy"] },
  { name: "Biscoff Frappe", description: "Blended Biscoff spread frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy", "gluten"] },
  { name: "Espresso Vanilla Frappe", description: "Blended espresso and vanilla frappe.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: ["dairy"] },

  // ── DRINKS — Fruit Chillers ────────────────────────────────────────────────
  { name: "Mango Chiller", description: "Refreshing blended mango fruit chiller.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: [] },
  { name: "Blueberry Chiller", description: "Refreshing blended blueberry fruit chiller.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: [] },
  { name: "Strawberry Chiller", description: "Refreshing blended strawberry fruit chiller.", inStorePrice: 9.00, category: "Drinks", pointValue: 9, allergens: [] },

  // ── PASTRY ────────────────────────────────────────────────────────────────
  { name: "Chocolate Croissant", description: "Buttery flaky croissant filled with rich chocolate.", inStorePrice: 7.90, category: "Pastry", pointValue: 7, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Pistachio Croissant", description: "Buttery flaky croissant filled with pistachio cream.", inStorePrice: 6.90, category: "Pastry", pointValue: 6, allergens: ["gluten", "dairy", "eggs", "nuts"] },
  { name: "Assorted Danish", description: "Choice of Mixed Berries or Apple Danish.", inStorePrice: 7.90, category: "Pastry", pointValue: 7, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Biscoff Cronut", description: "Crispy cronut layered with Biscoff spread.", inStorePrice: 6.90, category: "Pastry", pointValue: 6, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Ferrero Donut Ball", description: "Donut ball filled with Ferrero Rocher inspired filling.", inStorePrice: 7.90, category: "Pastry", pointValue: 7, allergens: ["gluten", "dairy", "eggs", "nuts"] },
  { name: "Assorted Donut", description: "Choose from Vanilla, Caramel or Chocolate.", inStorePrice: 6.50, category: "Pastry", pointValue: 6, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Scone", description: "House-made scone served with jam and cream.", inStorePrice: 6.50, category: "Pastry", pointValue: 6, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Assorted Muffin", description: "Choose from Chocolate, Triple Chocolate or Blueberry.", inStorePrice: 5.90, category: "Pastry", pointValue: 5, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Assorted Cookie", description: "Choose from Chocolate, Anzac, Macadamia, White Chocolate, Red Velvet, Smartie or Gingerbread.", inStorePrice: 4.50, category: "Pastry", pointValue: 4, allergens: ["gluten", "dairy", "eggs", "nuts"] },
  { name: "Friand", description: "Light almond-based mini cake.", inStorePrice: 5.90, category: "Pastry", pointValue: 5, allergens: ["gluten", "dairy", "eggs", "nuts"] },
  { name: "Carrot Cake", description: "Moist carrot cake topped with cream cheese frosting.", inStorePrice: 6.90, category: "Pastry", pointValue: 6, allergens: ["gluten", "dairy", "eggs", "nuts"] },
  { name: "Cheesecake", description: "Choose from With Cream, Biscoff, Chocolate or NY Cheesecake.", inStorePrice: 10.00, category: "Pastry", pointValue: 10, allergens: ["gluten", "dairy", "eggs"] },

  // ── FOOD — Savoury ────────────────────────────────────────────────────────
  { name: "Curry Chicken Pie", description: "Hearty pie filled with curried chicken.", inStorePrice: 7.90, category: "Food", pointValue: 7, allergens: ["gluten", "dairy"] },
  { name: "Sausage Roll", description: "Classic flaky pastry sausage roll.", inStorePrice: 6.90, category: "Food", pointValue: 6, allergens: ["gluten"] },
  { name: "Mini Mediterranean Quiche", description: "Vegan mini quiche with Mediterranean vegetables.", inStorePrice: 5.50, category: "Food", pointValue: 5, allergens: ["gluten"] },
  { name: "Turkey Ham and Cheese", description: "Turkey ham and cheese sandwich. Add tomato for $1 extra.", inStorePrice: 8.90, category: "Food", pointValue: 8, allergens: ["gluten", "dairy"] },
  { name: "Chicken Chorizo Wrap", description: "Halal. Egg, cheese, chicken chorizo in a wrap.", inStorePrice: 9.90, category: "Food", pointValue: 9, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Crispy Chicken Panini", description: "Schnitzel chicken, mix lettuce, cheese, tomato and spicy mayo.", inStorePrice: 11.90, category: "Food", pointValue: 11, allergens: ["gluten", "dairy", "eggs"] },
  { name: "Peri Peri Chicken Filo", description: "Peri peri chicken wrapped in crispy filo pastry.", inStorePrice: 11.90, category: "Food", pointValue: 11, allergens: ["gluten"] },
  { name: "Peri Peri Chicken Salad", description: "Peri chicken, mix lettuce, feta cheese, tomato, kalamata olives and avocado.", inStorePrice: 12.90, category: "Food", pointValue: 12, allergens: ["dairy"] },

  // ── FOOD — Deals ──────────────────────────────────────────────────────────
  { name: "Breakfast Deal", description: "Small coffee + Chicken Chorizo Wrap. Additional charge for alternative milks.", inStorePrice: 12.90, category: "Food", pointValue: 12, allergens: ["gluten", "dairy", "eggs"] },
];

(async () => {
  console.log(`\n🌱 Seeding ${items.length} menu items into Firestore...\n`);
  const batch = db.batch();

  for (const item of items) {
    const ref = db.collection("menu_items").doc();
    batch.set(ref, {
      name: item.name,
      description: item.description,
      inStorePrice: item.inStorePrice,
      appPrice: item.inStorePrice,
      isAppOnly: false,
      allergens: item.allergens,
      pointValue: item.pointValue,
      category: item.category,
      isAvailable: true,
    });
    console.log(`  + ${item.category.padEnd(8)} ${item.name}`);
  }

  await batch.commit();
  console.log("\n✅ All menu items seeded successfully.");
  process.exit(0);
})().catch((err) => {
  console.error("❌ Error:", err.message);
  process.exit(1);
});
