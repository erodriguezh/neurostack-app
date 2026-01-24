# fn-17-vzn.1 Update handleUseFreeTier to transition users to free tier when ≤2 protocols

## Description
Update `handleUseFreeTier()` in HomeViewModel to actually transition users to free tier when they have ≤2 active protocols.

## File
`lib/home/home_view_model.dart`

## Current Behavior (lines 200-209)
```dart
void handleUseFreeTier() {
  final user = state.value.user;
  if (user == null) {
    return;
  }

  if (user.activeProtocolCount > 2) {
    state.value = state.value.copyWith(showDeactivationModal: true);
  }
}
```

Currently only shows deactivation modal if >2 protocols, but does nothing when ≤2 protocols.

## Required Change
When user has ≤2 active protocols, transition them to free tier by:
1. Updating subscription status to `free` using `user.updateSubscriptionStatus()`
2. Saving to repository via `_userRepository.save()`
3. Updating cache via `_cachedUserStore?.saveUser()`
4. Refreshing state via `refresh()`

## Target Implementation
```dart
Future<void> handleUseFreeTier() async {
  final user = state.value.user;
  if (user == null) return;

  if (user.activeProtocolCount > 2) {
    state.value = state.value.copyWith(showDeactivationModal: true);
    return;
  }

  // ≤2 protocols: transition to free tier
  final updatedUser = user.updateSubscriptionStatus(SubscriptionStatus.free);
  await _userRepository.save(updatedUser);
  await _cachedUserStore?.saveUser(updatedUser);

  // Refresh state with updated user
  await refresh();
}
```

## Call Site Update
Check `lib/home/home_view.dart` - if the call site expects completion, add `await`.

## Acceptance
- [ ] `handleUseFreeTier()` is now async (`Future<void>`)
- [ ] When activeProtocolCount > 2: shows deactivation modal (existing behavior)
- [ ] When activeProtocolCount ≤ 2: updates status to free, saves to repo/cache, refreshes state
- [ ] Call site in home_view.dart updated if needed
- [ ] flutter analyze passes
- [ ] Tests pass

## Done summary
Updated handleUseFreeTier() to be async and transition users with ≤2 protocols to free tier by saving to repository and cache, with proper error handling. Also fixed isTrialOrPremiumExpired() to check raw subscriptionStatus instead of effectiveStatus, preventing modal re-trigger after choosing free tier.
## Evidence
- Commits: f0b6522b6f63d18a0660c1abf91b5e11f6ae5e72, 9d8c3ac77f8129191c4259698a49b367714ea8d0
- Tests: flutter analyze, flutter test
- PRs: