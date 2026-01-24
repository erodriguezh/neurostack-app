# fn-10-qt1.1 Fix _maybeTriggerExpiredModal() to detect trial expiration

## Description

**File:** `lib/home/home_view_model.dart`

**Problem:** The current `_maybeTriggerExpiredModal()` checks `subscriptionStatus == SubscriptionStatus.expired`, but `expired` is for RevenueCat premium lapses, not trial expiration. Trial expiration keeps `subscriptionStatus == trial` in DB but `getEffectiveStatus()` returns `free`.

**Fix:** Update the trigger logic to detect both:
1. Trial expiration: stored status is `trial`, but `getEffectiveStatus(DateTime.now())` returns `free`
2. RevenueCat premium expiration: status is `expired`

```dart
void _maybeTriggerExpiredModal(User user) {
  if (_hasShownExpiredModal) return;

  // Check for trial expiration: stored status is trial, but effective status is free
  final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
      user.getEffectiveStatus(DateTime.now()) == SubscriptionStatus.free;

  // Also handle RevenueCat premium expiration
  final isPremiumExpired = user.subscriptionStatus == SubscriptionStatus.expired;

  if (isTrialExpired || isPremiumExpired) {
    _hasShownExpiredModal = true;
    state.value = state.value.copyWith(showTrialExpiredModal: true);
  }
}
```

## Acceptance
- [ ] `_maybeTriggerExpiredModal()` triggers modal when trial is expired (trial status + effective free)
- [ ] `_maybeTriggerExpiredModal()` still triggers for premium expiration (expired status)
- [ ] `_maybeTriggerExpiredModal()` does NOT trigger for active trial (trial status + effective trial)
- [ ] Tests pass
- [ ] `flutter analyze` clean

## Done summary
- Task completed
## Evidence
- Commits:
- Tests:
- PRs: