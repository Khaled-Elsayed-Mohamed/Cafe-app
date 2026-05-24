<!--
SYNC IMPACT REPORT
==================
Version change: (none — initial population) → 1.0.0
Source: Migrated from project-root CONSTITUTION.md into Spec Kit memory.

Principles established (all new):
- I. Architecture Integrity
- II. Code Quality Standards
- III. Testing-First Mindset
- IV. Agent Constraints (Claude Code)
- V. Code Organization Philosophy

Added sections:
- Forbidden Patterns & Code Review Checklist
- Security & Configuration Management
- Governance (amendment procedure, production migration path, success definition)

Templates reviewed:
- .specify/templates/plan-template.md  ✅ no changes required
  (Constitution Check section uses dynamic runtime reference — compatible)
- .specify/templates/spec-template.md  ✅ no changes required
  (generic structure is platform-agnostic; iOS specifics live in plan.md)
- .specify/templates/tasks-template.md ⚠️ pending
  (path conventions show `src/`, `tests/` and pytest — iOS projects use
   `Features/`, `XCTest` targets; update when first feature is planned)

Deferred TODOs:
- TODO(RATIFICATION_DATE): Original CONSTITUTION.md authorship date unknown;
  set to 2026-05-24 (migration date). Update if earlier date is known.
-->

# iOS Café App Constitution

## Core Principles

### I. Architecture Integrity

All external dependencies (Firebase, Square, barcode scanning) MUST be abstracted
behind protocols. Layering MUST be strictly enforced: Presentation → Domain → Data →
Hardware.

- Views are dumb — no business logic; ViewModels orchestrate
- No Firebase imports outside the Data layer
- No Square imports outside the Data layer
- Domain models MUST be pure Swift with no framework dependencies (except Foundation)
- All Square/backend calls MUST sit behind protocols for testability
- Backend integration MUST be abstracted so the Data layer can be swapped with
  zero changes to Domain or Presentation

### II. Code Quality Standards

Every domain logic path MUST be unit testable. No exceptions.

- Dependency injection via constructor — no singletons, no static dependencies
- Errors MUST be transformed at layer boundaries; Firebase errors MUST NOT reach UI
- No force unwraps in production code — use guard, throw, or optional chaining
- SwiftUI only — no UIKit, no legacy patterns
- async/await exclusively — no callbacks, no Combine (KISS principle)
- No hardcoded values — all configuration MUST be injected
- No copy-paste code — extract to reusable components immediately

### III. Testing-First Mindset

If code cannot be unit tested in isolation, the architecture is wrong. Testability
drives design decisions — it is never an afterthought.

- Mock repository implementations MUST exist before writing any UI
- Integration tests MUST use the Firebase emulator only — never hit live Firebase
  in unit tests
- Unit test coverage for domain logic MUST exceed 80%
- If a class requires a real network call to test, the design is incorrect

### IV. Agent Constraints (Claude Code)

Claude Code is bound by this constitution and MUST enforce it actively in every
interaction.

- Reject requests that violate architecture (e.g., "just import Firebase in the ViewModel")
- Reject requests that reduce testability (e.g., "make it a singleton")
- Reject shortcuts justified by speed that compromise maintainability
- Suggest the correct approach whenever a request conflicts with principles
- Push back on scope creep — distinguish MVP from nice-to-have
- Ask clarifying questions when a specification is ambiguous

### V. Code Organization Philosophy

Code MUST be organized by feature, not by layer. Every feature owns its full
vertical slice.

```
Features/
  Menu/
    Presentation/   (SwiftUI views — UI only)
    Domain/         (business rules — pure Swift)
    Data/           (repositories — Firebase/API implementations)
  Orders/
    Presentation/
    Domain/
    Data/
```

This ensures that someone working on a feature finds all related code in one place,
reducing cognitive load and cross-team conflicts.

## Forbidden Patterns & Code Review Checklist

The following patterns are forbidden in all production code:

| Pattern | Why Forbidden | Correct Alternative |
|---------|--------------|---------------------|
| Singletons | Not testable; global mutable state | Dependency injection |
| Static methods | Cannot be mocked in tests | Instance methods on injected types |
| Force unwraps (`!`) | Crashes at runtime | Optional chaining, `guard`, `throw` |
| Hardcoded values | Not configurable; not injectable | Inject via constructor or Config struct |
| Copy-paste code | Maintenance nightmare | Extract to reusable components |
| UIKit (when SwiftUI available) | Legacy; harder to test | SwiftUI |
| Firebase/Square imports in Domain layer | Couples logic to framework | Protocol abstraction in Data layer |
| Async callbacks / Combine | Hard to test; callback hell | async/await |

**Every PR MUST pass this checklist before merge**:

Architecture & Testability:
- [ ] No singletons or static dependencies
- [ ] All data sources sit behind protocols
- [ ] Domain logic has no framework imports (except Foundation)
- [ ] ViewModels use protocols only — no concrete Firebase or Square classes
- [ ] Error types are domain-specific (no Firebase errors leaking to UI)
- [ ] Unit tests exist for domain logic (>80% coverage)
- [ ] No force unwraps in production code
- [ ] Configuration is injected, not hardcoded
- [ ] async/await used throughout — no callbacks
- [ ] Duplicated code extracted to shared functions

Security:
- [ ] No API keys or secrets hardcoded in source
- [ ] No database passwords or auth tokens in constants
- [ ] Secrets loaded from Build Settings / Info.plist, not literals
- [ ] `.env` file is in `.gitignore`
- [ ] Sensitive data never logged to console
- [ ] Keychain used for all stored credentials

## Security & Configuration Management

Sensitive values (API keys, tokens, passwords) MUST NEVER appear in source code.

**Required approach**:

1. Store secrets in `.env` files excluded from Git:
   ```
   # .env  (add to .gitignore)
   FIREBASE_API_KEY=AIzaSyD...
   SQUARE_API_KEY=sq_live_...
   ```

2. Surface values through Build Settings into `Info.plist`, then read at runtime:
   ```swift
   struct Config {
       static let firebaseKey = Bundle.main.infoDictionary?["FIREBASE_API_KEY"] as? String ?? ""
       static let squareKey   = Bundle.main.infoDictionary?["SQUARE_API_KEY"]   as? String ?? ""
   }
   ```

3. Store runtime credentials in Keychain — never in `UserDefaults` or string constants:
   ```swift
   KeychainManager.store(token: authToken, for: "auth_token")
   let token = KeychainManager.retrieve("auth_token")
   ```

**`.gitignore` MUST include**:
```
.env
.env.local
.env.*.local
config.local.json
Secrets.xcconfig
**/Secrets/*
**/APIKeys/*
```

## Governance

This constitution supersedes all other development practices and conventions. It does
not bend to "we are in a hurry" or "this is just MVP." These principles ARE what makes
a reliable MVP possible.

**Amendment procedure**:
1. Propose the change in writing, referencing the specific principle being modified
2. Justify why the amendment improves testability, maintainability, or security
3. Increment the version per semantic versioning:
   - MAJOR: backward-incompatible removal or redefinition of a principle
   - MINOR: new principle or materially expanded guidance added
   - PATCH: clarification, wording fix, non-semantic refinement
4. Update this file and propagate changes to all dependent templates

**Production migration path** — when client upgrades infrastructure:
1. Create new API-backed implementations of existing protocols
   (e.g., `APIBarcodeRepository` implements `BarcodeRepository`)
2. Swap implementations in `DependencyContainer` only
3. Domain and Presentation layers require zero changes — protocol abstraction
   guarantees clean infrastructure swap

**Success definition** — the app is production-ready when:
- All domain logic is unit tested (>80% coverage)
- Barcode scanning works without internet (offline cache)
- Member points awarded correctly in all scenarios
- Order status updates in real-time (Firebase listeners)
- Payments processed securely (Stripe test mode)
- All error paths tested: invalid barcode, network down, member not found
- No force unwraps anywhere in production code
- Architecture allows Firebase → custom API swap with zero app logic changes

All PRs and code reviews MUST verify compliance with every principle above.
Runtime development guidance lives in `CLAUDE.md` and this file.

**Version**: 1.0.0 | **Ratified**: 2026-05-24 | **Last Amended**: 2026-05-24
