# fn-39-z4l Phase 2.6: Create RevenueCatService

## Overview

Create `RevenueCatService` - the high-level wrapper around `RevenueCatClient` that initializes the SDK, exposes entitlement state, handles identify/logout with init gating, guards against multiple paywall presentations, and provides refresh/restore functionality.

## Scope

**New File:** `lib/paywall/data/revenuecat_service.dart`

**Pattern Reference:** Follow `SessionSyncService` at `lib/features/session/data/services/session_sync_service.dart`

## Approach

### Constructor Injection
- Receives `RevenueCatClient` via constructor (not `locator<>`)

### State Management
- Use nullable `ValueNotifier<EntitlementSnapshot?>` to distinguish:
  - `null` = unknown (RC unavailable, not yet initialized)
  - `EntitlementSnapshot` = known state (may be `.none()` = no entitlement)

### Init Flow
- `init()` must be idempotent (subsequent calls return same future)
- Use `_initStarted` guard + `Completer<void>` pattern
- Select platform-appropriate API key using `lib/core/utils/app_environment.dart`
- Configure SDK MUST complete before anything else
- Subscribe to `_client.entitlementChanges` during configure
- Only emit from listener if `_identifiedUserId != null` and `snapshot.appUserId == _identifiedUserId`

### Identify/Logout
- `identify(userId)` queues until init() completes (prevents race)
- Seeds initial snapshot after identify via `refreshEntitlement()`
- `logout()` clears `_identifiedUserId` and sets snapshot to `null`

### Paywall Presentation
- `presentPaywall()` must gate on: init completion, user identification, not already presenting
- Refresh entitlement after paywall closes

### Refresh/Restore
- `refreshEntitlement()` gates on init, swallows all exceptions (safe for lifecycle callbacks)
- Never clobber known state with null (use `_updateSnapshotIfBetter()`)
- `restorePurchases()` for device change/reinstall scenarios

## Quick commands
- `flutter analyze`
- `flutter test test/paywall/`

## Acceptance
- [ ] Service compiles and passes `flutter analyze`
- [ ] Constructor injection (no `locator<>` calls inside service)
- [ ] `init()` is idempotent
- [ ] `identify()` queues until init completes
- [ ] `presentPaywall()` gates on init + identification
- [ ] `refreshEntitlement()` never throws
- [ ] Unit tests for init, identify, logout, presentPaywall flows

## References
- `plan_paywall_modal.md` Phase 2.6
- Design Principles #7, #9, #10, #11 from plan
