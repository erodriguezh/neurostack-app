# fn-14-jz7.1 Handle paywall dismiss → return to modal (Phase 3.2)

## Description
After returning from `/paywall` without subscribing, re-show the trial expired modal. The modal should loop until the user either subscribes (exits paywall with premium status) or chooses "Continue with Free".

## Context
From `plan_trial_expiration_modal.md` Phase 3.2.

## Current State
- `_showTrialExpiredDialog()` in `lib/home/home_view.dart` (lines 320-337) calls `showTrialExpiredModal()` and handles choices
- `goToPaywall()` in `lib/home/home_view_model.dart` (line 221) is a `void` method that uses `_routerService.goTo()`
- Navigation is stack-based via `RouterService`

## Implementation

### 1. Make `goToPaywall()` return `Future<void>`
In `lib/home/home_view_model.dart`:
- Change `void goToPaywall()` to `Future<void> goToPaywall()`
- Navigate to paywall and wait for return using a `Completer` that completes when navigation returns to home

### 2. Update `_showTrialExpiredDialog()` with loop
In `lib/home/home_view.dart`:
```dart
Future<void> _showTrialExpiredDialog(HomeViewState state) async {
  while (true) {
    final choice = await showTrialExpiredModal(
      context,
      activeProtocolCount: state.user?.activeProtocolCount ?? 0,
    );

    if (!mounted) return;

    switch (choice) {
      case TrialExpiredChoice.keepEverything:
        await _viewModel.goToPaywall();  // Awaitable
        // After paywall returns, check if still expired
        final currentState = _viewModel.state.value;
        final user = currentState.user;
        if (user != null && _isTrialExpired(user)) {
          continue;  // Re-show modal
        }
        return;  // User subscribed, exit loop
      case TrialExpiredChoice.continueWithFree:
        _viewModel.handleUseFreeTier();
        return;
      case null:
        return;
    }
  }
}

bool _isTrialExpired(User user) {
  return user.subscriptionStatus == SubscriptionStatus.trial &&
      user.getEffectiveStatus(DateTime.now()) == SubscriptionStatus.free;
}
```

### 3. Add import for SubscriptionStatus
In `lib/home/home_view.dart`:
```dart
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
```

## Acceptance
- [ ] `goToPaywall()` returns `Future<void>` that completes when user returns to home
- [ ] `_showTrialExpiredDialog()` loops back to modal if user returns without subscribing
- [ ] `_isTrialExpired()` helper correctly detects trial expiration
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

## Files to Modify
- `lib/home/home_view_model.dart` - Make `goToPaywall()` awaitable
- `lib/home/home_view.dart` - Add loop logic and `_isTrialExpired()` helper

## Done summary
Implemented trial expired modal loop that re-shows after paywall dismiss if user hasn't subscribed. Made goToPaywall() awaitable via Completer, added refresh after paywall return, and ensured expired detection logic matches VM trigger conditions.

**Refactoring (Option B):** Extracted shared `isTrialOrPremiumExpired(User)` method to `HomeViewModel` to eliminate duplicated expiration-check logic between `_maybeTriggerExpiredModal()` and `_showTrialExpiredDialog()`. Removed now-unused `User` and `SubscriptionStatus` imports from `home_view.dart`.

## Evidence
- Commits: 8888c00, a3e858a, 4337602, 48a2801, d0cf9bf
- Tests: flutter analyze, flutter test
- PRs: