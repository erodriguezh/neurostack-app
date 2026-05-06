# fn-81-paywall-apple-compliance.2 Add Restore Purchases to Settings + rename Manage Subscription

## Description
**Size:** M
**Files:**
- `lib/settings/settings_view_model.dart` — add `restorePurchases()` method, inject `NotifyService`
- `lib/settings/widgets/settings_support_section.dart` — add Restore tile, rename Cancel→Manage, update callback name
- `lib/settings/settings_view.dart` — wire new callback, pass `NotifyService` to VM
- `test/settings/settings_view_model_test.dart` — add restore tests, update cancel→manage tests
- `test/settings/widgets/settings_brightness_test.dart` — update "Cancel Subscription" assertions

## Approach

### 1. Rename Cancel Subscription → Manage Subscription

- In `settings_support_section.dart:80`: change label from `'Cancel Subscription'` to `'Manage Subscription'`
- Rename callback parameter `onCancelSubscriptionTap` → `onManageSubscriptionTap` throughout:
  - `settings_support_section.dart` (parameter declaration + usage)
  - `settings_view.dart:116` (wiring)
- Update visibility: change from `isPremium`-only to `canAccessPremium` (includes trial users)
  - Follow `PremiumAwareViewModelMixin` which provides `isPremium` ValueNotifier
  - The mixin's `SubscriptionStatus` has `canAccessPremium` — check how it's exposed

### 2. Add Restore Purchases tile

- Add new `_TileEntry` in `settings_support_section.dart` for "Restore Purchases"
  - Icon: `LucideIcons.rotateCcw` or similar restore icon
  - Trailing: none (it's an in-app action, not external link)
  - Visibility: **always visible** (Apple requires for ALL users)
  - Position: above "Manage Subscription"
- Add `VoidCallback onRestorePurchasesTap` parameter to `SettingsSupportSection`
- Wire in `settings_view.dart`

### 3. Add restorePurchases() to SettingsViewModel

- Inject `NotifyService` via constructor (follow `RateAppViewModel` pattern at `lib/settings/rate_app/rate_app_view_model.dart`)
- Add `_isRestoring` guard (mirrors `_isPresenting` pattern in `paywall_view_model.dart`)
- Call `_revenueCatService.restorePurchases()` which returns `Future<bool>`
- After restore, check if entitlement changed:
  - `true` + entitlement active → `ToastEventSuccess(message: 'Purchases restored successfully')`
  - `true` + no entitlement → `ToastEventInfo(message: 'No previous purchases found')`
  - `false` or exception → `ToastEventError(message: 'Unable to restore purchases. Please try again.')`
- Guard against disposal during async (check `_isDisposed` pattern from existing VM methods)

### 4. Hide Restore on web

- `RevenueCatClientStub.restorePurchases()` is a no-op — restore is meaningless on web
- Gate the Restore tile visibility on `!kIsWeb` or platform check
- Follow the platform detection pattern used elsewhere in Settings

### 5. Tests

- Follow existing patterns in `test/settings/settings_view_model_test.dart` (652 lines)
- Use `MockRevenueCatService` from `test/mocks/mock_services.dart:43`
- `MockNotifyService` — may need to be created or already exists in mocks
- Test cases:
  - `restorePurchases()` calls `revenueCatService.restorePurchases()`
  - Success with entitlement → success toast
  - Success without entitlement → info toast
  - Failure → error toast
  - Double-tap guard: second call while restoring is ignored
  - "Manage Subscription" label renders (was "Cancel Subscription")
  - Restore tile always visible; Manage tile visible when `canAccessPremium`

## Key context

- **Gotcha:** `SettingsViewModel` does NOT currently inject `NotifyService`. Adding it changes the constructor, the `SettingsView` locator call, and ALL test setups.
- **Reuse:** `RevenueCatService.restorePurchases()` at `lib/paywall/data/revenuecat_service.dart:340-363` already exists and returns `Future<bool>`. Wire to it; do NOT reimplement.
- **Reuse:** `FakeRevenueCatClient` at `test/mocks/fake_revenuecat_client.dart:25` tracks `restorePurchasesWasCalled`.
- **Reuse:** Toast events at `lib/core/utils/internal_notification/toast/toast_event.dart`.
- **Pattern:** `_isPresenting` guard in PaywallViewModel — mirror for `_isRestoring`.
- **fn-46-1b8:** Was marked done but never implemented. This task absorbs that scope.
## Acceptance
- [ ] "Cancel Subscription" renamed to "Manage Subscription" in UI
- [ ] `onCancelSubscriptionTap` renamed to `onManageSubscriptionTap` in code
- [ ] "Manage Subscription" visible when `canAccessPremium` (premium + trial users)
- [ ] "Restore Purchases" tile added, always visible to all users (not on web)
- [ ] `restorePurchases()` method on SettingsViewModel calls `RevenueCatService.restorePurchases()`
- [ ] `NotifyService` injected into SettingsViewModel
- [ ] Toast: success + entitlement → "Purchases restored successfully"
- [ ] Toast: success + no entitlement → "No previous purchases found"
- [ ] Toast: failure → "Unable to restore purchases. Please try again."
- [ ] `_isRestoring` guard prevents concurrent restore calls
- [ ] Disposal guard: async callback checks `_isDisposed` before showing toast
- [ ] Restore tile hidden on web
- [ ] All existing settings tests pass
- [ ] New tests for restore (success/no-purchases/failure/double-tap/disposal)
- [ ] `flutter analyze` clean
## Done summary
Implemented all acceptance criteria for fn-81-paywall-apple-compliance.2. Renamed Cancel→Manage Subscription, added Restore Purchases tile, injected NotifyService, added restorePurchases() with _isRestoring guard and user-scoped snapshot check. 96 tests pass, flutter analyze clean.
## Evidence
- Commits: 6ce72f5
- Tests: 96 pass (settings_view_model_test.dart, settings_brightness_test.dart)
- PRs: