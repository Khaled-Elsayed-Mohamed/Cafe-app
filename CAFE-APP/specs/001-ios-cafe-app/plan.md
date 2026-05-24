# Implementation Plan: iOS Café App

**Branch**: `001-ios-cafe-app` | **Date**: 2026-05-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-ios-cafe-app/spec.md`

## Summary

A dual-role SwiftUI iOS app that lets customers browse a cached menu, place same-day pre-orders with in-app payment, and earn loyalty points — while café staff receive a real-time order queue and manage fulfillment. Firebase (Auth + Firestore + Cloud Messaging + Cloud Functions) is the backend for MVP. Payment is processed via Square In-App Payments SDK — the café already runs Square POS hardware, so Square is mandatory for consistency across in-app and in-store payments. Architecture follows the constitution's strict protocol-based MVVM + Repository pattern with vertical feature slices (Presentation → Domain → Data), zero Firebase or Square imports outside the Data layer, and 100% testable domain logic via constructor-injected mock repositories. See [research.md](research.md) for all technology decisions and [data-model.md](data-model.md) for the full Firestore schema and Swift domain models.

## Technical Context

**Language/Version**: Swift 5.10, Xcode 16+

**Primary Dependencies**: Firebase iOS SDK 11+ (Auth, Firestore, Cloud Messaging), Square In-App Payments SDK (iOS), SwiftUI (iOS 17+), Network framework (NWPathMonitor for offline detection)

**Storage**: Firebase Firestore (primary, real-time); UserDefaults + JSONEncoder (offline menu snapshot cache); iOS Keychain (auth tokens, device secrets)

**Testing**: XCTest + Swift Testing (iOS 17+), Firebase Emulator Suite (Auth + Firestore + Functions + Cloud Messaging)

**Target Platform**: iOS 17+, iPhone (portrait-primary), single app dual-role (customer + worker determined by Firebase Auth custom claim `role`)

**Project Type**: Mobile app (iOS)

**Performance Goals**:
- Menu load within 2 seconds of app launch (FR-001, SC-001)
- Real-time order queue update within 1 second of new order (FR-010)
- Barcode lookup returns customer details within 1 second (SC-006)
- Push notification delivered within 10 seconds of order being marked ready (SC-005)
- Loyalty points visible in account within 5 seconds of payment confirmation (SC-003)

**Constraints**:
- Offline menu browsing required — last-cached menu shown with "You're offline" banner; ordering blocked without connectivity (FR for US1 offline scenario)
- Payment must complete before order is created — Square PaymentIntent confirmed before Firestore order document written (FR-005)
- Same-day orders only, within operating hours, and >15 minutes before closing (FR-004)
- No Firebase or Square SDK imports in Domain or Presentation layers — all data access via protocols
- All configuration (Firebase API key, Square publishable key) injected via `Config` struct reading from `Info.plist` — never hardcoded

**Scale/Scope**: Single café MVP, ~25 screens (customer + worker), 7 Firestore collections, 3 Cloud Functions (award points, send push notification, expire stale orders), estimated dozens to low-hundreds of concurrent users

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Phase 0 Gate

**Architecture Integrity**:
- [x] Firebase SDK imports confined to Data layer only — Domain and Presentation import `Foundation` only
- [x] Square SDK imports confined to Data layer only — `SquareInAppPaymentRepository` is the sole Square-aware type
- [x] All Data-layer types implement protocols defined in the Domain layer (e.g., `FirebaseMenuRepository: MenuRepository`)
- [x] ViewModels accept only protocol types via constructor injection — no concrete Firebase or Square classes
- [x] Domain models are pure Swift structs/enums with no framework dependencies except Foundation
- [x] Firebase/Square errors are mapped to domain error types at the Data layer boundary — never reach Presentation

**Code Quality Standards**:
- [x] async/await used throughout — no Combine publishers, no completion callbacks
- [x] DI via constructor through `DependencyContainer` (composition root) — no singletons, no `@EnvironmentObject` with mutable shared state
- [x] No force unwraps in production code — guard, throw, or optional chaining
- [x] All SDK keys loaded from `Info.plist` via `Config` struct — never hardcoded in source
- [x] Keychain stores auth tokens; `UserDefaults` is used only for the offline JSON menu cache

**Testing-First Mindset**:
- [x] Mock implementations of all repository protocols defined before any View is written
- [x] Integration tests target Firebase Emulator Suite — no live Firebase in any test
- [x] Unit test target (`CafeAppTests`) mirrors the `Features/` folder structure

**Security**:
- [x] No API keys in Swift source — loaded via Build Settings → `Info.plist` → `Config`
- [x] `.env` and `Secrets.xcconfig` in `.gitignore`
- [x] Sensitive user data never logged — `OSLog` with `.private` privacy level for PII

**Gate result**: PASS — no violations. Proceed to Phase 0.

### Post-Phase 1 Re-check

*(Completed after contracts are defined — verify no framework types leak through protocol boundaries)*

- [x] All contracts in `specs/001-ios-cafe-app/contracts/` expose only domain types — no `QuerySnapshot`, no `Square*`, no `FIR*` types appear
- [x] `DependencyContainer` is the only site in the app that references concrete Data implementations
- [x] `PaymentRepository` contract uses domain types (`PaymentIntent`, `PaymentResult`) — not Square SDK types
- [x] `AsyncStream` is the only concurrency bridge used (no Combine `Publisher` or callback closures in any protocol)

**Gate result**: PASS — no violations detected post-design.

## Project Structure

### Documentation (this feature)

```text
specs/001-ios-cafe-app/
├── plan.md              # This file
├── research.md          # Phase 0: all technology decisions with rationale
├── data-model.md        # Phase 1: Firestore schema + Swift domain models + state machines
├── quickstart.md        # Phase 1: developer environment setup and onboarding
├── contracts/           # Phase 1: Swift protocol definitions (architectural boundaries)
│   ├── AuthRepository.swift
│   ├── MenuRepository.swift
│   ├── OrderRepository.swift
│   ├── PaymentRepository.swift
│   ├── LoyaltyRepository.swift
│   ├── WorkerOrderRepository.swift
│   ├── NotificationRepository.swift
│   └── CafeConfigRepository.swift
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
CafeApp/
├── App/
│   ├── CafeAppApp.swift               # @main entry; creates DependencyContainer; sets root view by role
│   ├── DependencyContainer.swift      # Composition root — wires concrete Data impls to Domain protocols
│   └── Config.swift                   # Reads Info.plist; exposes Firebase + Square keys as static lets
│
├── Features/
│   ├── Auth/
│   │   ├── Presentation/
│   │   │   ├── LoginView.swift
│   │   │   ├── RegisterView.swift
│   │   │   └── AuthViewModel.swift
│   │   ├── Domain/
│   │   │   ├── AuthRepository.swift   # Protocol
│   │   │   ├── SignInUseCase.swift
│   │   │   ├── RegisterUseCase.swift
│   │   │   └── AuthUser.swift         # Domain model
│   │   └── Data/
│   │       └── FirebaseAuthRepository.swift
│   │
│   ├── Menu/
│   │   ├── Presentation/
│   │   │   ├── MenuView.swift
│   │   │   ├── MenuItemDetailView.swift
│   │   │   └── MenuViewModel.swift
│   │   ├── Domain/
│   │   │   ├── MenuRepository.swift   # Protocol
│   │   │   ├── FetchMenuUseCase.swift
│   │   │   └── MenuItem.swift         # Domain model
│   │   └── Data/
│   │       └── FirebaseMenuRepository.swift
│   │
│   ├── Orders/
│   │   ├── Presentation/
│   │   │   ├── CartView.swift
│   │   │   ├── CheckoutView.swift
│   │   │   ├── OrderConfirmationView.swift
│   │   │   ├── OrderTrackingView.swift
│   │   │   └── OrderViewModel.swift
│   │   ├── Domain/
│   │   │   ├── OrderRepository.swift     # Protocol
│   │   │   ├── PaymentRepository.swift   # Protocol
│   │   │   ├── PlaceOrderUseCase.swift   # Validates hours, processes payment, creates order
│   │   │   ├── Order.swift               # Domain model
│   │   │   └── OrderItem.swift           # Domain model (includes isCheckedOff for fulfillment)
│   │   └── Data/
│   │       ├── FirebaseOrderRepository.swift
│   │       └── SquareInAppPaymentRepository.swift
│   │
│   ├── Loyalty/
│   │   ├── Presentation/
│   │   │   ├── ProfileView.swift
│   │   │   ├── RewardsView.swift
│   │   │   ├── BarcodeView.swift          # QR code from CIFilter — no third-party dep
│   │   │   └── LoyaltyViewModel.swift
│   │   ├── Domain/
│   │   │   ├── LoyaltyRepository.swift    # Protocol
│   │   │   ├── FetchLoyaltyUseCase.swift
│   │   │   ├── RedeemRewardUseCase.swift
│   │   │   ├── LoyaltyAccount.swift       # Domain model
│   │   │   └── Reward.swift               # Domain model
│   │   └── Data/
│   │       └── FirebaseLoyaltyRepository.swift
│   │
│   ├── Worker/
│   │   ├── Presentation/
│   │   │   ├── WorkerDashboardView.swift
│   │   │   ├── WorkerOrderDetailView.swift
│   │   │   └── WorkerOrderViewModel.swift
│   │   ├── Domain/
│   │   │   ├── WorkerOrderRepository.swift  # Protocol
│   │   │   └── FulfillOrderUseCase.swift
│   │   └── Data/
│   │       └── FirebaseWorkerOrderRepository.swift
│   │
│   └── Notifications/
│       ├── Domain/
│       │   ├── NotificationRepository.swift  # Protocol
│       │   └── RegisterNotificationUseCase.swift
│       └── Data/
│           └── FCMNotificationRepository.swift
│
└── Core/
    ├── Security/
    │   └── KeychainManager.swift          # Keychain read/write; used by FirebaseAuthRepository only
    ├── Network/
    │   ├── NetworkMonitorRepository.swift # Protocol: observeConnectivity() -> AsyncStream<Bool>
    │   └── NWNetworkMonitor.swift         # NWPathMonitor → AsyncStream<Bool>
    ├── CafeConfig/
    │   ├── CafeConfigRepository.swift     # Protocol: fetchConfig() -> CafeConfig
    │   ├── CafeConfig.swift               # Domain model: openTime, closeTime, cutoffMinutes, timeoutMinutes
    │   └── FirebaseCafeConfigRepository.swift
    └── Extensions/
        └── Date+CafeHours.swift           # isWithinOrderingWindow(config:), minutesUntilClose(config:)

CafeAppTests/
├── Features/
│   ├── Auth/
│   ├── Menu/
│   ├── Orders/
│   ├── Loyalty/
│   └── Worker/
└── Mocks/
    ├── MockAuthRepository.swift
    ├── MockMenuRepository.swift
    ├── MockOrderRepository.swift
    ├── MockPaymentRepository.swift
    ├── MockLoyaltyRepository.swift
    ├── MockWorkerOrderRepository.swift
    ├── MockNotificationRepository.swift
    └── MockCafeConfigRepository.swift

CafeAppIntegrationTests/
└── Firebase/
    ├── FirebaseMenuRepositoryTests.swift
    ├── FirebaseOrderRepositoryTests.swift
    └── FirebaseLoyaltyRepositoryTests.swift
```

**Structure Decision**: Option 3 (Mobile + Firebase backend). The iOS app is a single Xcode project with dual-role UI — `CafeAppApp.swift` reads the `role` custom claim on the Firebase Auth token and routes to either the customer tab bar or the worker dashboard. Firebase serves as the backend for MVP (no separate API project). Cloud Functions handle all server-side automation: point awarding, push notification dispatch, and stale-order expiry. Source strictly follows the constitution's vertical-slice feature organization: `Features/{FeatureName}/{Presentation|Domain|Data}`.

## Complexity Tracking

> No constitution violations were identified. All design decisions comply with the principles.
