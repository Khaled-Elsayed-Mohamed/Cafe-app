# Quickstart: iOS Café App

**Branch**: `001-ios-cafe-app` | **Date**: 2026-05-24 | **Plan**: [plan.md](plan.md)

Developer onboarding guide — environment setup, local development, and running tests.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 16+ | Mac App Store |
| Swift | 5.10+ | Bundled with Xcode |
| Firebase CLI | 13+ | `npm install -g firebase-tools` |
| Node.js | 20+ | [nodejs.org](https://nodejs.org) (required for Firebase CLI + Cloud Functions) |
| CocoaPods or SPM | — | SPM is preferred (Xcode built-in) |

---

## 1. Clone and Open the Project

```bash
git clone <repo-url>
cd CAFE-APP
open CafeApp/CafeApp.xcodeproj
```

---

## 2. Firebase Setup

### 2a. Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project named `cafe-app-dev`
2. Add an iOS app with bundle ID `com.yourname.cafeapp`
3. Download `GoogleService-Info.plist` and place it at `CafeApp/CafeApp/GoogleService-Info.plist`
4. Enable **Authentication** → Email/Password sign-in
5. Enable **Cloud Firestore** in Native mode
6. Enable **Cloud Messaging** (for push notifications)

### 2b. Configure Build Settings

In Xcode → Target: CafeApp → Build Settings → Add these User-Defined settings:

```
SQUARE_APPLICATION_ID = sandbox-sq0idb-...    ← your Square sandbox Application ID
```

Then in `CafeApp/Info.plist`, add:

```xml
<key>SQUARE_APPLICATION_ID</key>
<string>$(SQUARE_APPLICATION_ID)</string>
```

The `Config.swift` struct reads these at runtime — never commit raw key values to source.

### 2c. Square Setup

1. Log in to your existing Square Developer Dashboard and create a sandbox application
2. Copy the **Sandbox Application ID** (`sandbox-sq0idb-...`) — this is the value used in Build Settings above
3. Your Square **access token** (for server-side charge completion) belongs only in Firebase Cloud Functions environment config, never in the iOS app:
   ```bash
   firebase functions:config:set square.access_token="EAAAl..."
   ```
4. Deploy the `chargeCard` callable function (see `functions/` directory) — it receives the Square payment nonce from the app and completes the charge server-side

---

## 3. Swift Package Dependencies

Firebase is managed via SPM. Square In-App Payments SDK requires CocoaPods (Square does not publish a Swift package as of 2026).

**If using CocoaPods for everything**, your `Podfile`:

```ruby
platform :ios, '17.0'

target 'CafeApp' do
  use_frameworks!
  pod 'SquareInAppPaymentsSDK'
end
```

Then add Firebase via SPM inside Xcode → File → Add Package Dependencies:

| Package | URL | Version |
|---------|-----|---------|
| Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk` | 11.0+ |

Add these Firebase products to the `CafeApp` target:
- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseMessaging`

**Do not add any Firebase or Square products to `CafeAppTests`** — tests use mock implementations only.

---

## 4. Firebase Emulator Suite (for Local Development)

All development and testing runs against the Firebase emulator — never against live Firebase.

### 4a. Install and Initialize

```bash
# From repo root
firebase login
firebase init emulators
# Select: Authentication, Firestore, Functions, Cloud Messaging
# Accept default ports
```

### 4b. Seed Data

```bash
# Start emulators with seed data
firebase emulators:start --import=./firebase-seed
```

The `firebase-seed/` directory contains:
- Sample menu items (all 4 categories, including app-only items)
- A test customer account (`customer@test.com` / `Test1234!`)
- A test staff account (`worker@test.com` / `Test1234!`)
- A sample loyalty account with 9 completed orders (next order triggers reward)
- Café config with operating hours 07:00–20:00

### 4c. Connect the App to the Emulator

In `DependencyContainer.swift`, toggle the emulator flag before building for development:

```swift
static func live(useEmulator: Bool = false) -> DependencyContainer {
    if useEmulator {
        // Connects to localhost emulator ports
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        Firestore.firestore().useEmulator(withHost: "localhost", port: 8080)
    }
    // ...
}
```

Set `useEmulator: true` in `CafeAppApp.swift` during development. Use a build flag (`DEBUG`) to automate this so it never ships to production.

---

## 5. Running Tests

### Unit Tests (no emulator required)

```bash
xcodebuild test \
  -project CafeApp/CafeApp.xcodeproj \
  -scheme CafeAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Unit tests use mock repository implementations from `CafeAppTests/Mocks/`. No network calls are made.

### Integration Tests (Firebase Emulator required)

```bash
# Terminal 1: start emulators
firebase emulators:start --import=./firebase-seed

# Terminal 2: run integration tests
xcodebuild test \
  -project CafeApp/CafeApp.xcodeproj \
  -scheme CafeAppIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Integration tests verify that `Firebase*Repository` implementations read and write correctly against the emulator.

---

## 6. Build and Run (Development)

1. Select target **CafeApp** and simulator **iPhone 16** in Xcode
2. Ensure the Firebase emulator is running (step 4b above)
3. Press **⌘R** to build and run

**Customer flow**: Log in as `customer@test.com` → browse menu → add to cart → checkout (Square sandbox uses test card nonces automatically — the In-App Payments SDK card entry screen returns a sandbox nonce when a test card number is entered)

**Worker flow**: Log in as `worker@test.com` → worker dashboard shows incoming orders → accept → check off items → mark ready

---

## 7. Secrets Checklist

Before committing, verify none of these are in source:

- [ ] `GoogleService-Info.plist` is in `.gitignore`
- [ ] Square Application ID is in Build Settings only, not in any `.swift` file
- [ ] Square access token is only in Firebase Cloud Functions environment config (`firebase functions:config:set`), never in the iOS app
- [ ] No real customer emails, names, or payment data in seed files
- [ ] `Secrets.xcconfig` (if used) is in `.gitignore`

---

## 8. Key Files Reference

| File | Purpose |
|------|---------|
| `App/DependencyContainer.swift` | Wires all repository protocols to concrete implementations |
| `App/Config.swift` | Reads Square Application ID and Firebase keys from `Info.plist` |
| `Core/Security/KeychainManager.swift` | Keychain read/write for auth tokens |
| `Core/Network/NWNetworkMonitor.swift` | Offline detection (`NWPathMonitor`) |
| `Core/CafeConfig/CafeConfig.swift` | Operating hours domain model |
| `specs/001-ios-cafe-app/contracts/` | Swift protocol definitions (architectural boundaries) |
| `specs/001-ios-cafe-app/data-model.md` | Firestore schema + Swift domain models |
