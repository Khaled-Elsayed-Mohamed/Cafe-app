# Phase 0 Research: iOS Café App

**Branch**: `001-ios-cafe-app` | **Date**: 2026-05-24 | **Plan**: [plan.md](plan.md)

All technology choices and rationale for the iOS Café App implementation. Each decision resolves a NEEDS CLARIFICATION in the Technical Context or a best-practices question identified during planning.

---

## Decision 1 — Payment SDK: Square In-App Payments

**Decision**: Square In-App Payments SDK for iOS

**Rationale**:
- The café already operates Square POS hardware at the physical point of sale — Square is mandatory, not optional
- Using a different provider (e.g., Square) would require running two parallel payment systems, increasing cost, complexity, and breaking the link between in-store and in-app transaction history
- Square In-App Payments SDK supports card entry natively on iOS and produces a payment nonce that is sent to a server-side endpoint (Firebase callable function) to complete the charge
- Square's sandbox environment supports test card nonces for local development and CI
- Phase 5 (in-store barcode scan + POS integration) will use the same Square seller account and APIs, so consolidating on Square now eliminates an integration seam later

**Alternatives considered**:
- Square iOS SDK: rejected — café already has Square POS hardware; running two payment providers adds unnecessary operational overhead
- Manual card handling without SDK: rejected — increases PCI scope; both Square and Square SDKs handle card tokenization client-side

**Constitution note**: The constitution's success definition contained a stray reference to "Square test mode" — this was an error from initial document assembly. The principles correctly specify Square throughout. No constitution version change was needed (the Square references in the principles were already correct).

---

## Decision 2 — Firebase Firestore Real-time Listeners with async/await

**Decision**: `AsyncStream` wrapping Firestore `addSnapshotListener`, cleaned up via `onTermination`

**Rationale**:
- Firestore's snapshot listener API is callback-based; `AsyncStream` bridges it to Swift Concurrency without introducing Combine
- `continuation.onTermination` removes the Firestore listener when the `AsyncStream` is cancelled (e.g., when a ViewModel is deallocated), preventing memory leaks
- This pattern keeps the Data layer's public interface purely `async`/`AsyncStream` — no `AnyPublisher` or closure types leak through the protocol boundary

**Pattern**:
```swift
func observeActiveOrders(date: String) -> AsyncStream<[Order]> {
    AsyncStream { continuation in
        let listener = db.collection("orders")
            .whereField("date", isEqualTo: date)
            .whereField("status", in: ["pending", "accepted", "in_process"])
            .addSnapshotListener { snapshot, _ in
                let orders = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: FirestoreOrder.self) }
                    .map { $0.toDomain() }
                continuation.yield(orders)
            }
        continuation.onTermination = { _ in listener.remove() }
    }
}
```

**Alternatives considered**:
- Combine `PassthroughSubject`: rejected — constitution forbids Combine
- Polling Firestore on a timer: rejected — violates the <1s real-time requirement (FR-010)

---

## Decision 3 — Push Notifications: FCM + APNs + Cloud Function Trigger

**Decision**: Firebase Cloud Messaging (FCM) dispatches APNs notifications; a Firestore-triggered Cloud Function fires when `order.status` changes to `"ready"`

**Flow**:
1. Customer app registers with APNs on launch → receives FCM token → stored at `customers/{uid}/fcmToken`
2. Worker marks all items checked off → `FulfillOrderUseCase` writes final item check-off to Firestore
3. Cloud Function `onOrderReady` triggers on `orders/{orderId}` update where `status == "ready"` → reads `fcmToken` → sends FCM message
4. FCM delivers APNs push: `"Your order #[number] is ready for pickup"`
5. `userInfo` contains `orderId` → tapping notification navigates to `OrderTrackingView`

**Rationale**:
- Server-side dispatch (Cloud Function) is reliable regardless of whether the worker device is online at completion time
- FCM handles APNs certificate management — simpler than direct APNs integration
- Firestore trigger ensures the notification fires exactly once, even under retries

**Alternatives considered**:
- Worker device sending FCM message directly via HTTP: rejected — requires embedding the FCM server key in the iOS app (security violation)
- Silent polling by customer app: rejected — violates the <10s notification requirement (SC-005)

---

## Decision 4 — Offline Menu Cache: UserDefaults + JSON

**Decision**: `UserDefaults` storing a JSON-encoded `[MenuItem]` array, written on every successful Firestore menu fetch

**Rationale**:
- Menu is read-only and small (~50 items); `UserDefaults` JSON is sufficient without CoreData overhead
- `JSONEncoder/JSONDecoder` on `MenuItem` (a pure Swift `Codable` struct) requires no framework imports in the Data layer
- `NWPathMonitor` detects connectivity changes and emits `AsyncStream<Bool>` — `MenuViewModel` observes this to toggle the offline banner and disable ordering
- Cache is invalidated on next successful fetch (not time-based); staff-side availability changes propagate on reconnect

**Pattern**:
```swift
// FirebaseMenuRepository
func fetchMenu() async throws -> [MenuItem] {
    let items = try await fetchFromFirestore()
    saveCache(items)          // UserDefaults write
    return items
}

func fetchCachedMenu() -> [MenuItem] {
    guard let data = UserDefaults.standard.data(forKey: "menu_cache"),
          let items = try? JSONDecoder().decode([MenuItem].self, from: data)
    else { return [] }
    return items
}
```

**Alternatives considered**:
- CoreData: rejected — overkill for a flat list of ~50 items; adds significant complexity with no benefit at MVP scale
- NSCache: rejected — in-memory only; doesn't survive app restart

---

## Decision 5 — Membership Barcode Display: CIFilter QR Code

**Decision**: `CIFilter.qrCodeGenerator()` (Core Image, no dependencies) encodes `LoyaltyAccount.membershipBarcode` (UUID string) as a QR code displayed in `BarcodeView`

**Rationale**:
- QR codes are more tolerant of phone-screen glare and scan angle than Code128/EAN barcodes — better UX when a customer holds their phone up to a scanner
- Core Image's `CIFilter.qrCodeGenerator` is native iOS — no third-party barcode library needed
- `BarcodeView` renders: `CIFilter` → `CIImage` → `UIImage` (scaled up 10x with `.none` interpolation) → `Image(uiImage:)`
- Barcode itself is a UUID v4 string generated server-side on registration (Cloud Function `onCreateUser`)

**Pattern**:
```swift
func generateQRCode(from string: String) -> UIImage? {
    let data = Data(string.utf8)
    guard let filter = CIFilter(name: "CIQRCodeGenerator"),
          let _ = { filter.setValue(data, forKey: "inputMessage"); return () }(),
          let outputImage = filter.outputImage else { return nil }
    let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
    return UIImage(ciImage: scaled)
}
```

**Alternatives considered**:
- Third-party barcode library (ZXing, BarcodeKit): rejected — adds a dependency for a feature Core Image handles natively
- Code128 linear barcode: rejected — harder to scan from a screen; QR codes are the standard for phone-display scenarios

---

## Decision 6 — iOS Dependency Injection: Manual Constructor Injection

**Decision**: Plain Swift `DependencyContainer` struct in `App/` — composition root that wires concrete Data implementations to Domain protocols; no third-party DI framework

**Rationale**:
- Constitution mandates KISS and no magic — manual constructor injection is transparent, easy to test, and trivially swappable
- Replacing Firebase with a custom API only requires changing the wiring in `DependencyContainer`, with zero changes to Domain or Presentation
- `@EnvironmentObject DependencyContainer` passes the container down the view hierarchy; each View's `init` receives only the protocols it needs

**Pattern**:
```swift
// DependencyContainer.swift
struct DependencyContainer {
    let menuRepository: any MenuRepository
    let orderRepository: any OrderRepository
    let paymentRepository: any PaymentRepository
    // ...

    static func live() -> DependencyContainer {
        DependencyContainer(
            menuRepository: FirebaseMenuRepository(),
            orderRepository: FirebaseOrderRepository(),
            paymentRepository: SquarePaymentRepository(publishableKey: Config.stripePublishableKey),
            // ...
        )
    }

    static func mock() -> DependencyContainer {
        DependencyContainer(
            menuRepository: MockMenuRepository(),
            orderRepository: MockOrderRepository(),
            paymentRepository: MockPaymentRepository(),
            // ...
        )
    }
}
```

**Alternatives considered**:
- Factory (third-party DI): rejected — adds dependency for a problem solvable in ~50 lines of Swift
- Swinject: rejected — same reason; overkill for a single-app MVP

---

## Decision 7 — Order Expiry Automation: Cloud Function (Scheduled)

**Decision**: A Firebase Cloud Function scheduled to run every 15 minutes queries orders in `"ready"` status where `expiresAt < now` and batch-writes their status to `"expired"`

**Rationale**:
- Client-side expiry is unreliable — the app may be closed or the device offline
- Cloud Scheduler triggers guarantee expiry even when no devices are active
- `expiresAt` is set when an order transitions to `"ready"` status: `expiresAt = readyAt + config.orderTimeoutMinutes`
- The default timeout is 120 minutes (2 hours), configurable via `cafe_config/default`

**Alternatives considered**:
- Client app checks and expires on open: rejected — creates race conditions if multiple devices are open
- Firestore TTL: rejected — Firestore TTL deletes documents; we need status = "expired" for audit trail, not deletion

---

## Decision 8 — Point Award Automation: Firestore-triggered Cloud Function

**Decision**: Cloud Function `onOrderStatusUpdate` triggers when `orders/{orderId}.status` changes to `"completed"` → sums `items[].pointValue` → increments `loyalty_accounts/{customerId}.totalPoints` and `orderCount` in a Firestore batch write → if `orderCount % 10 == 0`, creates a new `rewards` document

**Rationale**:
- Server-side calculation prevents client-side manipulation of point values
- Firestore batch write is atomic — either all of `totalPoints`, `orderCount`, and the optional `Reward` creation succeed, or none do
- `"completed"` is the trigger (not `"ready"`) — orders transition to completed when the customer collects. For MVP, the worker marks the order completed after handing it over

**Note on "in-process" vs "completed" trigger**: The spec's loyalty flow awards points "immediately upon payment confirmation" (FR-006). For pre-orders, points are awarded on `"completed"` status (pickup confirmed). For the MVP demo this is acceptable; the clarification session confirmed same-day same-flow. Points appear within 5 seconds (SC-003) due to Firestore real-time listener in `LoyaltyViewModel`.

**Alternatives considered**:
- Client writes points after payment: rejected — manipulable by a motivated user via direct Firestore write
- Cloud Task deferred execution: rejected — adds complexity; Firestore trigger is simpler and sufficient
