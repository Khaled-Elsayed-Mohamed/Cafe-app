# Feature Specification: iOS Café App

**Feature Branch**: `001-ios-cafe-app`

**Created**: 2026-05-24

**Status**: Draft

**Input**: User description: Full product specification — pre-order placement, membership loyalty, menu browsing, worker order fulfillment, payments, and push notifications for a café management iOS app.

## Clarifications

### Session 2026-05-24

- Q: Can customers schedule pre-orders for a future date (e.g., tomorrow), or are they limited to same-day pickup only? → A: Same-day only — customers can only pick a ready-by time later today during the café's current operating hours.
- Q: Does the café track per-item stock counts, or use a simple available/unavailable toggle? → A: Availability toggle only — staff manually marks items unavailable; no stock counts or race-condition handling needed.
- Q: How does a customer get their membership barcode — auto-generated at signup, or linked to a pre-printed physical card? → A: Auto-generated at registration — a unique barcode is created automatically when the customer creates their account.
- Q: What does the customer see when they open the app without a network connection? → A: Show cached menu with an offline banner — display the last-known menu with a visible "You're offline" notice; ordering is blocked while offline.
- Q: How does reward redemption status get updated in the system — customer-initiated, staff-initiated, or automatic? → A: Customer-initiated in-app — the customer taps "Redeem" to mark the reward as pending redemption; staff visually confirms at the counter. The app reflects the pending status immediately.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Menu Browsing & Search (Priority: P1)

A customer opens the app and sees the full menu organized by category (e.g., Coffee, Food, Drinks, Pastry). They can search for items by name or description, filter by category, and tap any item to see its details including name, price, and allergen information. Seasonal app-only items are clearly distinguished from the regular menu.

**Why this priority**: Without a functional menu, no ordering is possible. This is the entry point for every customer interaction and delivers standalone value (browse before deciding to order).

**Independent Test**: A user can open the app, see the menu load within 2 seconds, search for an item, and view its detail — without placing any order.

**Acceptance Scenarios**:

1. **Given** the app is launched, **When** the menu screen appears, **Then** all available items load within 2 seconds, grouped by category.
2. **Given** the menu is displayed, **When** the customer types a search term, **Then** the list filters instantly to matching items (by name or description) without a network call.
3. **Given** the menu is displayed, **When** the customer taps an item, **Then** a detail view shows the name, price, description, and allergens.
4. **Given** there are app-only seasonal items, **When** the customer views the menu, **Then** those items are clearly marked as app-exclusive with their app price.
5. **Given** the customer pulls down on the menu list, **When** refresh completes, **Then** any menu changes (new items, price updates) are reflected.
6. **Given** the café is closed, **When** a customer browses the menu, **Then** menu items are visible but a clear "café closed" indicator prevents ordering.
7. **Given** the device has no network connection, **When** the customer opens the menu, **Then** the last-cached menu is displayed with a visible "You're offline" banner, and placing orders is disabled until connectivity is restored.

---

### User Story 2 - Pre-Order Placement & Payment (Priority: P1)

A customer selects items, customizes them (size, special instructions), chooses a "ready by" time, and pays in-app. The order is only created after successful payment. The customer immediately sees their updated loyalty points balance after payment completes.

**Why this priority**: Pre-ordering with in-app payment is the core revenue flow. It directly delivers the value proposition of skipping the queue.

**Independent Test**: A customer can add items to a cart, specify a pickup time, pay, and receive confirmation — with points appearing in their account immediately.

**Acceptance Scenarios**:

1. **Given** items are in the cart, **When** the customer selects a "ready by" time later today during café operating hours (and more than 15 minutes before closing), **Then** the time is accepted and checkout proceeds.
2. **Given** the customer selects a ready-by time within 15 minutes of the café's closing time, **When** they attempt to confirm, **Then** the app shows "Can't place order — café closing soon" and blocks submission.
3. **Given** the café is currently closed, **When** the customer attempts to place an order, **Then** the app shows a "café closed" message and prevents checkout.
4. **Given** a valid order and payment details, **When** payment succeeds, **Then** an order is created in the system and the customer sees a confirmation with their order number.
5. **Given** payment fails (e.g., card declined), **When** the error occurs, **Then** no order is created, the customer sees a friendly error message, and can retry.
6. **Given** payment is confirmed, **When** the confirmation screen appears, **Then** the customer's updated loyalty points balance (including points just earned) is visible.
7. **Given** an order has been placed and paid, **When** the customer attempts to cancel, **Then** the app indicates cancellation is not available after payment.

---

### User Story 3 - Pre-Order Fulfillment (Worker) (Priority: P1)

A café staff member sees incoming pre-orders in a real-time queue, accepts them, checks off each item as it is prepared, and marks the order complete. The customer is automatically notified when their order is ready.

**Why this priority**: Without fulfillment, the pre-order flow has no conclusion. This story closes the loop for the primary revenue workflow.

**Independent Test**: A worker can log into the worker app, see a new pre-order appear, accept it, check off all items, and confirm the customer notification was sent.

**Acceptance Scenarios**:

1. **Given** a customer places a pre-order, **When** the worker app is open, **Then** the new order appears in the queue in real-time (within 1 second) without a manual refresh.
2. **Given** an order is in the queue, **When** the worker taps it, **Then** they see the full order details: order number, customer name, items, sizes, special instructions, and time remaining until the requested ready time.
3. **Given** an order is displayed, **When** the worker taps "Accept," **Then** the order status changes to "in process" and the customer's tracking view updates.
4. **Given** the worker is fulfilling an order, **When** they check off each item as complete, **Then** the item is visually marked done.
5. **Given** all items in an order are checked off, **When** the last item is marked, **Then** the order status automatically changes to "ready" and a push notification is sent to the customer.
6. **Given** an order has been in "ready" state for an extended period without pickup, **When** the timeout threshold is reached, **Then** the order is automatically marked as expired.

---

### User Story 4 - Loyalty Points & Membership (Priority: P2)

A customer earns loyalty points automatically on every purchase (pre-order or in-store). Points are calculated based on the specific items purchased, not the order total. Every 10th order triggers a free coffee reward. The customer can view their current points balance and claimed rewards in their profile.

**Why this priority**: The loyalty program differentiates this app from a simple ordering tool and drives repeat visits. It can be demonstrated independently by showing points accumulate correctly.

**Independent Test**: After a payment, a customer's points balance increases by the correct item-based amount, visible immediately in their profile without a manual refresh.

**Acceptance Scenarios**:

1. **Given** a completed payment, **When** the transaction processes, **Then** points equal to the sum of each item's defined point value are added to the customer's account immediately.
2. **Given** the customer views their profile, **When** the profile screen loads, **Then** their current points total and a history of recent transactions are visible.
3. **Given** the customer completes their 10th order, **When** points are awarded, **Then** a free coffee reward (valid for 30 days) is automatically added to their account.
4. **Given** the customer has a claimed reward, **When** they view the reward, **Then** they see the reward type, value, and expiration date.
5. **Given** an active membership barcode, **When** the customer views their home or profile screen, **Then** their membership barcode is displayed and scannable from the phone screen.

---

### User Story 5 - In-Store Purchase Points via Barcode Scan (Priority: P2)

A customer shows their membership barcode (printed card or phone screen) to a café staff member at the point of sale. The staff scans it, the customer's name and current points balance appear on the register, and after the customer pays, points are awarded automatically based on what they purchased.

**Why this priority**: This is the critical bridge between in-store sales and the loyalty app, and the mechanism that makes the physical membership card valuable.

**Independent Test**: A staff member can scan a membership barcode, see the customer's name and points balance displayed, and after a sale, the customer's app shows updated points — without any manual entry.

**Acceptance Scenarios**:

1. **Given** a valid membership barcode is scanned, **When** the lookup completes, **Then** the register displays the customer's name and current points balance within 1 second.
2. **Given** an unrecognized or invalid barcode is scanned, **When** the lookup fails, **Then** the register shows a clear error (e.g., "Member not found") and the staff can still process the sale without loyalty points.
3. **Given** a member's account is inactive or suspended, **When** their barcode is scanned, **Then** a status message is shown and the sale proceeds without awarding points.
4. **Given** a sale is completed with a linked membership, **When** the payment is processed, **Then** points for each purchased item are added to the customer's account automatically.
5. **Given** the customer's app is open, **When** points are awarded from an in-store purchase, **Then** the updated balance appears in the app within a few seconds without requiring a manual refresh.

---

### User Story 6 - Order-Ready Push Notifications (Priority: P2)

A customer who placed a pre-order receives a push notification the moment their order is marked ready by staff. Tapping the notification takes them directly to their order details.

**Why this priority**: Notifications reduce the burden on customers to check the app repeatedly and improve the pickup experience.

**Independent Test**: When a worker marks an order as ready, the customer's device receives a push notification with the correct order number, and tapping it opens the order details.

**Acceptance Scenarios**:

1. **Given** a worker marks an order as "ready," **When** the status changes, **Then** the customer receives a push notification reading "Your order #[number] is ready for pickup."
2. **Given** the customer taps the notification, **When** the app opens, **Then** it navigates directly to that order's detail screen.
3. **Given** the customer has opted out of notifications in settings, **When** their order is marked ready, **Then** no notification is sent and the customer must check the app manually.

---

### Edge Cases

- What happens when the café's operating hours change mid-day (e.g., early closure)?
- If a customer adds an item to their cart and staff marks it unavailable before checkout completes, what does the customer see?
- What if a push notification fails to deliver (device offline)?
- What if a reward expires and the customer tries to use it?
- How are points handled for a multi-item order where one item has no defined point value?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST display the full café menu, grouped by category, within 2 seconds of app launch.
- **FR-002**: The system MUST support client-side filtering of menu items by name and description without additional network calls.
- **FR-003**: Customers MUST be able to customize order items with size selection and free-text special instructions.
- **FR-004**: The system MUST prevent order placement outside café operating hours, within 15 minutes of closing time, or for any date other than today (same-day pickup only).
- **FR-005**: The system MUST create an order only after payment is confirmed — failed payments MUST NOT create orders.
- **FR-006**: Points MUST be calculated using per-item point values and awarded to the customer's account immediately upon payment confirmation.
- **FR-007**: The system MUST display each item's point value on the item detail screen.
- **FR-008**: The system MUST grant a free-coffee reward automatically when a customer completes their 10th order.
- **FR-009**: Rewards MUST expire 30 days after being claimed.
- **FR-010**: Staff MUST receive new pre-orders in real-time on the worker dashboard without manual refresh.
- **FR-011**: Staff MUST be able to check off individual items within an order as they are prepared.
- **FR-012**: The system MUST automatically mark an order "ready" and send a customer push notification when all items are checked off.
- **FR-013**: Pre-orders that remain uncollected beyond a configurable timeout period MUST be automatically expired.
- **FR-014**: The system MUST automatically generate a unique membership barcode when a customer registers, and customers MUST be able to view and display it within the app at any time.
- **FR-015**: In-store barcode scans MUST return the customer's name and current points balance to the point-of-sale display within 1 second.
- **FR-016**: In-store purchases linked to a membership MUST award points automatically after payment, without staff intervention.
- **FR-017**: Customers MUST be able to opt in or out of push notifications from within app settings.
- **FR-018**: The system MUST distinguish app-only menu items from regular items and show any price difference clearly.
- **FR-019**: Customer authentication MUST support email/password registration and login.
- **FR-020**: Staff authentication MUST be separate from customer authentication, with restricted access to fulfillment functions only.
- **FR-021**: Customers MUST be able to tap "Redeem" on an active reward in-app to mark it as pending redemption; the app MUST reflect the pending status immediately and prevent double-redemption.

### Key Entities

- **MenuItem**: Represents a product the café sells, including name, price (in-store and app-only where different), description, allergens, point value, category, and a binary availability flag (available/unavailable — no stock counts).
- **Order**: Represents a customer's pre-order, including items ordered, total, earned points, status (pending → accepted → in process → ready → completed/expired), requested ready time, and timestamps for each status transition.
- **Customer**: Represents a registered app user with a profile, current points balance, order history, and claimed rewards.
- **LoyaltyAccount**: Tracks a customer's membership barcode (unique, auto-generated at registration), total points, point transaction history, and claimed rewards.
- **Reward**: Represents a loyalty reward (e.g., free coffee) with a type, monetary value, claim date, expiry date, and redemption status (unredeemed → pending redemption → redeemed). The customer taps "Redeem" in-app to transition to pending; staff confirms visually at the counter.
- **Staff**: Represents a worker or owner account with appropriate role-based access to fulfillment and management functions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Customers can browse the full menu and find any item within 30 seconds of opening the app.
- **SC-002**: The end-to-end pre-order flow (select items → pay → receive confirmation) completes in under 3 minutes for a first-time user.
- **SC-003**: Loyalty points appear in the customer's account within 5 seconds of payment confirmation on both pre-orders and in-store purchases.
- **SC-004**: Workers can accept and begin fulfilling a new order within 10 seconds of it appearing in the queue.
- **SC-005**: Customers receive a push notification within 10 seconds of their order being marked ready.
- **SC-006**: In-store membership barcode lookup returns customer details to the register within 1 second.
- **SC-007**: Zero orders are created without confirmed payment across all tested scenarios.
- **SC-008**: Point calculations are correct for 100% of orders across all item combinations tested.
- **SC-009**: Every 10th order triggers a free-coffee reward correctly in all tested scenarios.
- **SC-010**: The app operates without a crash for all tested happy-path and error-path scenarios.

## Assumptions

- The café has a single physical location for the MVP; multi-location support is out of scope.
- When offline, customers can browse the last-cached menu with a visible "You're offline" banner; placing orders requires an active connection. Full offline ordering is out of scope.
- In-store points from barcode scans require a backend service to receive payment webhooks from the point-of-sale system; this integration is planned post-demo (Phase 5) and is not required for the MVP demo.
- Reward redemption is customer-initiated in-app (tap "Redeem" → pending) and confirmed visually by staff at the counter; the app tracks the pending/redeemed status but does not integrate with the POS system for MVP.
- Cancellations after payment are not supported; the spec assumes this is a deliberate business decision by the café owner.
- The café owner updates the menu via an admin console rather than an in-app management screen for MVP.
- App-only items may have a different (higher) price than the in-store price; if no app price is set, the in-store price applies in the app.
- The order timeout for uncollected "ready" orders is configurable by the café owner but defaults to a reasonable period (e.g., 2 hours).
- Staff accounts are pre-provisioned by the café owner; self-registration for staff is out of scope.
- The payment provider charges the customer at order placement; no deferred billing or pay-at-pickup model is in scope.
