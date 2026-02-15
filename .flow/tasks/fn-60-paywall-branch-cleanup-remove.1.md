# fn-60-paywall-branch-cleanup-remove.1 Remove dead code from TrialExpirationDecisionStore

## Description
Remove all dead code from `TrialExpirationDecisionStore` — both the legacy methods (keyed by trialStartDate) and the newer subscription-based methods that were never wired into production code.

**Size:** M
**Files:**
- `lib/paywall/data/trial_expiration_decision_store.dart` (interface + implementation)
- `test/paywall/data/trial_expiration_decision_store_test.dart`

## What to remove

### From the abstract interface (top of file)
- `isResolved()` method signature (L22-28)
- `markResolved()` method signature (L30-40)
- `isSubscriptionExpirationResolved()` method signature (L50-56)
- `markSubscriptionExpirationResolved()` method signature (L57-65)
- `ExpirationDecision` enum (L7-13 — only used by dead methods)

### From the implementation
- `_keyPrefix` constant (L94)
- `_subExpKeyPrefix` constant (L95)
- `_key()` helper (L100-101)
- `_buildDecisionKey()` helper (L114-136)
- `isResolved()` implementation (L140-156)
- `markResolved()` implementation
- `isSubscriptionExpirationResolved()` implementation (L161-175)
- `markSubscriptionExpirationResolved()` implementation (L176-189)

### From tests
- All tests covering the removed methods (~20+ test cases)
- Keep tests for `saveLastSeenStatus()` and `getLastSeenStatus()` (these ARE used in production)

## Approach

- Follow pattern at `lib/paywall/data/trial_expiration_decision_store.dart` — the file has clear sections
- The remaining interface should only contain: `saveLastSeenStatus()`, `getLastSeenStatus()`, constructor
- Verify with `grep -r "isResolved\|markResolved\|isSubscriptionExpirationResolved\|markSubscriptionExpirationResolved\|ExpirationDecision" lib/` that no production code references these

## Key context

- The legacy methods have comments saying "Kept for backward compatibility" — that compatibility is no longer needed since callers were migrated
- The "new" subscription methods were designed but never wired into HomeViewModel; production uses `saveLastSeenStatus`/`getLastSeenStatus` instead
- Orphaned SharedPreferences keys under `trial_expired_resolved:` prefix are harmless and don't need cleanup
## Acceptance
- [ ] `ExpirationDecision` enum deleted
- [ ] `isResolved()` / `markResolved()` removed from interface and implementation
- [ ] `isSubscriptionExpirationResolved()` / `markSubscriptionExpirationResolved()` removed from interface and implementation
- [ ] `_buildDecisionKey()`, `_keyPrefix`, `_subExpKeyPrefix`, `_key()` helpers removed
- [ ] Tests for removed methods deleted; tests for `saveLastSeenStatus`/`getLastSeenStatus` preserved
- [ ] `grep -r "ExpirationDecision" lib/` returns no results
- [ ] `flutter test test/paywall/` passes
- [ ] `flutter analyze` passes
## Done summary
Removed all dead code from TrialExpirationDecisionStore: deleted ExpirationDecision enum, legacy isResolved/markResolved methods, unused subscription-based methods (isSubscriptionExpirationResolved/markSubscriptionExpirationResolved), associated helpers (_buildDecisionKey, _keyPrefix, _subExpKeyPrefix, _key), EntitlementSnapshot import, and ~440 lines of tests for the removed methods. Preserved saveLastSeenStatus/getLastSeenStatus which are used in production.
## Evidence
- Commits: 4b650e14960abe91e50191f5262a619675ec58f6
- Tests: flutter test test/paywall/, flutter analyze
- PRs: