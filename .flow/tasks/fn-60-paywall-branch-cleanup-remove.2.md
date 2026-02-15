# fn-60-paywall-branch-cleanup-remove.2 Remove dead domain code from User entity and events

## Description
Remove dead domain methods and events from the User entity that are no longer called from any production code. The webhook now handles all subscription status changes server-side.

**Size:** S
**Files:**
- `lib/features/user/domain/entities/user.dart`
- `lib/features/user/domain/events/user_events.dart`
- `test/domain/user/user_test.dart`

## What to remove

### From `user.dart`
- `upgradeToPremium()` method (L232-253) — never called from production; subscription upgrades handled by RevenueCat webhook
- `updateSubscriptionStatus()` method (L258-266) — comment says "Used when RevenueCat notifies of status changes" but no production caller exists

### From `user_events.dart`
- `TrialStartedEvent` class (L15-21) — never raised; trial is now managed by RevenueCat
- `SubscriptionUpgradedEvent` class (L65-76) — only raised by `upgradeToPremium()` which is being deleted

### From tests
- Tests for `upgradeToPremium()` at `test/domain/user/user_test.dart` (L303-L434 approx)
- Tests for `updateSubscriptionStatus()` if any exist
- Any test that constructs `TrialStartedEvent` or `SubscriptionUpgradedEvent`

## Approach

- Verify with grep before removing: `grep -r "upgradeToPremium\|updateSubscriptionStatus\|TrialStartedEvent\|SubscriptionUpgradedEvent" lib/`
- Keep all other User methods intact
- Keep `SubscriptionStatusChangedEvent` if it exists and is used elsewhere
## Acceptance
- [ ] `User.upgradeToPremium()` removed
- [ ] `User.updateSubscriptionStatus()` removed
- [ ] `TrialStartedEvent` class removed from `user_events.dart`
- [ ] `SubscriptionUpgradedEvent` class removed from `user_events.dart`
- [ ] Associated tests removed
- [ ] `grep -r "upgradeToPremium\|TrialStartedEvent\|SubscriptionUpgradedEvent" lib/` returns no results
- [ ] `flutter test test/domain/user/` passes
- [ ] `flutter analyze` passes
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
