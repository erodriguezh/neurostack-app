# fn-77-rate-app-in-app-review-integration.2 Rate App screen, route, and ViewModel

## Description
Create the Rate App screen (view + view model), add the route to `route_config.dart` as a flat `RouteEntry`, and style it following existing screen patterns. Handle unsupported platform behavior with proper CTA state model, fallback URL mapping, config validation, and failure UX.

**Size:** M
**Files:**
- `lib/settings/rate_app_view.dart` (new — flat, matching `contact_view.dart` placement)
- `lib/settings/rate_app_view_model.dart` (new — flat, matching `settings_view_model.dart` placement)
- `lib/config/route_config.dart` (add `/settings/rate-app` route)
- `lib/core/ui/constants/widget_keys.dart` (add Rate App keys)
- `test/settings/rate_app_view_model_test.dart` (new)

## Approach

- **Route**: Add `/settings/rate-app` as a flat `RouteEntry(path: '/settings/rate-app', ...)` mirroring the `/settings/contact` pattern in `route_config.dart`. NOT a nested child route. `requiresAuth: true`, no bottom nav shell.
- **File placement**: New files placed flat in `lib/settings/` (matching `contact_view.dart`, `settings_view_model.dart`). NOT in subdirectories `views/` or `view_models/`.

### RateAppView
- StatelessWidget or StatefulWidget depending on state needs.
- Layout: `Scaffold` with `AppBar` (close button top-right, no title), body is a centered column
- **Close button**: Uses `locator<RouterService>().back()` — same pattern as `ContactView` (`lib/settings/contact_view.dart:36`). NOT `Navigator.pop()`.
- Neurostack logo: same asset used in the main menu / splash
- Title: "Enjoying Neurostack?" — use `Theme.of(context).textTheme` heading style
- Body text: "Your feedback helps improve the app and reach more people who can benefit from evidence-based wellness protocols."
- Primary CTA: "Rate on App Store" — enabled when `viewModel.canOpenStoreListing`, calls `viewModel.openStoreListing()`. Disabled with explanatory text when `!canOpenStoreListing`.
- Secondary CTA: "Quick Rating" — enabled when `viewModel.isServiceInitialized`, calls `viewModel.requestReviewForScreen()`. Hidden/disabled when `!isServiceInitialized`.
- Button styling: Check if `AppPrimaryCta` supports custom icons. If it hardcodes an arrow icon, use a custom styled button matching the design system.
- Use `AppSemanticColors`, `AppSpacing` — no raw `kitColors`

### RateAppViewModel — CTA state model

The ViewModel exposes three distinct states for button enablement:

```dart
/// Native in_app_review service is available (iOS/Android only)
bool get isServiceInitialized => _inAppReviewService.isInitialized;

/// Fallback store URL can be constructed from env config for current platform
bool get hasFallbackStoreConfig => _resolvedStoreUrl != null;

/// Primary CTA enabled: native path OR fallback URL available
bool get canOpenStoreListing => isServiceInitialized || hasFallbackStoreConfig;
```

**Why three states**: `isServiceInitialized` and `hasFallbackStoreConfig` are independent. On Android with service initialized but no `PLAY_STORE_PACKAGE_NAME`, the primary CTA must remain enabled (native path works). On web with `PLAY_STORE_PACKAGE_NAME` but no service, fallback URL works. Both false → CTA disabled.

### Fallback URL platform mapping

Resolved at construction time and cached as `_resolvedStoreUrl` (nullable):
- **Apple platforms** (`iOS`, `macOS`): `https://apps.apple.com/app/id<APP_STORE_ID>` — requires `APP_STORE_ID`
- **All other platforms** (`Android`, `web`, `Windows`, `Linux`, `Fuchsia`): `https://play.google.com/store/apps/details?id=<PLAY_STORE_PACKAGE_NAME>` — requires `PLAY_STORE_PACKAGE_NAME`

If the required config for the current platform is empty, `_resolvedStoreUrl` is null.

### RateAppViewModel constructor and test seams:
- Injects `InAppReviewService` and `NotifyService`
- `String appStoreId` / `String playStorePackageName` — constructor params with compile-time defaults (`const String.fromEnvironment(...)`). Tests inject explicit values to exercise config combinations.
- `Future<bool> Function(Uri, {LaunchMode mode})? launch` — defaults to `launchUrl`. Injectable for unit testing (mirrors `SettingsViewModel` at `lib/settings/settings_view_model.dart:32`).

### Methods:
- `Future<void> openStoreListing()`:
  - If `isServiceInitialized` → delegate to `_inAppReviewService.openStoreListing()`
  - Else if `hasFallbackStoreConfig` → launch `_resolvedStoreUrl` via `url_launcher`. On failure: show toast via `NotifyService`.
  - Else → no-op (CTA should be disabled by view)
- `Future<void> requestReviewForScreen()` → delegates to `InAppReviewService.requestReviewForScreen()`
- Widget keys: Add keys to `widget_keys.dart`

## Key context

- Close button uses `locator<RouterService>().back()` — this app uses a custom `RouterService`, NOT GoRouter or `Navigator.pop()`
- Both buttons always visible on supported platforms regardless of threshold state (decision: simpler UX)
- "Quick Rating" is independent from the programmatic threshold tracker
- `requestReview()` may silently do nothing — that's expected, no error to show
- `openStoreListing()` failure on native → error toast (handled by service). Fallback URL failure → toast (handled by ViewModel).
- `url_launcher` fallback lives in `RateAppViewModel` — service stays platform-agnostic
- `SettingsViewModel.openSubscriptionManagement` swallows launch failures — this ViewModel improves on that by surfacing failures via toast

## Acceptance
- [ ] `RateAppView` created at `lib/settings/rate_app_view.dart` (flat)
- [ ] `RateAppViewModel` created at `lib/settings/rate_app_view_model.dart` (flat)
- [ ] Route `/settings/rate-app` added as flat `RouteEntry` in `route_config.dart`
- [ ] Route has `requiresAuth: true`, no bottom nav
- [ ] Screen has: logo, title, body text, primary + secondary CTAs, close button
- [ ] Close button uses `locator<RouterService>().back()` (NOT `Navigator.pop()`)
- [ ] ViewModel exposes: `isServiceInitialized`, `hasFallbackStoreConfig`, `canOpenStoreListing`
- [ ] Primary CTA enabled when `canOpenStoreListing` (native OR fallback)
- [ ] Primary CTA disabled with explanatory text when `!canOpenStoreListing`
- [ ] Secondary CTA hidden/disabled when `!isServiceInitialized`
- [ ] `openStoreListing()` dispatches: native service if initialized, else fallback URL if available
- [ ] Fallback URL mapping: Apple platforms → App Store URL, all others → Play Store URL
- [ ] macOS + `APP_STORE_ID` → App Store URL works
- [ ] Android + service initialized + no `PLAY_STORE_PACKAGE_NAME` → primary CTA enabled (native path)
- [ ] ViewModel injects `NotifyService`; shows toast on fallback launch failure
- [ ] Uses `AppSemanticColors`, `AppSpacing` — no raw color values
- [ ] Widget keys added to `widget_keys.dart`
- [ ] Tests: `isServiceInitialized`, `hasFallbackStoreConfig`, `canOpenStoreListing` state combinations
- [ ] Tests: fallback URL for iOS/macOS (App Store) and Android/web/desktop (Play Store)
- [ ] Tests: Android + initialized + no PLAY_STORE_PACKAGE_NAME → CTA enabled
- [ ] Tests: missing fallback config → CTA disabled, no crash
- [ ] Tests: fallback launch failure → toast via `NotifyService`
- [ ] `flutter analyze` passes

## Done summary
Created RateAppView screen, RateAppViewModel with three-state CTA model (isServiceInitialized, hasFallbackStoreConfig, canOpenStoreListing), platform-aware fallback URL resolution (Apple -> App Store, web/others -> Play Store), and /settings/rate-app route. Added 27 unit tests covering all state combinations, dispatch logic, and failure modes.
## Evidence
- Commits: 643f53a, 50f4b2c, bf4bf67
- Tests: flutter test test/settings/rate_app_view_model_test.dart, flutter analyze
- PRs: