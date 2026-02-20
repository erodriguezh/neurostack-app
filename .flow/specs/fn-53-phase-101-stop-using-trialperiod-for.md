# Phase 10.1: Stop Using TrialPeriod for Gating

## Overview
RevenueCat is now the authority for subscription/trial state (Phases 1-9 complete). The `SubscriptionStatusResolver` handles all gating decisions using `EntitlementSnapshot`. The `User.getEffectiveStatus()` method still uses `trialPeriod.isExpired()` for gating, which is redundant and potentially conflicting. Remove all trialPeriod-based gating.

## Scope

### User entity (`lib/features/user/domain/entities/user.dart`)
- **`getEffectiveStatus(DateTime currentTime)`**: Currently checks `trialPeriod.isExpired()` to override `trial` -> `free`. Simplify to just return `subscriptionStatus` (no time-based override). The resolver handles this now.
- Keep the `trialPeriod` field itself (Phase 10.2 makes it optional, Phase 11 removes it)
- Keep `createWithTrial()` factory (Phase 10.2 renames it)

### Callers of `getEffectiveStatus()` or `trialPeriod?.isExpired()`
- Search and remove/update any remaining callers that use trialPeriod for gating
- HomeViewModel and LibraryViewModel already use resolver (Phases 6.1/6.5)

### Tests
- `test/domain/user/user_test.dart` - Update tests for simplified `getEffectiveStatus()`
- Other test files pass `trialPeriod:` to `UserFactory.create()` - these are fine (field still exists)

## Approach
1. Find all callers of `getEffectiveStatus()` and `trialPeriod?.isExpired()`
2. Simplify `getEffectiveStatus()` to return `subscriptionStatus` directly
3. Update affected tests
4. Verify no gating logic depends on trialPeriod

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] `User.getEffectiveStatus()` no longer checks `trialPeriod.isExpired()`
- [ ] No code outside tests uses `user.trialPeriod` for gating/conditional logic
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

## Constraints
- Do NOT remove the `trialPeriod` field from User entity (Phase 10.2)
- Do NOT change UserDto serialization (Phase 10.4)
- Do NOT remove TrialPeriod value object (Phase 11.4)

## References
- Implementation plan: `plan_paywall_modal.md` Phase 10.1
- SubscriptionStatusResolver: `lib/paywall/domain/subscription_status_resolver.dart`
- User entity: `lib/features/user/domain/entities/user.dart`
