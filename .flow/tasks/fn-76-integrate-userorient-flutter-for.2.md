# fn-76-integrate-userorient-flutter-for.2 Wire Feature Request tap, theming, and logout cleanup

## Description
Wire the Settings screen "Feature Request" tile via a ViewModel method with constructor-injected `UserOrientService`, add `clearCache()` to both logout paths in `AuthService`, and add unit tests scoped to the right files.

**Size:** M
**Files:**
- `lib/settings/settings_view_model.dart` — add `UserOrientService` constructor param, add `openFeatureRequestBoard(BuildContext)` method
- `lib/settings/settings_view.dart` — pass `UserOrientService` to ViewModel, delegate tap (line 108)
- `lib/features/auth/data/auth_service.dart` — add `clearCache()` to `logout()` AND `_handleAuthChange(signedOut)`
- `test/settings/settings_view_model_test.dart` — tests for board-opening behavior
- `test/features/auth/data/auth_service_test.dart` — tests for cleanup in both logout paths

## Approach
- **SettingsViewModel**: Add `UserOrientService` as a constructor parameter (not `locator<>()` — matches existing DI pattern where all deps are constructor-injected, see `settings_view_model.dart:21-39`). Add `openFeatureRequestBoard(BuildContext context)` method that:
  1. Extracts user ID from `_authService.authState.value` via pattern match on `AuthenticatedOnline(user)` / `AuthenticatedOffline(user)`
  2. If not authenticated, returns early (no-op guard)
  3. Derives `isPaying` from `_resolver.resolveEffectiveStatus(user: user, snapshot: _revenueCatService.entitlementSnapshot.value).isPremium`
  4. Calls `_userOrientService.openBoard(context, userId: user.id, isPaying: isPaying)`
- **SettingsView** (`settings_view.dart:108`): replace `onFeatureRequestTap: () {}` with `onFeatureRequestTap: () => _viewModel.openFeatureRequestBoard(context)`. Pass `locator<UserOrientService>()` to ViewModel constructor from `_SettingsViewState`.
- **AuthService cleanup** (constructor-injected `_userOrientService` from task 1):
  - `logout()` (line ~91): add `await _userOrientService.clearCache()` — awaited best-effort cleanup with try-catch, after RevenueCat logout, before Supabase signOut (same pattern as RevenueCat at `auth_service.dart:88`)
  - `_handleAuthChange()` signedOut case (line ~158): add `unawaited(_userOrientService.clearCache().catchError((e, st) { _logger.fine('UserOrient clearCache skipped: $e', e, st); }))` — unawaited with `.catchError()` on the future chain, after RevenueCat logout (matches existing RevenueCat pattern at `auth_service.dart:160-167`). Note: `try-catch` does NOT catch async errors from unawaited futures.
- **Test scoping**:
  - `test/settings/settings_view_model_test.dart`: authenticated tap calls `openBoard` with correct args, unauthenticated tap is no-op, `isPaying` derived correctly
  - `test/features/auth/data/auth_service_test.dart`: `logout()` triggers `clearCache()`, `signedOut` auth event triggers `clearCache()`

## Key context
- `SettingsViewModel` already has `AuthService`, `RevenueCatService`, `SubscriptionStatusResolver` via constructor — adding `UserOrientService` follows the same pattern
- `onFeatureRequestTap` is `VoidCallback` — no signature change needed
- `context` from `ValueListenableBuilder` builder at `settings_view.dart:88` is passed through
- `SubscriptionStatus.isPremium` covers `premiumMonthly`, `premiumAnnual`, `grace`
- Auth `signedOut` event at `auth_service.dart:158` is an independent sign-out path that bypasses `logout()`

## Acceptance
- [ ] `UserOrientService` constructor-injected into `SettingsViewModel` (not via locator)
- [ ] `SettingsViewModel.openFeatureRequestBoard(context)` method exists
- [ ] Tapping "Feature Request" opens the UserOrient board via ViewModel delegation
- [ ] Board receives correct user ID (Supabase auth UUID)
- [ ] Board receives `isPaying: true` for premium users, `false` otherwise
- [ ] Tap is a no-op when user is not authenticated (no crash)
- [ ] `clearCache()` called in `AuthService.logout()` via constructor-injected `_userOrientService`
- [ ] `clearCache()` called in `AuthService._handleAuthChange(signedOut)` via constructor-injected `_userOrientService`
- [ ] SettingsViewModel test: authenticated tap calls `openBoard` with correct userId and isPaying
- [ ] SettingsViewModel test: unauthenticated tap is a no-op
- [ ] SettingsViewModel test: isPaying derived from `SubscriptionStatus.isPremium`
- [ ] AuthService test: `logout()` triggers `clearCache()` on UserOrientService
- [ ] AuthService test: `signedOut` auth event triggers `clearCache()` on UserOrientService
- [ ] `flutter analyze` passes, all tests pass

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
