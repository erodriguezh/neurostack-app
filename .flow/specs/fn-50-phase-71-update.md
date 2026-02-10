# Phase 7.1: Update TrialExpirationDecisionStore Re-keying

## Overview
Re-key `TrialExpirationDecisionStore` from `trialStartDate` to RevenueCat-stable identifiers. The current keying uses `trialStartDate` which won't exist under RevenueCat.

## Scope
- `lib/paywall/data/trial_expiration_decision_store.dart` — add new snapshot-based methods
- `test/paywall/data/trial_expiration_decision_store_test.dart` — tests for new keying logic
- Callers that use the old `isResolved`/`markResolved` will be migrated in later phases

## Approach
1. Add `_buildDecisionKey()` with fallback hierarchy: originalTransactionId > latestPurchaseDate > expirationDate > null
2. Add `isSubscriptionExpirationResolved()` and `markSubscriptionExpirationResolved()` to interface + impl
3. Add `ExpirationDecision` enum (upgrade/useFreeTier)
4. Keep existing `trialStartDate`-based methods for backward compatibility
5. Write unit tests

## Quick commands
- `flutter test test/paywall/data/trial_expiration_decision_store_test.dart`
- `flutter analyze`

## Acceptance
- [ ] New methods added to interface and implementation
- [ ] Decision key fallback hierarchy works correctly
- [ ] Null key returns false for isResolved (fail-safe: show modal)
- [ ] Null key does nothing for markResolved (non-cacheable)
- [ ] Tests pass
- [ ] flutter analyze clean

## References
- `plan_paywall_modal.md` → Phase 7.1
- `lib/paywall/domain/entitlement_snapshot.dart` — EntitlementSnapshot model
