# Spec: Rate App / In-App Review Integration

## Purpose

Integrate the `in_app_review` Flutter package to prompt users to rate Neurostack at moments of satisfaction. Two flows: a **programmatic trigger** after session-logging milestones, and a **manual Rate App screen** accessible from Settings.

---

## Screen States

### Rate App Screen (`/settings/rate-app`)

| State | Condition | Behavior |
|-------|-----------|----------|
| Default (supported platform) | `InAppReviewService.isInitialized == true` | Both CTAs visible: "Rate on App Store" and "Quick Rating" |
| Unsupported platform (fallback available) | `isInitialized == false`, `hasFallbackStoreConfig == true` | "Rate on App Store" uses `url_launcher` fallback; "Quick Rating" hidden |
| Unsupported platform (no config) | `isInitialized == false`, `hasFallbackStoreConfig == false` | Primary CTA disabled with explanatory text; "Quick Rating" hidden |

### Programmatic Trigger

No visible UI. `requestReview()` is called silently after session-logging milestones. The native OS dialog may or may not appear (platform-controlled).

---

## User Flows

### Flow 1: Programmatic Review Prompt

1. User logs a session via the Log Session modal (from Home or Progress screen)
2. `onSessionLogged` callback fires (pre-dismiss) -- `sessionCountFuture = helper.captureSessionCount(userId)` starts as fire-and-forget from modal's perspective
3. Modal closes (`await showLogSessionModal()` returns)
4. Caller `await`s `sessionCountFuture` -- resolves with snapshot captured at step 2
5. `helper.triggerReviewIfNeeded(count, userId)` -- 2-second delay, then `requestReviewIfNeeded()`
6. Service checks threshold `[5, 15, 35]`, reads review-request index from SharedPreferences, fires `requestReview()` if eligible, increments index
7. Entire block wrapped in try/catch -- non-critical, app works without it

### Flow 2: Manual Rate App Screen

1. User navigates to **Settings** tab
2. User taps **"Rate the App"** tile (`LucideIcons.star`, `chevronRight` trailing) -- see `lib/settings/widgets/settings_support_section.dart:64-69`
3. `SettingsViewModel.goToRateApp()` navigates to `/settings/rate-app` via `RouterService`
4. Rate App screen displays logo, title, body text, two CTAs
5. **"Rate on App Store"** -- calls `RateAppViewModel.openStoreListing()`: native service if initialized, else `url_launcher` fallback with constructed store URL
6. **"Quick Rating"** -- calls `RateAppViewModel.requestReviewForScreen()`: tries `requestReview()`, auto-fallback to `openStoreListing()` on failure. Hidden on unsupported platforms.
7. Close button (top-right) -- `locator<RouterService>().back()` back to Settings

### Edge Cases

| Case | Behavior |
|------|----------|
| `requestReview()` silently no-ops (OS quota hit) | Expected -- no user feedback possible. Button still works, just invisible to user. |
| `requestReview()` throws (iOS 18 freeze #147, Android NPE #175) | Programmatic: silent swallow. Screen: auto-fallback to `openStoreListing()`. |
| `openStoreListing()` throws | Error toast via `NotifyService` |
| `isAvailable()` returns false | Programmatic: skip silently. Screen: fallback to `openStoreListing()`. |
| Missing `APP_STORE_ID` on Apple platforms (iOS/macOS) | `init()` logs warning, `_isInitialized = false`. All service methods become no-ops. Fallback URL also requires `APP_STORE_ID`, so no fallback available either -- primary CTA disabled, Quick Rating hidden. |
| Missing config on Android | Service still initializes -- `in_app_review` plugin auto-detects package name from manifest. |
| User on web/desktop | Service uninitialized. Rate App screen visible but "Quick Rating" hidden; "Rate on App Store" uses `url_launcher` fallback URL or disabled if no config. |
| Synced + pending count during sync handoff | Count snapshot captured in `onSessionLogged` callback (before sync moves data) as a `Future<int>`, awaited after modal dismiss. |
| Fresh install (no SharedPreferences) | Review-request index defaults to 0 -- first threshold is 5 sessions. |
| User reinstalls app | SharedPreferences wiped, index resets to 0. Sessions re-sync from remote. Next uncrossed threshold fires. |
| All 3 thresholds exhausted | Programmatic trigger stops. Screen buttons remain visible (simpler UX). |
| Fallback URL launch failure (web/desktop) | `RateAppViewModel` shows error toast via `NotifyService`. |
| Missing fallback config (web/desktop, no env config) | Primary CTA disabled, explanatory text shown ("Store rating not available"). |

---

## Architecture

### InAppReviewAdapter (test seam)

- **Location:** `lib/core/utils/in_app_review/in_app_review_adapter.dart`
- Abstract class wrapping `InAppReview.instance` static singleton for testability
- Methods: `isAvailable()`, `requestReview()`, `openStoreListing({String? appStoreId})`
- `DefaultInAppReviewAdapter` delegates to `InAppReview.instance`
- Android note: `openStoreListing()` auto-detects package name from manifest -- `appStoreId` param is iOS-only

### InAppReviewService

- **Location:** `lib/core/utils/in_app_review/in_app_review_service.dart`
- **Pattern:** follows `UserOrientService` -- plain class, `Logger`, `_isInitialized` guard, platform guard, lazy singleton
- **Constructor dependencies:**
  - `SharedPreferences` -- review-request index persistence
  - `NotifyService` -- error toasts on `openStoreListing()` failure
  - `InAppReviewAdapter` -- test seam
  - `appStoreId` / `playStorePackageName` -- compile-time env defaults via `const String.fromEnvironment(...)`
- **Methods:**
  - `void init()` -- guards `kIsWeb` (compile-time), `defaultTargetPlatform` (testable via `debugDefaultTargetPlatformOverride`). Platform-specific validation: iOS requires `APP_STORE_ID`, Android needs nothing.
  - `bool get isInitialized` -- exposed for `RateAppViewModel` conditional UI
  - `Future<void> requestReviewIfNeeded(int sessionCount, String userId)` -- programmatic flow. Checks `thresholds[index]`, calls `adapter.requestReview()`, increments index. Silent on failure.
  - `Future<void> requestReviewForScreen()` -- manual flow. Try `adapter.requestReview()`, on failure auto-fallback to `openStoreListing()`.
  - `Future<void> openStoreListing()` -- calls `adapter.openStoreListing(appStoreId: ...)`. On failure, shows error toast via `NotifyService`.

### ReviewTriggerHelper

- **Location:** `lib/core/utils/in_app_review/review_trigger_helper.dart`
- **Purpose:** Shared helper for post-session programmatic review trigger, used by both HomeView and ProgressView
- **Constructor dependencies:**
  - `SessionLocalDataSource` -- for session count snapshot
  - `InAppReviewService` -- for review prompt
- **Methods:**
  - `Future<int> captureSessionCount(String userId)` -- `Future.wait` on `getSyncedSessions` + `getPendingSessions`, returns total count. Called from `onSessionLogged` callback.
  - `Future<void> triggerReviewIfNeeded(int sessionCount, String userId)` -- 2-second delay, then `requestReviewIfNeeded()`. Called after modal dismiss.

### RateAppViewModel

- **Location:** `lib/settings/rate_app_view_model.dart`
- **Pattern:** follows `SettingsViewModel`
- **Constructor dependencies:**
  - `InAppReviewService` -- native review/store listing actions
  - `NotifyService` -- error toasts on fallback launch failure
  - `appStoreId` / `playStorePackageName` -- compile-time env defaults
  - `launch` -- injectable `launchUrl` function for testing (defaults to `url_launcher.launchUrl`)
- **CTA state model:**
  - `isServiceInitialized` -- native `in_app_review` available (iOS/Android)
  - `hasFallbackStoreConfig` -- fallback URL constructible from env config
  - `canOpenStoreListing` -- native OR fallback available
- **Fallback URL mapping** (resolved at construction time):
  - Web: always Play Store URL (host platform detection unreliable)
  - Apple platforms (iOS, macOS): `https://apps.apple.com/app/id<APP_STORE_ID>`
  - All others: `https://play.google.com/store/apps/details?id=<PLAY_STORE_PACKAGE_NAME>`

### RateAppView

- **Location:** `lib/settings/rate_app_view.dart`
- `AppGridBackground(mode: adaptive)` > `Scaffold` (transparent, no AppBar) > `SafeArea` > Column
- Close button: `IconButton(Icons.close)` in `Align(topRight)`, calls `locator<RouterService>().back()`
- Body: centered column with logo, title, body text, primary/secondary CTAs
- Uses `AppSemanticColors`, `AppSpacing`, `context.borderRadius`

### Registration & Init

- **DI:** `lib/config/locator_config.dart` -- lazy `Module<InAppReviewService>` and `Module<ReviewTriggerHelper>`
- **Startup:** `lib/startup/startup_view_model.dart` -- `init()` called after UserOrient init, wrapped in try/catch

### Route

- **Config:** `lib/config/route_config.dart` -- flat `RouteEntry(path: '/settings/rate-app', ...)` mirroring `/settings/contact`. `requiresAuth: true`, no bottom nav.

### Review-Request Index Persistence

- SharedPreferences key: `'review_request_index_<userId>'`
- Value: int (0-3) -- index into `[5, 15, 35]` thresholds
- Default 0 on missing key. Survives logout (intentional).
- Pattern: follows `TrialReminderService`

---

## API Contracts

### InAppReviewAdapter

```dart
abstract class InAppReviewAdapter {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing({String? appStoreId});
}
```

### InAppReviewService

```dart
class InAppReviewService {
  InAppReviewService({
    required SharedPreferences prefs,
    required NotifyService notifyService,
    required InAppReviewAdapter adapter,
    String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
    String playStorePackageName = const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
  });

  void init();
  bool get isInitialized;
  Future<void> requestReviewIfNeeded(int sessionCount, String userId);
  Future<void> requestReviewForScreen();
  Future<void> openStoreListing();
}
```

### ReviewTriggerHelper

```dart
class ReviewTriggerHelper {
  ReviewTriggerHelper({
    required SessionLocalDataSource sessionLocalDataSource,
    required InAppReviewService inAppReviewService,
  });

  Future<int> captureSessionCount(String userId);
  Future<void> triggerReviewIfNeeded(int sessionCount, String userId);
}
```

### RateAppViewModel

```dart
class RateAppViewModel {
  RateAppViewModel({
    required InAppReviewService inAppReviewService,
    required NotifyService notifyService,
    String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
    String playStorePackageName = const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  });

  bool get isServiceInitialized;
  bool get hasFallbackStoreConfig;
  bool get canOpenStoreListing;
  Future<void> openStoreListing();
  Future<void> requestReviewForScreen();
}
```

---

## Environment

- `APP_STORE_ID` -- Apple App Store numeric ID. Read via `const String.fromEnvironment('APP_STORE_ID')`. Required on iOS for `openStoreListing()`. Also used by `RateAppViewModel` for fallback URL on Apple platforms.
- `PLAY_STORE_PACKAGE_NAME` -- Android package name. Read via `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')`. Used only by `RateAppViewModel` for `url_launcher` fallback URL. Plugin auto-detects from manifest.
- **Template:** `env/default.env.json` -- both keys with placeholder values
- **Runtime:** passed via `--dart-define-from-file=env/env.json`

---

## Dependencies

- `in_app_review` -- [pub.dev](https://pub.dev/packages/in_app_review)
- Existing: `shared_preferences`, `url_launcher` (already in dependency tree)

---

## Data Requirements

- `SessionLocalDataSource.getSyncedSessions(userId)` -- synced session list
- `SessionLocalDataSource.getPendingSessions(userId)` -- pending session list
- `CachedUserStore.loadUser()` -- for userId
- `SharedPreferences` -- review-request index

---

## UI Specification

See: [`docs/best_practices/design/screen-prompts/12-rate-app-screen.md`](../best_practices/design/screen-prompts/12-rate-app-screen.md)

---

## Acceptance Criteria

- [ ] `InAppReviewAdapter` interface + `DefaultInAppReviewAdapter` created (test seam)
- [ ] `InAppReviewService` public contract: `init()`, `isInitialized`, `requestReviewIfNeeded()`, `requestReviewForScreen()`, `openStoreListing()`
- [ ] Service follows `UserOrientService` pattern (lazy singleton, platform guard, init guard, try/catch init in startup)
- [ ] Constructor injects `SharedPreferences`, `NotifyService`, and `InAppReviewAdapter`
- [ ] Programmatic `requestReviewIfNeeded()` fires after 5th, 15th, 35th session (synced + pending count)
- [ ] Session count capture started in `onSessionLogged` callback as `Future<int>`, awaited after modal dismiss
- [ ] 2-second delay before programmatic trigger (after modal dismiss)
- [ ] Review-request index persisted in SharedPreferences (user-scoped key)
- [ ] `ReviewTriggerHelper` extracts shared trigger logic (used by both Home and Progress)
- [ ] Rate App screen accessible from Settings tile, uses `RouterService.back()` for close
- [ ] Rate App screen has logo, title, body text, primary/secondary CTAs
- [ ] `RateAppViewModel` exposes `isServiceInitialized`, `hasFallbackStoreConfig`, `canOpenStoreListing`
- [ ] Primary CTA: native service if initialized, else `url_launcher` fallback, else disabled
- [ ] Secondary CTA: hidden when `!isServiceInitialized`
- [ ] Fallback URL: Apple platforms use App Store URL, all others use Play Store URL
- [ ] Missing `APP_STORE_ID` on Apple platforms: service uninitialized AND no fallback URL (CTA disabled)
- [ ] Fallback launch failure shows error toast via `NotifyService`
- [ ] Route `/settings/rate-app` as flat `RouteEntry`, `requiresAuth: true`, no bottom nav
- [ ] All try/catch wrapped -- feature is non-critical
- [ ] Unit tests for threshold logic, fallback URL construction, and CTA state model

---

## Out of Scope

- Analytics events (deferred to future analytics epic -- leave `// TODO(analytics)` comments)
- Cooldown timer between prompts (thresholds are sufficient)
- Server-side review-request tracking (SharedPreferences local-only for now)
- "Quick Rating" counting against the programmatic threshold tracker (independent flows)
- Web/desktop native review support (service is inert, fallback to `url_launcher`)

---

## Appendix: Best Practices Research

> The original research notes that informed this spec are preserved below.

- Ask after a positive milestone (session logged = delight event)
- Do not ask too early -- thresholds at 5, 15, 35 sessions ensure repeated engagement
- Use native `requestReview()` for programmatic prompts, `openStoreListing()` for user-initiated
- Base timing on data (session count), not guesses
- Respect platform quotas (iOS: 3/year, Android: ~monthly) -- our 3 thresholds align with iOS limit
- Persist review-request history in SharedPreferences to prevent re-asking
- Separate reviews (Rate App screen) from feedback (Feature Request tile via UserOrient)
