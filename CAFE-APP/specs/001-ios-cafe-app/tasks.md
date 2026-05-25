# Tasks: iOS Café App

**Branch**: `001-ios-cafe-app` | **Date**: 2026-05-24 | **Plan**: [plan.md](plan.md) | **Spec**: [spec.md](spec.md)

**Input**: Design documents from `specs/001-ios-cafe-app/` — plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Not explicitly requested in spec — mock repository scaffolding included as a mandatory architectural requirement (constitution-mandated: demo-cycle mocks before any View is written; remaining 3 mocks deferred to Phase 5 preamble).

**Organization**: Demo-first — Phases 1–4 deliver the full selling demo cycle (customer orders → worker fulfills). Phases 5–8 add loyalty, barcode, notifications, and polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US6 from spec.md)
- Paths follow plan.md structure: `CafeApp/` for app source, `functions/` for Cloud Functions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xcode project creation, dependency management, Firebase project wiring, and local development environment.

- [X] T001 Create Xcode project `CafeApp` targeting iOS 17+; add `CafeAppTests` and `CafeAppIntegrationTests` test targets; confirm project opens cleanly
- [X] T002 [P] Add Firebase iOS SDK 11+ via SPM (FirebaseAuth, FirebaseFirestore, FirebaseMessaging) to `CafeApp` target only — do NOT add to test targets
- [X] T003 [P] Create `CafeApp/Podfile` with `pod 'SquareInAppPaymentsSDK'` under `CafeApp` target (iOS 17.0 platform); run `pod install`
- [X] T004 [P] Create full directory structure under `CafeApp/` per plan.md: `App/`, `Features/{Auth,Menu,Orders,Loyalty,Worker,Notifications}/`, `Core/{Security,Network,CafeConfig,Extensions}/`
- [X] T005 Download `GoogleService-Info.plist` from Firebase console (project `cafe-app-dev`) and place at `CafeApp/CafeApp/GoogleService-Info.plist`; add `SQUARE_APPLICATION_ID` User-Defined build setting in Xcode; wire it into `CafeApp/CafeApp/Info.plist` as `<key>SQUARE_APPLICATION_ID</key><string>$(SQUARE_APPLICATION_ID)</string>`
- [X] T006 [P] Add entries to `.gitignore`: `GoogleService-Info.plist`, `Secrets.xcconfig`, `*.xcuserstate`, `Pods/`, `.env`, `functions/.runtimeconfig.json`
- [X] T007 Initialize Firebase Emulator Suite from repo root (`firebase init emulators` — select Auth, Firestore, Functions, Cloud Messaging, accept default ports); create `firebase-seed/` with test customer account, test worker account, sample menu items (all 4 categories), loyalty account at 9 orders, and `cafe_config/default` (07:00–20:00) per quickstart.md
- [X] T008 Initialize Cloud Functions project in `functions/` with Node.js 20+: `npm init`, install `firebase-admin` and `firebase-functions`, add TypeScript config (`tsconfig.json`)

**Checkpoint**: Project opens in Xcode, `pod install` succeeds, SPM resolves Firebase, `firebase emulators:start --import=./firebase-seed` starts cleanly.

---

## Phase 2: Demo Foundation (Blocking Prerequisites)

**Purpose**: Core infrastructure, authentication feature (required by every story), the 5 mock repository implementations needed for the demo cycle, `DependencyContainer`, app entry point, and Firestore rules. The remaining 3 mocks (Loyalty, Notification, CafeConfig) are deferred to Phase 5 preamble.

**⚠️ CRITICAL**: No user story work begins until this phase is complete. Demo-cycle mocks (T020, T021) must exist before any View is written (constitution mandate).

- [X] T009 Create `CafeApp/App/Config.swift` — `static let squareApplicationId: String` reads `SQUARE_APPLICATION_ID` from `Bundle.main.infoDictionary`; fatal error with message if key missing
- [X] T010 [P] Create `CafeApp/Core/Security/KeychainManager.swift` — `save(_ value: String, forKey key: String) throws` and `load(forKey key: String) -> String?` using `kSecClassGenericPassword`; no Firebase or Square imports
- [X] T011 [P] Create `CafeApp/Core/Network/NetworkMonitorRepository.swift` protocol (`observeConnectivity() -> AsyncStream<Bool>`) and `CafeApp/Core/Network/NWNetworkMonitor.swift` implementation using `NWPathMonitor`; wraps monitor callbacks in `AsyncStream` with `onTermination` stopping the monitor
- [X] T012 [P] Create `CafeApp/Core/CafeConfig/CafeConfig.swift` — `struct CafeConfig` with `openTime: String`, `closeTime: String`, `orderCutoffMinutes: Int`, `orderTimeoutMinutes: Int`, `timezone: TimeZone` per data-model.md Swift domain models
- [X] T013 [P] Create `CafeApp/Core/CafeConfig/CafeConfigRepository.swift` protocol (`fetchConfig() async throws -> CafeConfig`, `observeConfig() -> AsyncStream<CafeConfig>`) and `CafeApp/Core/CafeConfig/FirebaseCafeConfigRepository.swift` reading `cafe_config/default` from Firestore; wraps snapshot listener in `AsyncStream`
- [X] T014 [P] Create `CafeApp/Core/Extensions/Date+CafeHours.swift` — `func isWithinOrderingWindow(config: CafeConfig) -> Bool` (open, ≤ cutoff minutes before close, same day) and `func minutesUntilClose(config: CafeConfig) -> Int` using `config.timezone`; no Firebase imports
- [X] T015 [P] Create `CafeApp/Features/Auth/Domain/AuthUser.swift` (`AuthUser` struct, `UserRole` enum with `.customer`, `.worker`, `.owner`) and `CafeApp/Features/Auth/Domain/AuthRepository.swift` protocol (copy from `specs/001-ios-cafe-app/contracts/AuthRepository.swift`)
- [X] T016 Create `CafeApp/Features/Auth/Data/FirebaseAuthRepository.swift` — implements `AuthRepository`; reads `role` custom claim from ID token; stores token via `KeychainManager`; wraps `Auth.auth().addStateDidChangeListener` in `AsyncStream`; maps all Firebase errors to `AuthError` domain types; `import FirebaseAuth` is the only framework import
- [X] T017 Create `CafeApp/Features/Auth/Domain/SignInUseCase.swift` and `CafeApp/Features/Auth/Domain/RegisterUseCase.swift` — thin use-case wrappers calling `AuthRepository`; `import Foundation` only
- [X] T018 Create `CafeApp/Features/Auth/Presentation/AuthViewModel.swift` — `@Observable` class; injects `any AuthRepository`; `signIn(email:password:)`, `signUp(email:password:displayName:)`, `signOut()` as `async` methods; `currentUser: AuthUser?` state; no Firebase imports
- [X] T019 Create `CafeApp/Features/Auth/Presentation/LoginView.swift` and `CafeApp/Features/Auth/Presentation/RegisterView.swift` — email/password `Form` views; bind to `AuthViewModel`; no Firebase imports; error messaging via `AuthError` cases
- [X] T020 [P] Create `CafeAppTests/Mocks/MockAuthRepository.swift` — in-memory implementation of `AuthRepository`; `var stubbedUser: AuthUser?` and `var shouldThrow: AuthError?` for test control
- [X] T021 [P] Create 4 demo-cycle mock files — each is an in-memory implementation of its protocol with configurable stubs: `CafeAppTests/Mocks/MockMenuRepository.swift`, `MockOrderRepository.swift`, `MockPaymentRepository.swift`, `MockWorkerOrderRepository.swift` (MockLoyaltyRepository, MockNotificationRepository, MockCafeConfigRepository are deferred to T021b in Phase 5)
- [X] T022 Create `CafeApp/App/DependencyContainer.swift` — `struct DependencyContainer` with properties typed as protocol existentials (`any MenuRepository`, `any OrderRepository`, etc.); `static func live(useEmulator: Bool = false) -> DependencyContainer` wires concrete Data implementations for the demo cycle (Auth, Menu, Orders, Payment, Worker, CafeConfig); `static func mock() -> DependencyContainer` wires the 5 demo Mock implementations; Loyalty/Notification properties declared but populated in Phase 5; emulator flag connects Firebase Auth + Firestore to localhost ports
- [X] T023 Create `CafeApp/App/CafeAppApp.swift` — `@main`; creates `DependencyContainer.live(useEmulator: ProcessInfo.processInfo.environment["USE_EMULATOR"] == "1")`; observes `authRepository.observeAuthState()` and routes to customer `TabView` or worker `WorkerDashboardView` based on `UserRole`; passes `DependencyContainer` via `@EnvironmentObject`
- [X] T024 [P] Create `firestore.rules` at repo root with security rules per data-model.md summary (public read for menu/config, uid-matched read/write for customers/loyalty, staff read/write for orders, Cloud Functions–only writes for loyalty/transactions/rewards); create `firestore.indexes.json` with all 6 composite indexes from data-model.md
- [ ] T025 Deploy Firestore rules and indexes to local emulator: `firebase deploy --only firestore:rules,firestore:indexes --project demo-cafeapp`

**Checkpoint**: App launches in simulator, login/register screens render, role-based routing switches between customer `TabView` and worker dashboard, emulator security rules enforced.

---

## Phase 3: Demo Customer Loop — Menu Browsing + Pre-Order & Payment (US1 + US2)

**Goal**: Full customer experience in one phase — browse the menu, add items to cart with size and special instructions, select a same-day pickup time, pay via Square In-App Payments, and track the order in real-time. Menu works offline with cached data. Failed payments produce no Firestore order document.

**Independent Test**: Launch as customer → menu loads within 2 seconds → add items to cart → pay with Square sandbox test card → see order confirmation → track real-time status. Repeat with declined card — verify no order appears in Firestore.

### Implementation

- [X] T026 [P] [US1] Create `CafeApp/Features/Menu/Domain/MenuItem.swift` — `MenuItem` struct (Identifiable, Codable), `MenuCategory` enum, and `extension MenuItem { var effectiveAppPrice: Double }` per data-model.md Swift domain models
- [X] T027 [P] [US1] Create `CafeApp/Features/Menu/Domain/MenuRepository.swift` protocol — `fetchMenu() async throws -> [MenuItem]`, `fetchCachedMenu() -> [MenuItem]`, `observeMenuUpdates() -> AsyncStream<[MenuItem]>` (copy from `specs/001-ios-cafe-app/contracts/MenuRepository.swift`)
- [X] T028 [US1] Create `CafeApp/Features/Menu/Domain/FetchMenuUseCase.swift` — calls `MenuRepository.fetchMenu()`; on error falls back to `fetchCachedMenu()`; no Firebase imports
- [X] T029 [US1] Create `CafeApp/Features/Menu/Data/FirebaseMenuRepository.swift` — `fetchMenu()` queries `menu_items` where `isAvailable == true`; on success encodes `[MenuItem]` to JSON and writes to `UserDefaults` key `"menu_cache"`; `fetchCachedMenu()` reads and decodes from `UserDefaults`; `observeMenuUpdates()` wraps `addSnapshotListener` in `AsyncStream` with `onTermination` removing the listener
- [X] T030 [US1] Create `CafeApp/Features/Menu/Presentation/MenuViewModel.swift` — `@Observable`; injects `any MenuRepository` and `any NetworkMonitorRepository`; `items: [MenuItem]`; `isOffline: Bool` driven by connectivity stream; `searchText: String`; computed `filteredItems: [MenuItem]` filtering by name and description client-side (FR-002); loads via `FetchMenuUseCase` on `.task` lifecycle
- [X] T031 [US1] Create `CafeApp/Features/Menu/Presentation/MenuView.swift` — `Picker`-based category filter (Coffee, Food, Drinks, Pastry, All); `List` of `filteredItems`; `searchable` modifier wired to `MenuViewModel.searchText`; `.refreshable` calls `fetchMenu()`; offline banner overlay (FR for US1 offline scenario); "Café Closed" indicator when outside ordering window per `CafeConfig`
- [X] T032 [US1] Create `CafeApp/Features/Menu/Presentation/MenuItemDetailView.swift` — displays name, `effectiveAppPrice`, description, allergens `HStack`, `pointValue` badge, app-only label when `isAppOnly == true` (FR-007, FR-018)
- [X] T033 [US1] Wire `MenuView` as the first tab in the customer `TabView` in `CafeApp/App/CafeAppApp.swift`; inject `menuRepository` and `networkMonitorRepository` from `DependencyContainer`

*Sub-checkpoint after T033: Customer can browse menu, search items, and view item detail — menu half of the demo is working.*

- [X] T034 [P] [US2] Create `CafeApp/Features/Orders/Domain/OrderItem.swift` (menuItemId, name, size?, specialInstructions?, pointValue, price, isCheckedOff) and `CafeApp/Features/Orders/Domain/Order.swift` (Order struct, OrderStatus enum, OrderStatusTimestamps struct) per data-model.md Swift domain models
- [X] T035 [P] [US2] Create `CafeApp/Features/Orders/Domain/OrderRepository.swift` protocol — `createOrder`, `fetchOrder(id:)`, `observeOrder(id:)`, `fetchTodayOrders(customerId:)` (copy from `specs/001-ios-cafe-app/contracts/OrderRepository.swift`)
- [X] T036 [P] [US2] Create `CafeApp/Features/Orders/Domain/PaymentRepository.swift` protocol with `collectPayment(amount: Double, currency: String) async throws -> PaymentResult`; define `PaymentResult`, `PaymentStatus`, and `PaymentError` domain types in this file (copy from `specs/001-ios-cafe-app/contracts/PaymentRepository.swift`); no Square SDK types
- [X] T037 [US2] Create `CafeApp/Features/Orders/Domain/PlaceOrderUseCase.swift` — (1) validate `requestedReadyTime` is within ordering window via `Date+CafeHours`; (2) call `PaymentRepository.collectPayment`; (3) only on `.succeeded` status call `OrderRepository.createOrder`; on payment failure throw `OrderError.paymentFailed` without creating an order (FR-005); `import Foundation` only
- [X] T038 [US2] Create `CafeApp/Features/Orders/Data/SquareInAppPaymentRepository.swift` — the **only** file with `import SquareInAppPaymentsSDK`; presents Square card entry UI; on nonce received calls Firebase callable function `chargeCard` with `{nonce, amount, currency}`; maps Square SDK errors to `PaymentError` domain types; returns `PaymentResult` with Square transaction ID as `paymentReference`
- [X] T039 [US2] Create `CafeApp/Features/Orders/Data/FirebaseOrderRepository.swift` — `createOrder` writes to `orders` collection with all fields per data-model.md including `date: "YYYY-MM-DD"` denormalized field; `observeOrder(id:)` wraps snapshot listener in `AsyncStream`; `fetchTodayOrders` queries by `customerId ASC, createdAt DESC`
- [X] T040 [US2] Create Cloud Function `chargeCard` (callable) in `functions/src/chargeCard.ts` — receives `{nonce, amount, currency}`; calls Square Charges API using `functions.config().square.access_token` (server-side only); returns `{paymentReference}` on success; throws `HttpsError` with mapped reason on failure; Square access token never touches the iOS app
- [X] T041 [US2] Create `CafeApp/Features/Orders/Presentation/OrderViewModel.swift` — `@Observable`; injects `PlaceOrderUseCase`, `any OrderRepository`, `any CafeConfigRepository`; `cart: [OrderItem]`; `addToCart(_:)`, `removeFromCart(at:)`, `placeOrder(requestedTime:) async`; `activeOrder: Order?` observed via `observeOrder` AsyncStream; exposes `isOrderingAllowed: Bool` computed from `CafeConfig`
- [X] T042 [US2] Create `CafeApp/Features/Orders/Presentation/CartView.swift` — list of cart items; size `Picker` (Small/Medium/Large) and `TextField` for special instructions per item; total amount footer; "Checkout" button (disabled when `isOffline` or `!isOrderingAllowed`)
- [X] T043 [US2] Create `CafeApp/Features/Orders/Presentation/CheckoutView.swift` — `DatePicker` restricted to today, café operating hours, and >15 minutes before close; order summary; "Pay" button triggers `OrderViewModel.placeOrder` which invokes Square card entry sheet; error alert on payment failure (FR-005)
- [X] T044 [US2] Create `CafeApp/Features/Orders/Presentation/OrderConfirmationView.swift` — order number, item list, `totalPointsEarned` badge, `requestedReadyTime`; "Track Order" navigation link to `OrderTrackingView`
- [X] T045 [US2] Create `CafeApp/Features/Orders/Presentation/OrderTrackingView.swift` — real-time order status progress indicator driven by `OrderViewModel.activeOrder` AsyncStream; shows `requestedReadyTime` countdown; displays expiry warning in "ready" state; handles "expired" state gracefully

**Checkpoint**: Customer can browse menu → add items → pay with Square sandbox → see confirmation → track order in real-time. Declined card produces no Firestore document (SC-007).

---

## Phase 4: Demo Worker Loop — Pre-Order Fulfillment (US3)

**Goal**: Authenticated worker sees incoming orders appear in real-time (within 1 second), accepts them, checks off each item as prepared, and marks completed on pickup. A scheduled Cloud Function auto-expires uncollected "ready" orders after the configurable timeout.

**Independent Test**: Log in as worker → new pre-order appears in queue within 1 second → accept → check off all items → status transitions to "ready" → mark collected → verify "completed" in Firestore.

### Implementation

- [X] T046 [P] [US3] Create `CafeApp/Features/Worker/Domain/WorkerOrderRepository.swift` protocol — `observeActiveOrders(date:)`, `acceptOrder(id:)`, `checkOffItem(orderId:itemIndex:)`, `markOrderReady(id:)`, `markOrderCompleted(id:)` (copy from `specs/001-ios-cafe-app/contracts/WorkerOrderRepository.swift`)
- [X] T047 [US3] Create `CafeApp/Features/Worker/Domain/FulfillOrderUseCase.swift` — `acceptOrder`: validates status is `pending`; `checkOffItem`: writes check-off and calls `markOrderReady` automatically when all items checked (FR-012); `markOrderCompleted`: validates status is `ready`; enforces order status state machine; no Firebase imports
- [X] T048 [US3] Create `CafeApp/Features/Worker/Data/FirebaseWorkerOrderRepository.swift` — `observeActiveOrders(date:)` queries `orders` where `date == today` and `status in [pending, accepted, in_process]`, wrapped in `AsyncStream` with `onTermination`; `acceptOrder` writes `status = "accepted"`; `checkOffItem` writes `items[index].isCheckedOff = true`; `markOrderReady` writes `status = "ready"`, `expiresAt = Date() + config.orderTimeoutMinutes * 60`, and `statusTimestamps.ready`; `markOrderCompleted` writes `status = "completed"` and `statusTimestamps.completed`
- [X] T049 [US3] Create Cloud Function `onOrderExpiry` (scheduled, every 15 minutes via `pubsub.schedule`) in `functions/src/onOrderExpiry.ts` — queries `orders` where `status == "ready"` and `expiresAt < now`; batch-writes `status = "expired"` and `statusTimestamps.expired` for all matching documents (FR-013)
- [X] T050 [US3] Create `CafeApp/Features/Worker/Presentation/WorkerOrderViewModel.swift` — `@Observable`; injects `FulfillOrderUseCase` and `any WorkerOrderRepository`; `activeOrders: [Order]` populated from `observeActiveOrders` AsyncStream (real-time); `accept(orderId:)`, `checkOff(orderId:itemIndex:)`, `markCompleted(orderId:)` async action methods
- [X] T051 [US3] Create `CafeApp/Features/Worker/Presentation/WorkerDashboardView.swift` — scrollable list of active orders sorted by `requestedReadyTime`; each row shows order number, customer name, item count, and a countdown to the requested ready time; real-time via `WorkerOrderViewModel`; no manual refresh needed (FR-010)
- [X] T052 [US3] Create `CafeApp/Features/Worker/Presentation/WorkerOrderDetailView.swift` — full order detail: customer name, each `OrderItem` with name, size, special instructions, and a `Toggle` for `isCheckedOff`; "Accept Order" button (visible in `pending` state); "Mark Collected" button (visible in `ready` state); status badge (FR-011)
- [X] T053 [US3] Wire `WorkerDashboardView` as the root view for `UserRole.worker` routing in `CafeApp/App/CafeAppApp.swift`; inject `workerOrderRepository` and `cafeConfigRepository` from `DependencyContainer`
- [ ] T054 [US3] Deploy `onOrderExpiry` Cloud Function to Firebase Emulator (`firebase deploy --only functions:onOrderExpiry`); seed an order into "ready" state with `expiresAt` in the past; verify emulator transitions it to "expired"

**Checkpoint**: Worker sees live order queue (≤1s update), full accept→check-off→ready→completed flow works, orders auto-expire after timeout via Cloud Function.

---

## → DEMO READY 🎯

**Full selling demo cycle complete.**

**Customer flow**: browse menu → add items → pay (Square sandbox) → see order confirmation → track order in real-time
**Worker flow**: new order appears instantly (≤1s) → accept → check off each item → mark collected → customer tracking screen updates simultaneously

Both roles running simultaneously against Firebase Emulator. The complete revenue loop is demonstrable to any stakeholder.

Phases 5–8 add loyalty points, barcode scan, push notifications, and polish — valuable additions but not required for the core pitch.

---

## Phase 5: Loyalty Points & Membership (US4)

**Goal**: Points are automatically calculated and awarded on order completion (Cloud Function). Every 10th order triggers a free-coffee reward (30-day expiry). Customer views points balance, transaction history, active rewards, and can tap "Redeem" to mark a reward as pending. Membership QR code is generated at registration and displayed from `BarcodeView`.

**Independent Test**: Complete a payment → points appear in customer profile within 5 seconds → complete 10th order → free-coffee reward document appears → tap "Redeem" → status updates to "pending_redemption" immediately.

### Implementation

- [X] T021b [P] Create the 3 mock files deferred from Phase 2: `CafeAppTests/Mocks/MockLoyaltyRepository.swift`, `MockNotificationRepository.swift`, `MockCafeConfigRepository.swift`; wire all three into `DependencyContainer.live()` and `DependencyContainer.mock()`
- [X] T055 [P] [US4] Create `CafeApp/Features/Loyalty/Domain/LoyaltyAccount.swift` (LoyaltyAccount struct) and `CafeApp/Features/Loyalty/Domain/Reward.swift` (Reward struct, RewardType enum, RedemptionStatus enum, `isActive` extension) per data-model.md Swift domain models
- [X] T056 [P] [US4] Create `CafeApp/Features/Loyalty/Domain/LoyaltyRepository.swift` protocol — `fetchAccount`, `observeAccount`, `fetchRewards`, `redeemReward`, `fetchPointTransactions`; include `PointTransaction` struct and `PointSource` enum in this file (copy from `specs/001-ios-cafe-app/contracts/LoyaltyRepository.swift`)
- [X] T057 [US4] Create `CafeApp/Features/Loyalty/Domain/FetchLoyaltyUseCase.swift` (fetches account + rewards together) and `CafeApp/Features/Loyalty/Domain/RedeemRewardUseCase.swift` (validates `reward.isActive` before calling `redeemReward`; throws `LoyaltyError.rewardNotActive` if not); no Firebase imports
- [X] T058 [US4] Create `CafeApp/Features/Loyalty/Data/FirebaseLoyaltyRepository.swift` — `observeAccount` wraps snapshot listener on `loyalty_accounts/{uid}` in `AsyncStream`; `fetchRewards` queries `rewards` by `customerId ASC, expiryDate DESC`; `redeemReward` writes `redemptionStatus = "pending_redemption"` and `redeemedAt = Timestamp(date: Date())` to `rewards/{rewardId}` (FR-021); `fetchPointTransactions` queries `point_transactions` by `customerId ASC, createdAt DESC`
- [X] T059 [US4] Create Cloud Function `onCreateUser` (Auth user creation trigger) in `functions/src/onCreateUser.ts` — generates UUID v4 as `membershipBarcode`; writes `loyalty_accounts/{uid}` with `customerId`, `membershipBarcode`, `totalPoints: 0`, `orderCount: 0`, `updatedAt` (FR-014)
- [X] T060 [US4] Create Cloud Function `onOrderStatusUpdate` (Firestore `orders/{orderId}` update trigger) in `functions/src/onOrderStatusUpdate.ts` — fires when `status` transitions to `"completed"`; sums `items[].pointValue` for `totalPointsEarned`; batch-writes: increments `loyalty_accounts/{customerId}.totalPoints` and `orderCount`; creates `point_transactions` document with `itemBreakdown`; if `orderCount % 10 == 0` creates `rewards` document (`type: "free_coffee"`, `expiryDate = claimDate + 30 days`) (FR-006, FR-008, FR-009)
- [X] T061 [US4] Create `CafeApp/Features/Loyalty/Presentation/LoyaltyViewModel.swift` — `@Observable`; injects `any LoyaltyRepository`; `account: LoyaltyAccount?` from `observeAccount` AsyncStream (real-time, SC-003); `rewards: [Reward]`; `transactions: [PointTransaction]`; `redeemReward(id: String) async` calls `RedeemRewardUseCase`
- [X] T062 [US4] Create `CafeApp/Features/Loyalty/Presentation/ProfileView.swift` — current `totalPoints` display; scrollable `point_transactions` history showing item breakdown per transaction; navigation links to `RewardsView` and `BarcodeView`
- [X] T063 [US4] Create `CafeApp/Features/Loyalty/Presentation/RewardsView.swift` — list of all rewards; each row shows type, `monetaryValue`, expiry countdown, and `redemptionStatus` badge; "Redeem" `Button` for `isActive` rewards (FR-021); button disabled and greyed when `redemptionStatus == .pendingRedemption` or `.redeemed` to prevent double-redemption
- [X] T064 [US4] Create `CafeApp/Features/Loyalty/Presentation/BarcodeView.swift` — `CIFilter(name: "CIQRCodeGenerator")` encodes `LoyaltyAccount.membershipBarcode` (UUID string); scales output `CIImage` by `CGAffineTransform(scaleX: 10, y: 10)`; renders as `Image(uiImage: UIImage(ciImage: scaled))`; no third-party barcode library (research.md Decision 5)
- [X] T065 [US4] Wire `ProfileView` as a tab in the customer `TabView` in `CafeApp/App/CafeAppApp.swift`; inject `loyaltyRepository` from `DependencyContainer`; deploy `onCreateUser` and `onOrderStatusUpdate` Cloud Functions to emulator; register a test user and verify `loyalty_accounts` document is created with a UUID barcode

**Checkpoint**: Points appear within 5 seconds of payment confirmation (SC-003); 10th order produces a `rewards` document; "Redeem" tap updates status to `pending_redemption` immediately; QR barcode displays and scans correctly.

---

## Phase 6: In-Store Barcode Scan & Points (US5)

**Goal**: Staff scans a customer's membership QR code and gets their name + points balance within 1 second. After an in-store sale, points are awarded automatically. (Full POS hardware integration is post-demo; Phase 6 delivers the lookup Cloud Function and the worker-side scan UI. The customer-facing barcode display is already complete in Phase 5.)

**Independent Test**: Call `lookupMember` with a valid membership UUID → `{displayName, totalPoints}` returned in < 1 second. Call with invalid UUID → `NOT_FOUND` error. Award in-store points → customer app balance updates within 5 seconds.

### Implementation

- [X] T066 [US5] Create Cloud Function `lookupMember` (callable) in `functions/src/lookupMember.ts` — receives `{barcode: string}`; queries `loyalty_accounts` using the `membershipBarcode ASC` index; returns `{displayName, totalPoints}` (SC-006); returns `HttpsError('not-found', 'Member not found')` for unknown barcode; validates caller has `role == "worker"` or `"owner"` custom claim
- [X] T067 [US5] Create Cloud Function `awardInStorePoints` (callable) in `functions/src/awardInStorePoints.ts` — receives `{barcode, items: [{menuItemId, itemName, pointsEarned}]}`; looks up loyalty account by `membershipBarcode`; batch-increments `totalPoints` and `orderCount`; writes `point_transactions` document with `source: "in_store"`; if `orderCount % 10 == 0` creates a `rewards` document (same logic as `onOrderStatusUpdate`)
- [X] T068 [US5] Add member lookup to `CafeApp/Features/Worker/Presentation/WorkerDashboardView.swift` — "Scan Member" button opens `DataScannerViewController` (iOS 16+ built-in); on QR code scan calls `lookupMember` Cloud Function; displays customer name and points in a `.sheet`; "Award Points" action in the sheet calls `awardInStorePoints` with manually entered item list (full POS integration is post-demo)
- [ ] T069 [US5] Deploy `lookupMember` and `awardInStorePoints` to emulator; verify barcode lookup returns within 1 second; verify invalid barcode returns `NOT_FOUND`; verify customer app balance updates after `awardInStorePoints` call (SC-006)

**Checkpoint**: Staff can scan QR → name and points appear in ≤ 1 second; in-store points appear in customer app within 5 seconds; invalid barcode shows clear error.

---

## Phase 7: Order-Ready Push Notifications (US6)

**Goal**: Customers receive a push notification within 10 seconds of their order being marked ready by staff. Tapping the notification deep-links to the correct order detail screen. Customers can opt in/out of notifications from within the app.

**Independent Test**: Worker marks order ready in worker UI → customer test device receives push notification with correct order number within 10 seconds → tapping notification opens `OrderTrackingView` for that order.

### Implementation

- [X] T070 [P] [US6] Create `CafeApp/Features/Notifications/Domain/NotificationRepository.swift` protocol — `requestPermission() async throws -> Bool`, `registerDeviceToken(_ token: Data, forUserId: String) async throws`, `isPermissionGranted() async -> Bool` (copy from `specs/001-ios-cafe-app/contracts/NotificationRepository.swift`); and `CafeApp/Features/Notifications/Domain/RegisterNotificationUseCase.swift` orchestrating permission request + token registration
- [X] T071 [US6] Create `CafeApp/Features/Notifications/Data/FCMNotificationRepository.swift` — requests APNs permission via `UNUserNotificationCenter.current().requestAuthorization`; receives FCM token via `Messaging.messaging().token()`; writes token to `customers/{uid}/fcmToken` in Firestore; `isPermissionGranted()` checks `UNAuthorizationStatus`; `import FirebaseMessaging` is the only framework import
- [X] T072 [US6] Create Cloud Function `onOrderReady` (Firestore `orders/{orderId}` update trigger) in `functions/src/onOrderReady.ts` — fires when `status` transitions to `"ready"`; reads `customers/{customerId}/fcmToken`; sends FCM message with `notification.title = "Order Ready"`, `notification.body = "Your order #[orderId] is ready for pickup"`, and `data.orderId`; skips silently if `fcmToken` is null (customer opted out — FR-017)
- [X] T073 [US6] Register notification delegate in `CafeApp/App/CafeAppApp.swift` — call `RegisterNotificationUseCase` on app launch for `UserRole.customer`; implement `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)` to extract `orderId` from `userInfo["orderId"]` and navigate to `OrderTrackingView`
- [X] T074 [US6] Add notification permission toggle to customer settings (a settings section within `ProfileView` or a dedicated settings sheet) — shows current permission state from `NotificationRepository.isPermissionGranted()`; "Enable Notifications" button calls `requestPermission()` (FR-017); explains why notifications improve the experience (pick-up alert)
- [ ] T075 [US6] Deploy `onOrderReady` Cloud Function to emulator; test end-to-end via FCM emulator: worker marks order ready in `WorkerOrderDetailView` → verify FCM message appears in emulator → verify deep link payload contains `orderId`

**Checkpoint**: Push notification delivered within 10 seconds of order marked ready (SC-005); tapping notification opens correct `OrderTrackingView`; opt-out user does not receive notification.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Security audit, secrets verification, observability hardening, integration test scaffolding, and architecture validation.

- [X] T076 [P] Run secrets checklist from `quickstart.md`: confirm `GoogleService-Info.plist` is in `.gitignore`, `SQUARE_APPLICATION_ID` appears only in Build Settings and `Info.plist`, Square access token is only in Firebase Functions config, no PII in `firebase-seed/` data, `Secrets.xcconfig` is git-ignored
- [X] T077 [P] Audit all `Logger` / `OSLog` usages across `CafeApp/` — replace any log statement that includes `email`, `displayName`, `fcmToken`, or `paymentReference` with `.private` privacy level (e.g., `Logger().debug("User: \(email, privacy: .private)")`) per constitution
- [ ] T078 Run manual performance checks against emulator: menu load ≤ 2 seconds from cold launch (SC-001), worker queue update ≤ 1 second on new order (FR-010), notification delivery ≤ 10 seconds (SC-005); document any misses as issues
- [X] T079 [P] Scaffold integration test files per plan.md structure: `CafeAppIntegrationTests/Firebase/FirebaseMenuRepositoryTests.swift`, `FirebaseOrderRepositoryTests.swift`, `FirebaseLoyaltyRepositoryTests.swift` — each connects to Firebase Emulator in `setUpWithError()` and tests one round-trip (fetch, create, observe); ensure `CafeAppIntegrationTests` target does NOT include `FirebaseAuth` or `SquareInAppPaymentsSDK` mock frameworks
- [X] T080 Architecture gate: run `grep -rn "import FirebaseFirestore\|import FirebaseAuth\|import FirebaseMessaging\|import SquareInAppPaymentsSDK" CafeApp/Features/` and confirm all matches are in `*/Data/*.swift` files only — zero matches in `*/Domain/` or `*/Presentation/` (constitution mandate)

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends On | Notes |
|-------|-----------|-------|
| Phase 1 (Setup) | None | Start immediately |
| Phase 2 (Demo Foundation) | Phase 1 | **BLOCKS all user stories** |
| Phase 3 (Demo Customer Loop) | Phase 2 | US1+US2 merged — full customer experience |
| Phase 4 (Demo Worker Loop) | Phase 2 + Phase 3 | Workers process orders placed in Phase 3 |
| **→ DEMO READY** | Phases 1–4 | **Full selling demo cycle** |
| Phase 5 (Loyalty) | Phase 2 + Phase 3 | Points awarded on order completion |
| Phase 6 (Barcode Scan) | Phase 5 | Requires BarcodeView from Phase 5 |
| Phase 7 (Notifications) | Phase 4 | `onOrderReady` triggered by worker action from Phase 4 |
| Phase 8 (Polish) | All desired phases | Final pass |

### Within Each Phase

- Domain models → protocols → use cases → data implementations → view models → views
- Cloud Functions can be developed in parallel with iOS implementation (entirely different files)
- Models marked `[P]` within a phase can start simultaneously

### Parallel Opportunities

**Phase 2**: T010, T011, T012, T013, T014, T015, T020, T021, T024 can all run in parallel
**Phase 3**: T026 and T027 (different domain model files) can run in parallel; T034, T035, T036 (different domain files) can run in parallel; T040 (Cloud Function) can run in parallel with T038, T039
**Phase 4**: T046 and T049 (protocol vs Cloud Function) can run in parallel
**Phase 5**: T021b, T055, T056 can all run in parallel; T059, T060 (Cloud Functions) can run in parallel with T058 (iOS Data layer)
**Phase 6**: T066 and T067 (different Cloud Functions) can run in parallel
**Phase 7**: T070 and T072 (protocol vs Cloud Function) can run in parallel
**Phase 8**: T076, T077, T079 can all run in parallel

---

## Parallel Example: Phase 2 Demo Foundation

```text
# All of these can start simultaneously (all different files):
T010: CafeApp/Core/Security/KeychainManager.swift
T011: CafeApp/Core/Network/NetworkMonitorRepository.swift + NWNetworkMonitor.swift
T012: CafeApp/Core/CafeConfig/CafeConfig.swift
T013: CafeApp/Core/CafeConfig/CafeConfigRepository.swift + FirebaseCafeConfigRepository.swift
T014: CafeApp/Core/Extensions/Date+CafeHours.swift
T015: CafeApp/Features/Auth/Domain/AuthUser.swift + AuthRepository.swift
T020: CafeAppTests/Mocks/MockAuthRepository.swift
T021: CafeAppTests/Mocks/Mock{Menu,Order,Payment,Worker}Repository.swift  ← 4 demo mocks only
T024: firestore.rules + firestore.indexes.json

# Then sequentially:
T016 (depends on T015): FirebaseAuthRepository.swift
T017 (depends on T015): SignInUseCase.swift + RegisterUseCase.swift
T022 (depends on T013, T016, T021): DependencyContainer.swift
T023 (depends on T022): CafeAppApp.swift
```

---

## Implementation Strategy

### Demo-First Cycle (Core Revenue Loop)

1. Phase 1: Setup
2. Phase 2: Demo Foundation (slim — 5 demo mocks only)
3. Phase 3: Demo Customer Loop (menu + Square payment end-to-end)
4. Phase 4: Demo Worker Loop (fulfillment closes the cycle)
→ **DEMO READY**: Full customer→worker cycle running on Firebase Emulator

### Full Feature Set (After Demo Cycle)

5. Phase 5: Loyalty & Membership (points, rewards, QR barcode) + deferred mocks
6. Phase 6: Barcode Scan (in-store lookup)
7. Phase 7: Push Notifications (order-ready alert)
8. Phase 8: Polish

### Parallel Team Strategy (2 Developers)

After Phase 2 completes:
- **Dev A**: Phase 3 (Demo Customer Loop) → Phase 4 (Demo Worker Loop) → demo running
- **Dev B**: Phase 5 Loyalty Cloud Functions (T059, T060) can start as soon as Phase 3 Order domain models exist → then full Phase 5 iOS implementation

After demo cycle complete (Phases 1–4):
- **Dev A**: Phase 7 (US6 Notifications)
- **Dev B**: Phase 6 (US5 Barcode Scan)

---

## Notes

- `[P]` tasks are safe to run in parallel — they touch different files with no shared state
- `[Story]` label provides full traceability back to acceptance scenarios in spec.md
- No Firebase or Square SDK types in Domain or Presentation layers — enforced at T080
- Demo-cycle mocks (T020, T021) created in Phase 2 before any View exists; remaining mocks (T021b) added in Phase 5 preamble before any Loyalty View is written (constitution mandate)
- Square access token: `firebase functions:config:set square.access_token="EAAAl..."` — never in iOS source (quickstart.md)
- Cloud Functions in each phase can be deployed independently to the emulator as they are completed
- `[P]` on `T046` (WorkerOrderRepository protocol) means the protocol can be written in parallel with `T049` (onOrderExpiry Cloud Function) — completely different codebases
