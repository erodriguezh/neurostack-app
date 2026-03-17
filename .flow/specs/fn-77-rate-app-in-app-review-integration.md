# Rate App / In-App Review Integration

> **Authoritative source**: This `.flow/specs/` file is the authoritative design spec. `docs/specs/202603162012_spec_rate_app_integration.md` is stale until task 4 (documentation) lands and rewrites it.

## Overview

Add in-app review functionality using the `in_app_review` Flutter package. Two flows:

1. **Programmatic** — silently call `requestReview()` after the user logs their 5th, 15th, or 35th session (counted from synced + pending local sessions). Triggered ~2 seconds after the log session modal closes (i.e., after `await showLogSessionModal()` returns, NOT inside `onSessionLogged` which fires pre-dismiss).
2. **Manual** — Settings "Rate the App" tile navigates to a dedicated Rate App screen with two CTAs: "Rate on App Store" (`openStoreListing()`) and "Quick Rating" (`requestReviewForScreen()`).

## Architecture

### InAppReviewService

- Location: `lib/core/utils/in_app_review/in_app_review_service.dart`
- Pattern: follows `UserOrientService` (`lib/core/utils/userorient/userorient_service.dart`)
  - Plain class, `Logger` instance
  - `_isInitialized` boolean guard — all public methods no-op when false
  - `init()` with platform guard (`kIsWeb` → return, non-iOS/Android → return)
  - Lazy singleton in `locator_config.dart`
  - `init()` called in `StartupViewModel.initializeApp()` wrapped in try/catch

### Test seam

The static `InAppReview.instance` singleton is not directly mockable. Introduce a thin adapter interface:

```dart
abstract class InAppReviewAdapter {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing({String? appStoreId});
}
```

Default implementation delegates to `InAppReview.instance`. `InAppReviewService` takes this adapter as a constructor dependency, enabling full unit test coverage via mock adapter.

**Note on Android**: The `in_app_review` package auto-detects the Android package name from the manifest — no explicit parameter needed for `openStoreListing()` on Android. The `appStoreId` parameter is iOS-only. `PLAY_STORE_PACKAGE_NAME` env config is used exclusively by `RateAppViewModel` for the `url_launcher` fallback URL construction on unsupported platforms.

### Platform detection

`kIsWeb` is compile-time and cannot be swapped in VM tests. Abstract platform detection behind an injectable helper or use `defaultTargetPlatform` (which IS swappable via `debugDefaultTargetPlatformOverride` in tests) for the iOS/Android guard. The `kIsWeb` guard is a compile-time early return that does not need a dedicated unit test — test non-mobile guard via `debugDefaultTargetPlatformOverride`.

### Constructor dependencies

```dart
InAppReviewService({
  required SharedPreferences prefs,
  required NotifyService notifyService,
  required InAppReviewAdapter adapter,
  String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
  String playStorePackageName = const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
})
```

- `SharedPreferences` — review-request index persistence
- `NotifyService` — error toasts when `openStoreListing()` fails
- `InAppReviewAdapter` — test seam for the `in_app_review` plugin
- `appStoreId` / `playStorePackageName` — config values with compile-time defaults. Tests inject explicit values to exercise present/missing config combinations. Production uses defaults (`const String.fromEnvironment(...)`).

### Public contract (locked — tasks 2 and 3 depend on this)

```dart
class InAppReviewService {
  void init();
  bool get isInitialized;
  Future<void> requestReviewIfNeeded(int sessionCount, String userId);
  Future<void> requestReviewForScreen();
  Future<void> openStoreListing();
}
```

- `isInitialized` — exposed getter for `RateAppViewModel` conditional UI
- All public methods no-op when `!isInitialized`
- All public async methods wrapped in try/catch — failures are non-critical

### Key methods

- `init()` — guards on platform + reads env config via `const String.fromEnvironment('APP_STORE_ID')` and `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')` (matching existing codebase pattern, NOT `AppEnvironment`)
- `requestReviewIfNeeded(int sessionCount, String userId)` — programmatic flow: checks session count against thresholds `[5, 15, 35]`, reads review-request index from SharedPreferences, calls `adapter.requestReview()` if threshold crossed, increments index. All wrapped in try/catch. Silent on failure.
- `requestReviewForScreen()` — manual flow (Rate App screen): try `adapter.requestReview()`, on failure auto-fallback to `openStoreListing()`.
- `openStoreListing()` — calls `adapter.openStoreListing(appStoreId: ...)`. On failure, shows error toast via `NotifyService`.

### Session count source — race condition mitigation

**Problem**: In `LogSessionViewModel.submit()`, `savePendingSession()` is followed by `unawaited(_sessionSyncService.sync())` BEFORE the modal dismisses (line 269 of `log_session_view_model.dart`). By the time `await showLogSessionModal()` returns, sync may have already moved the session from pending to synced storage — or be mid-flight, causing potential double-count.

**Callback contract constraint**: `showLogSessionModal` takes `void Function(Session session)` as `onSessionLogged` — the callback is synchronous (`void` return), so async work inside it cannot be awaited by the modal flow. Any `Future` started inside the callback runs fire-and-forget relative to the modal.

**Solution**: Start the session count capture as a `Future<int>` inside `onSessionLogged` (fire-and-forget from the modal's perspective), then `await` that future after `showLogSessionModal()` returns:

```dart
Future<int>? sessionCountFuture;

await showLogSessionModal(
  context,
  protocol: ...,
  userId: userId,
  onSessionLogged: (session) {
    // Fire-and-forget from modal's POV, but we hold the Future
    sessionCountFuture = locator<ReviewTriggerHelper>().captureSessionCount(userId);
    // ... existing callback work (refresh, etc.)
  },
);

// Modal dismissed — now safely await the future we started in callback
if (sessionCountFuture != null) {
  try {
    final count = await sessionCountFuture!;
    await locator<ReviewTriggerHelper>().triggerReviewIfNeeded(count, userId);
  } catch (_) {
    // Non-critical
  }
}
```

This works because:
1. `captureSessionCount` is initiated in the callback (at the safe snapshot point, before sync moves data)
2. The `Future<int>` runs concurrently with modal dismiss
3. After modal dismiss, we `await` the already-in-flight future — by then it's likely completed
4. No changes needed to the `showLogSessionModal` callback contract

### Review-request index persistence

- SharedPreferences key: `'review_request_index_<userId>'`
- Value: int (0, 1, 2, or 3) — index into `[5, 15, 35]` thresholds
- 0 = no prompts shown yet, 3 = all thresholds exhausted
- Follows `TrialReminderService` key pattern (`lib/paywall/data/trial_reminder_service.dart`)
- Default 0 on fresh install / missing key
- Survives logout (intentional — same user, same history)

### Programmatic trigger flow (revised)

1. User logs session → `onSessionLogged` callback fires (pre-dismiss, sync just scheduled)
2. **In `onSessionLogged`**: start `sessionCountFuture = helper.captureSessionCount(userId)` — fire-and-forget from modal's perspective (callback is `void Function`), but caller holds the `Future<int>`
3. Existing callback work continues (refresh, etc.)
4. Modal closes via `Navigator.pop()`
5. `await showLogSessionModal()` returns (modal fully dismissed)
6. `await sessionCountFuture` — resolves with snapshot captured at step 2
7. `await Future.delayed(Duration(seconds: 2))` (so success toast is visible first)
8. Call `InAppReviewService.requestReviewIfNeeded(count, userId)`
9. Service checks threshold, fires `requestReview()` if eligible, increments index
10. All wrapped in try/catch — non-critical, app works without it

### Shared review trigger helper

To avoid duplicating the post-modal trigger logic in both HomeView and ProgressView, extract a single shared helper:

```dart
/// lib/core/utils/in_app_review/review_trigger_helper.dart
class ReviewTriggerHelper {
  ReviewTriggerHelper({
    required SessionLocalDataSource sessionLocalDataSource,
    required InAppReviewService inAppReviewService,
  });

  /// Captures session count from local stores. Call from onSessionLogged
  /// (before sync moves data between stores).
  /// Returns a Future<int> — caller stores it and awaits after modal dismiss.
  Future<int> captureSessionCount(String userId) async {
    final results = await Future.wait([
      _sessionLocalDataSource.getSyncedSessions(userId),
      _sessionLocalDataSource.getPendingSessions(userId),
    ]);
    return results[0].length + results[1].length;
  }

  /// Call after modal dismiss with the previously captured count.
  /// Delays 2s (so success toast is visible), then triggers review.
  Future<void> triggerReviewIfNeeded(int sessionCount, String userId) async {
    await Future.delayed(const Duration(seconds: 2));
    await _inAppReviewService.requestReviewIfNeeded(sessionCount, userId);
  }
}
```

Both HomeView and ProgressView: start `captureSessionCount` in `onSessionLogged` (store `Future<int>`), then after modal dismiss: `await` the future, pass result to `triggerReviewIfNeeded`. Single implementation, tested once.

### Manual flow (Rate App screen)

- Route: `/settings/rate-app` — flat `RouteEntry(path: '/settings/rate-app', ...)` mirroring `/settings/contact` pattern in `route_config.dart`. NOT a nested child route. `requiresAuth: true`, no bottom nav.
- **Navigation**: Uses `RouterService` — NOT GoRouter or `Navigator.pop()`. Close button calls `locator<RouterService>().back()` (same pattern as `ContactView` at `lib/settings/contact_view.dart:36`).
- Neurostack logo (same asset as main menu) centered in upper area
- Title: "Enjoying Neurostack?"
- Body: "Your feedback helps improve the app and reach more people who can benefit from evidence-based wellness protocols."
- Primary CTA: "Rate on App Store" → `openStoreListing()`
- Secondary CTA: "Quick Rating" → `requestReviewForScreen()` (try requestReview, fallback to openStoreListing)
- Both buttons always visible (even after 3 thresholds exhausted — simpler)
- "Quick Rating" does NOT count against the programmatic threshold tracker (independent flows)
- Button styling: `AppPrimaryCta` may need icon configurability (currently hardcodes arrow). If not feasible, use a custom styled button matching the design system for this screen only.

### File placement for Rate App screen

New files follow the existing flat Settings module structure (matching `contact_view.dart`, `settings_view_model.dart`):
- `lib/settings/rate_app_view.dart` (NOT `lib/settings/views/`)
- `lib/settings/rate_app_view_model.dart` (NOT `lib/settings/view_models/`)

This is consistent with the current flat layout where `contact_view.dart` and `settings_view_model.dart` live directly in `lib/settings/`.

### RateAppViewModel constructor

```dart
RateAppViewModel({
  required InAppReviewService inAppReviewService,
  required NotifyService notifyService,
  String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
  String playStorePackageName = const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
  Future<bool> Function(Uri, {LaunchMode mode})? launch,
})
```

- `launch` defaults to `launchUrl` — injectable for unit testing (mirrors `SettingsViewModel` pattern at `lib/settings/settings_view_model.dart:32`)
- `appStoreId` / `playStorePackageName` — config with compile-time defaults. Tests inject explicit values.

### RateAppViewModel CTA state model

The ViewModel exposes three distinct states for the view to determine button enablement:

```dart
/// Native in_app_review service is available (iOS/Android only)
bool get isServiceInitialized => _inAppReviewService.isInitialized;

/// Fallback store URL can be constructed from env config
bool get hasFallbackStoreConfig => _resolvedStoreUrl != null;

/// Primary CTA enabled: native path OR fallback URL available
bool get canOpenStoreListing => isServiceInitialized || hasFallbackStoreConfig;
```

**State matrix:**

| Platform | Service init | Fallback config | Primary CTA | Secondary CTA |
|----------|-------------|-----------------|-------------|---------------|
| iOS (config present) | true | true | Enabled (native) | Enabled |
| iOS (config missing) | false | false | **Disabled** | **Disabled** |
| Android | true | maybe | Enabled (native) | Enabled |
| Android (no PLAY_STORE_PACKAGE_NAME) | true | false | Enabled (native) | Enabled |
| Web/Desktop (config present) | false | true | Enabled (fallback URL) | **Disabled** |
| Web/Desktop (no config) | false | false | **Disabled** | **Disabled** |
| macOS (APP_STORE_ID present) | false | true | Enabled (App Store URL) | **Disabled** |

### Fallback URL platform mapping

The ViewModel determines which store URL to construct based on `defaultTargetPlatform`:

- **Apple platforms** (`iOS`, `macOS`): `https://apps.apple.com/app/id<APP_STORE_ID>` — requires `APP_STORE_ID`
- **All other platforms** (`Android`, `web`, `Windows`, `Linux`, `Fuchsia`): `https://play.google.com/store/apps/details?id=<PLAY_STORE_PACKAGE_NAME>` — requires `PLAY_STORE_PACKAGE_NAME`

The ViewModel resolves this at construction time and caches `_resolvedStoreUrl` (nullable). If the required config for the current platform is empty, `_resolvedStoreUrl` is null and `hasFallbackStoreConfig` returns false.

### Unsupported platform behavior (web/desktop)

The "Rate the App" tile is visible on all platforms. On unsupported platforms where `isInitialized` is false:
- Rate App screen still navigable (tile always visible)
- "Rate on App Store" → enabled only when `canOpenStoreListing` is true:
  - If `isServiceInitialized`: delegates to native service
  - Else if `hasFallbackStoreConfig`: launches `_resolvedStoreUrl` via `url_launcher`
  - Else: CTA disabled, explanatory text shown ("Store rating not available")
- **Fallback launch failure**: If `url_launcher` throws or returns false, show error toast via `NotifyService` (inject `NotifyService` into `RateAppViewModel`).
- "Quick Rating" button → hidden or disabled when `!isServiceInitialized` (since `requestReview()` is impossible on web/desktop)
- `InAppReviewService` stays platform-agnostic — no `url_launcher` dependency. Fallback lives in `RateAppViewModel`.

### Env config

- `APP_STORE_ID` — Apple App Store numeric ID, read via `const String.fromEnvironment('APP_STORE_ID')` (matching existing codebase pattern). Used by `InAppReviewService.openStoreListing()` on iOS and by `RateAppViewModel` for fallback URL on Apple platforms.
- `PLAY_STORE_PACKAGE_NAME` — Android package name, read via `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')`. Used only by `RateAppViewModel` for `url_launcher` fallback URL construction on non-Apple platforms. The `in_app_review` plugin auto-detects the Android package name from the manifest.
- Added to `env/default.env.json` with placeholder values
- **Platform-specific config validation**: `init()` only requires the config relevant to the current platform. On iOS, `APP_STORE_ID` must be present. On Android, no env config is required (package name is auto-detected). Missing iOS config on iOS → `_isInitialized = false`. Missing Android config on Android → still initializes (plugin handles it). `PLAY_STORE_PACKAGE_NAME` is never required for service initialization — it's only used by the ViewModel fallback.

### Error handling

- `requestReview()` throws → auto-fallback to `openStoreListing()` (on Rate App screen via `requestReviewForScreen()`) or silent swallow (programmatic via `requestReviewIfNeeded()`)
- `openStoreListing()` throws → error toast via `NotifyService`
- `isAvailable()` checked before `requestReview()` — if false, fallback to `openStoreListing()` on screen, skip on programmatic
- iOS 18 freeze (#147) and Android NPE (#175) mitigated by try/catch
- Missing platform-specific env config (e.g., `APP_STORE_ID` on iOS) → service stays uninitialized on that platform, all methods no-op
- **Fallback URL launch failure** (web/desktop): `RateAppViewModel` shows error toast via `NotifyService` when `url_launcher` fails
- **Missing fallback config** (web/desktop with no env config): Primary CTA disabled, explanatory text shown

### Analytics

> **Note**: Analytics events (e.g., `review_requested`, `store_listing_opened`) are deferred to a future analytics epic. Leave a `// TODO(analytics): track review prompt event` comment at trigger points.

## Dependencies

- `in_app_review` Flutter package (add to `pubspec.yaml`)
- Completed: fn-76 (UserOrient integration — pattern to follow)
- Completed: fn-73 (Settings screen — tile placeholder exists)

## Quick commands

```bash
# Verify package added
grep 'in_app_review' pubspec.yaml

# Run tests
flutter test test/core/utils/in_app_review/
flutter test test/settings/

# Analyze
flutter analyze
```

## Acceptance

- [ ] `in_app_review` package added to `pubspec.yaml`
- [ ] `InAppReviewAdapter` interface + default implementation created (test seam)
- [ ] `InAppReviewService` public contract locked: `init()`, `isInitialized` getter, `requestReviewIfNeeded()`, `requestReviewForScreen()`, `openStoreListing()`
- [ ] `InAppReviewService` follows `UserOrientService` pattern (lazy singleton, platform guard via `defaultTargetPlatform`, init guard, try/catch init in startup)
- [ ] Constructor injects `SharedPreferences`, `NotifyService`, and `InAppReviewAdapter`
- [ ] Programmatic `requestReviewIfNeeded()` fires after 5th, 15th, 35th session (synced + pending count)
- [ ] Session count capture started in `onSessionLogged` callback as `Future<int>` (fire-and-forget from modal, awaited after dismiss)
- [ ] No changes to `showLogSessionModal` callback contract (`void Function(Session)` preserved)
- [ ] ~2-second delay before programmatic trigger fires (after modal dismiss)
- [ ] Review-request index persisted in SharedPreferences (user-scoped key)
- [ ] `ReviewTriggerHelper` extracts shared trigger logic (used by both Home and Progress)
- [ ] Rate App screen accessible from Settings "Rate the App" tile
- [ ] Rate App screen has: logo, title, body text, "Rate on App Store" primary CTA, "Quick Rating" secondary CTA, close button
- [ ] Rate App screen uses `RouterService.back()` for close (NOT `Navigator.pop()`)
- [ ] Rate App files placed flat in `lib/settings/` (matching `contact_view.dart` pattern)
- [ ] "Rate on App Store" calls `openStoreListing()` with App Store ID from env config
- [ ] `openStoreListing()` passes `appStoreId` on iOS; Android auto-detected by plugin
- [ ] "Quick Rating" calls `requestReviewForScreen()` with auto-fallback to `openStoreListing()` on failure
- [ ] Route `/settings/rate-app` added as flat `RouteEntry` in `route_config.dart` (requiresAuth, no bottom nav)
- [ ] Navigation uses `RouterService.goTo(Path(name: '/settings/rate-app'))` (NOT GoRouter)
- [ ] Env config read via `const String.fromEnvironment(...)` (not AppEnvironment)
- [ ] `env/default.env.json` updated with `APP_STORE_ID` and `PLAY_STORE_PACKAGE_NAME`
- [ ] Platform-specific config validation: iOS requires `APP_STORE_ID`, Android needs nothing from env for service init
- [ ] Missing platform config → service stays uninitialized on that platform, graceful degradation
- [ ] `RateAppViewModel` exposes: `isServiceInitialized`, `hasFallbackStoreConfig`, `canOpenStoreListing`
- [ ] Primary CTA enabled when `canOpenStoreListing` (native OR fallback available)
- [ ] Android + no `PLAY_STORE_PACKAGE_NAME` + service initialized → primary CTA remains enabled (native path)
- [ ] Fallback URL mapping: Apple platforms → App Store URL, all others → Play Store URL
- [ ] Desktop platform (macOS) tested: App Store URL if `APP_STORE_ID` present
- [ ] `RateAppViewModel` injects `NotifyService` and shows toast on fallback launch failure
- [ ] `RateAppViewModel` fallback URL construction tested (iOS/macOS App Store, Android/web/desktop Play Store)
- [ ] Missing fallback config tested (CTA disabled, no crash)
- [ ] Fallback launch failure tested (toast shown)
- [ ] Callback-future orchestration integration test: Future started in onSessionLogged, awaited after dismiss, delayed trigger fires
- [ ] Screen prompt doc created at `docs/best_practices/design/screen-prompts/12-rate-app-screen.md`
- [ ] Settings screen spec and screen prompt updated (placeholder notes removed)
- [ ] `docs/specs/202603162012_spec_rate_app_integration.md` rewritten to match `.flow/specs/` (authoritative until task 4)
- [ ] `docs/README.md` updated with new links
- [ ] Screen functional specs updated with Rate App entry and metadata counts corrected
- [ ] All try/catch wrapped — feature is non-critical
- [ ] Unit tests for `InAppReviewService` threshold logic via mock `InAppReviewAdapter`
- [ ] Unit tests verify `adapter.openStoreListing(...)` called (observable behavior, not internal state)
- [ ] `flutter analyze` passes
