# fn-36-lmc.1 Create EntitlementSnapshot and PaywallOutcome models

## Description

Create internal app-owned models to represent RevenueCat entitlement state. These models keep SDK types at the adapter boundary, following the "SDK types at boundary" design principle.

## Files to Create

### `lib/paywall/domain/entitlement_snapshot.dart`

This file contains:

1. **EntitlementSnapshot** - App-owned model replacing direct `CustomerInfo` usage
2. **EntitlementPeriodType** - Enum for period types (trial, intro, normal)
3. **PaywallOutcome** - Result of paywall presentation

## Implementation Details

### EntitlementSnapshot

**CRITICAL DESIGN DECISIONS:**

- Use `nullable EntitlementSnapshot?` to distinguish:
  - `null` = RC unavailable (web stub, not configured, hard SDK failure) → fallback to DB
  - `EntitlementSnapshot.none()` = RC says user has no entitlement → authoritative

- Track `appUserId` - snapshot is only authoritative when `appUserId == currentUser.id`
- Track `lastPeriodType` even when expired - needed to distinguish "trial expired → free" vs "paid expired → expired"

**Fields:**
- `appUserId: String?` - Track which user this snapshot belongs to
- `hasProEntitlement: bool` - Whether user has active entitlement
- `isTrialPeriod: bool` - Whether currently in trial
- `isInGracePeriod: bool` - Billing issue, payment retry in progress
- `productId: String?` - Product identifier (monthly/yearly)
- `expirationDate: DateTime?` - When entitlement expires
- `originalTransactionId: String?` - Stable transaction ID
- `latestPurchaseDate: DateTime?` - Most recent purchase date
- `lastPeriodType: EntitlementPeriodType?` - Period type even when expired

**Factory methods:**
- `EntitlementSnapshot.none({required String appUserId})` - Known state: user has NEVER had entitlement

**Helper methods:**
- `isForUser(String userId)` - Check if snapshot belongs to given user
- `wasTrialThatExpired` getter - Was this a trial that expired? (for trial-expired modal)
- `wasPaidThatExpired` getter - Was this a paid subscription that expired? (for "resubscribe" UX)
  - NOTE: "intro" is treated as paid (discounted paid period, not free trial)

### EntitlementPeriodType enum

```dart
enum EntitlementPeriodType { trial, intro, normal }
```

- `trial`: Free trial period (7 days, no charge)
- `intro`: Intro offer (discounted paid period - treated as "paid" for churn UX)
- `normal`: Regular billing period

### PaywallOutcome enum

```dart
enum PaywallOutcome { purchased, cancelled, error }
```

Result of paywall presentation.

## Reference

See implementation plan Phase 2.3 in `plan_paywall_modal.md` for full interface specification.

## Acceptance

- [ ] `EntitlementSnapshot` class with all required fields
- [ ] `EntitlementSnapshot.none()` factory that creates "no entitlement" state
- [ ] `isForUser()` method returns correct boolean
- [ ] `wasTrialThatExpired` getter works correctly
- [ ] `wasPaidThatExpired` getter works correctly (includes intro as paid)
- [ ] `EntitlementPeriodType` enum with trial, intro, normal
- [ ] `PaywallOutcome` enum with purchased, cancelled, error
- [ ] File uses immutable class pattern (const constructor)
- [ ] `flutter analyze` passes
- [ ] Unit tests for helper methods

## Done summary
Created EntitlementSnapshot and PaywallOutcome models for RevenueCat integration. The implementation includes the EntitlementSnapshot class with all required fields, none() factory, isForUser() method, wasTrialThatExpired and wasPaidThatExpired getters, plus EntitlementPeriodType and PaywallOutcome enums with comprehensive unit tests (21 tests passing).
## Evidence
- Commits: 006e7c368dba184fe9883a1053fb7f3820069bd2
- Tests: flutter test test/paywall/domain/entitlement_snapshot_test.dart
- PRs: