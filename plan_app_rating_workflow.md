# Implementation Plan: Rate App / In-App Review Integration

**Spec (authoritative):** `.flow/specs/fn-77-rate-app-in-app-review-integration.md`
**Spec (stale — superseded until task 4 rewrites):** `docs/specs/202603162012_spec_rate_app_integration.md`
**UI Design:** Rate App screen (new) + Settings tile wiring (existing placeholder)

---

## Phase 1 — Add Package & Environment Config

### 1.1 Add `in_app_review` dependency

- **File:** `pubspec.yaml`
- Add `in_app_review` under `dependencies`
- Run `flutter pub get` — verify no version conflicts

### 1.2 Add env config keys

- **File:** `env/default.env.json`
- Add `"APP_STORE_ID": "<Apple App Store numeric ID>"` — required on iOS for `openStoreListing()`
- Add `"PLAY_STORE_PACKAGE_NAME": "<com.yourcompany.neurostack>"` — used only by `RateAppViewModel` for `url_launcher` fallback URL; plugin auto-detects from manifest on Android
- Pattern: matches existing `REVENUECAT_API_KEY` placeholder style (see `env/default.env.json:4`)
- Developer must also add real values to their local `env/env.json` (gitignored)

---

## Phase 2 — Create `InAppReviewAdapter` (Test Seam), `InAppReviewService` & `ReviewTriggerHelper`

### 2.1 Create the adapter interface

- **File:** `lib/core/utils/in_app_review/in_app_review_adapter.dart` (new)
- Abstract class wrapping `InAppReview.instance` — enables unit testing without static singleton
- Methods:
  - `Future<bool> isAvailable()`
  - `Future<void> requestReview()`
  - `Future<void> openStoreListing({String? appStoreId})`
- `DefaultInAppReviewAdapter` — default implementation delegating to `InAppReview.instance`
- `appStoreId` param is iOS-only; Android plugin auto-detects package name from manifest

### 2.2 Create the service

- **File:** `lib/core/utils/in_app_review/in_app_review_service.dart` (new)
- Pattern: follows `UserOrientService` (`lib/core/utils/userorient/userorient_service.dart`) — plain class, `Logger`, `_isInitialized` guard
- Constructor dependencies:
  - `SharedPreferences` — review-request index (follows `TrialReminderService` at `lib/paywall/data/trial_reminder_service.dart` for key pattern)
  - `NotifyService` — error toasts on `openStoreListing()` failure (see `lib/core/utils/internal_notification/notify_service.dart`)
  - `InAppReviewAdapter` — test seam from Phase 2.1
  - `String appStoreId` — defaults to `const String.fromEnvironment('APP_STORE_ID')`. Tests inject explicit values.
  - `String playStorePackageName` — defaults to `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')`. Tests inject explicit values.
- **Config testability**: `const String.fromEnvironment(...)` is compile-time and cannot be varied per unit test. Constructor params with defaults enable tests to exercise present/missing config combinations without `--dart-define`.
- **Public contract (locked — tasks 2 and 3 depend on this):**
  - `void init()`
  - `bool get isInitialized`
  - `Future<void> requestReviewIfNeeded(int sessionCount, String userId)`
  - `Future<void> requestReviewForScreen()`
  - `Future<void> openStoreListing()`
- `void init()`:
  - Compile-time guard: `kIsWeb` → return early
  - Runtime guard: `defaultTargetPlatform` (swappable in tests via `debugDefaultTargetPlatformOverride`) — non-iOS/Android → return early
  - Read env config via `const String.fromEnvironment('APP_STORE_ID')` and `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')` — NOT `AppEnvironment` (matching existing codebase pattern)
  - Platform-specific validation: on iOS, require `APP_STORE_ID` — if empty, log warning, keep `_isInitialized = false`. On Android, no env config required (plugin handles it).
  - Set `_isInitialized = true` on success
- `Future<void> requestReviewIfNeeded(int sessionCount, String userId)`:
  - Guard `_isInitialized`
  - Read review-request index from SharedPreferences key `'review_request_index_<userId>'` (default 0)
  - Thresholds: `[5, 15, 35]` — if `index >= thresholds.length`, return (exhausted)
  - If `sessionCount >= thresholds[index]`: call `adapter.isAvailable()`, then `adapter.requestReview()`, increment index in SharedPreferences
  - All wrapped in try/catch — silent on failure
  - Add `// TODO(analytics): track review prompt event`
- `Future<void> requestReviewForScreen()`:
  - Guard `_isInitialized`
  - Try `adapter.isAvailable()` → `adapter.requestReview()`
  - On failure: auto-fallback to `openStoreListing()`
- `Future<void> openStoreListing()`:
  - Guard `_isInitialized`
  - Call `adapter.openStoreListing(appStoreId: _appStoreId)`
  - On failure: show error toast via `NotifyService.setToastEvent(ToastEventError(...))` (see `lib/core/utils/internal_notification/toast/toast_event.dart`)

### 2.3 Create ReviewTriggerHelper

- **File:** `lib/core/utils/in_app_review/review_trigger_helper.dart` (new)
- Shared helper used by both HomeView and ProgressView — eliminates logic duplication
- Constructor deps: `SessionLocalDataSource`, `InAppReviewService`
- `Future<int> captureSessionCount(String userId)` — queries synced + pending sessions via `Future.wait`, returns total count. Called from `onSessionLogged` callback (at safe snapshot point before sync moves data).
- `Future<void> triggerReviewIfNeeded(int sessionCount, String userId)` — delays 2s (so success toast is visible), then calls `requestReviewIfNeeded(sessionCount, userId)`.

### 2.4 Add mocks

- **File:** `test/mocks/mock_services.dart`
- Add `MockInAppReviewService` and `MockInAppReviewAdapter` (mocktail mocks)
- Follows existing mock pattern in the file

---

## Phase 3 — Register in DI & Wire Startup Init

### 3.1 Register services in locator

- **File:** `lib/config/locator_config.dart`
- Add `Module<InAppReviewService>` as lazy singleton near `UserOrientService` registration (~line 186):
  ```
  Module<InAppReviewService>(
    builder: () => InAppReviewService(
      prefs: locator<SharedPreferences>(),
      notifyService: locator<NotifyService>(),
      adapter: DefaultInAppReviewAdapter(),
    ),
    lazy: true,
  ),
  ```
- Add `Module<ReviewTriggerHelper>` as lazy singleton:
  ```
  Module<ReviewTriggerHelper>(
    builder: () => ReviewTriggerHelper(
      sessionLocalDataSource: locator<SessionLocalDataSource>(),
      inAppReviewService: locator<InAppReviewService>(),
    ),
    lazy: true,
  ),
  ```

### 3.2 Initialize at app startup

- **File:** `lib/startup/startup_view_model.dart`
- Call `init()` after UserOrient init (~line 89), before auth init:
  ```
  try {
    locator<InAppReviewService>().init();
  } catch (e, st) {
    _logger.warning('InAppReview init failed', e, st);
  }
  ```
- Synchronous, non-blocking. If init fails, app continues — all methods become no-ops.

---

## Phase 4 — Rate App Screen, Route & ViewModel

### 4.1 Add route

- **File:** `lib/config/route_config.dart`
- Add flat `RouteEntry(path: '/settings/rate-app', ...)` — mirrors `/settings/contact` pattern (NOT a nested child route)
- `requiresAuth: true`, no bottom nav shell

### 4.2 Create `RateAppViewModel`

- **File:** `lib/settings/rate_app_view_model.dart` (new — flat in `lib/settings/`, matching `settings_view_model.dart` placement)
- Pattern: follows `SettingsViewModel` (`lib/settings/settings_view_model.dart`)
- Injects `InAppReviewService` and `NotifyService`
- **Constructor test seams** (mirroring `SettingsViewModel` pattern):
  - `String appStoreId` — defaults to `const String.fromEnvironment('APP_STORE_ID')`. Tests inject explicit values.
  - `String playStorePackageName` — defaults to `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')`. Tests inject explicit values.
  - `Future<bool> Function(Uri, {LaunchMode mode})? launch` — defaults to `launchUrl`. Injectable for unit testing (mirrors `SettingsViewModel` at `lib/settings/settings_view_model.dart:32`).
- **CTA state model** — three distinct getters:
  - `bool get isServiceInitialized` — native `in_app_review` service available (iOS/Android only)
  - `bool get hasFallbackStoreConfig` — fallback URL can be constructed from env config for current platform
  - `bool get canOpenStoreListing` — `isServiceInitialized || hasFallbackStoreConfig` — primary CTA enabled when either path available
- **Fallback URL platform mapping** (resolved at construction, cached as `_resolvedStoreUrl`):
  - Apple platforms (`iOS`, `macOS`): `https://apps.apple.com/app/id<APP_STORE_ID>` — requires `APP_STORE_ID`
  - All other platforms (`Android`, `web`, `Windows`, `Linux`, `Fuchsia`): `https://play.google.com/store/apps/details?id=<PLAY_STORE_PACKAGE_NAME>` — requires `PLAY_STORE_PACKAGE_NAME`
  - If required config for current platform is empty → `_resolvedStoreUrl = null`, `hasFallbackStoreConfig = false`
- Methods:
  - `Future<void> openStoreListing()`:
    - If `isServiceInitialized` → delegate to `_inAppReviewService.openStoreListing()` (native path)
    - Else if `hasFallbackStoreConfig` → launch `_resolvedStoreUrl` via `url_launcher`. On failure: show toast via `NotifyService`
    - Else → no-op (CTA should be disabled by view)
  - `Future<void> requestReviewForScreen()` — delegates to `InAppReviewService.requestReviewForScreen()`
- **Key state scenario**: Android + service initialized + no `PLAY_STORE_PACKAGE_NAME` → `canOpenStoreListing = true` (native path), primary CTA enabled

### 4.3 Create `RateAppView`

- **File:** `lib/settings/rate_app_view.dart` (new — flat in `lib/settings/`, matching `contact_view.dart` placement)
- `Scaffold` with `AppBar`:
  - Close button (top-right) → `locator<RouterService>().back()` (same pattern as `ContactView` at `lib/settings/contact_view.dart:36`)
  - No title in AppBar
- Body: centered column with:
  - Neurostack logo — same asset as main menu/splash (find via existing usage in codebase)
  - Title: "Enjoying Neurostack?" — `Theme.of(context).textTheme` heading style
  - Body text: "Your feedback helps improve the app and reach more people who can benefit from evidence-based wellness protocols."
  - Primary CTA: "Rate on App Store" (star/external-link icon) → `viewModel.openStoreListing()` — enabled when `viewModel.canOpenStoreListing`, disabled with explanatory text when `!canOpenStoreListing`
  - Secondary CTA: "Quick Rating" (star icon) → `viewModel.requestReviewForScreen()` — hidden/disabled when `!viewModel.isServiceInitialized`
- Button styling: check if `AppPrimaryCta` (`lib/core/ui/widgets/app_primary_cta.dart`) supports custom icons. If it hardcodes arrow, use custom styled button matching design system.
- Design tokens: `AppSemanticColors` (`lib/core/ui/extensions/app_semantic_colors.dart`), `AppSpacing` (`lib/core/ui/constants/spacing.dart`), `AppBorderRadius` (`lib/core/ui/constants/border_radius.dart`). No raw `kitColors`.

### 4.4 Add widget keys

- **File:** `lib/core/ui/constants/widget_keys.dart`
- Add keys for Rate App screen elements (logo, title, primaryCta, secondaryCta, closeButton)

---

## Phase 5 — Wire Settings Tile & Programmatic Trigger

### 5.1 Add `goToRateApp()` to SettingsViewModel

- **File:** `lib/settings/settings_view_model.dart`
- Add `void goToRateApp()` method — navigates to `/settings/rate-app` via `_routerService.goTo(Path(name: '/settings/rate-app'))`
- Follows existing pattern of `goToPaywall()`, `goToContact()`, etc. (see `settings_view_model.dart`)

### 5.2 Wire Settings tile tap

- **File:** `lib/settings/settings_view.dart` (line 109)
- **Current:** `onRateAppTap: () {},`
- **Replace with:** `onRateAppTap: _viewModel.goToRateApp,` (or equivalent delegate pattern matching existing tiles)

### 5.3 Update tile trailing icon

- **File:** `lib/settings/widgets/settings_support_section.dart` (line 64-69)
- Change trailing icon: `LucideIcons.externalLink` → `LucideIcons.chevronRight` (consistent with Contact Us, Feature Request — in-app navigation tiles use chevron-right)

### 5.4 Add programmatic trigger in HomeView

- **File:** `lib/home/home_view.dart` (inside `_showLogSessionModal`)
- **Callback contract**: `showLogSessionModal` takes `void Function(Session session)` — callback is synchronous, cannot be awaited by modal. We store the `Future<int>` and await it after modal dismiss.
- Implementation:
  1. Declare `Future<int>? sessionCountFuture;` before `showLogSessionModal` call
  2. **In `onSessionLogged` callback** (fires pre-dismiss, after save, before sync moves data):
     ```dart
     sessionCountFuture = locator<ReviewTriggerHelper>().captureSessionCount(userId);
     ```
     Fire-and-forget from modal's perspective, but caller holds the Future reference.
  3. After `await showLogSessionModal()` returns (modal dismissed):
     ```dart
     if (sessionCountFuture != null) {
       try {
         final count = await sessionCountFuture!;
         await locator<ReviewTriggerHelper>().triggerReviewIfNeeded(count, userId);
       } catch (_) {
         // Non-critical — review prompt is best-effort
       }
     }
     ```
  4. Add `// TODO(analytics): track review prompt event`

### 5.5 Add programmatic trigger in ProgressView

- **File:** `lib/progress/progress_view.dart` (inside `_showLogSessionModal`)
- Same pattern as Phase 5.4 — identical `Future<int>?` approach using `ReviewTriggerHelper`

---

## Phase 6 — Unit Tests

### 6.1 InAppReviewService tests

- **File:** `test/core/utils/in_app_review/in_app_review_service_test.dart` (new)
- Test threshold logic via mock `InAppReviewAdapter`:
  - session count 4 → no trigger
  - session count 5 → trigger (first threshold)
  - session count 6 → no trigger (already fired for threshold 0)
  - session count 15 → trigger (second threshold)
  - session count 35 → trigger (third threshold)
  - session count 36 → no trigger (all thresholds exhausted)
- Test `_isInitialized` guard: methods are no-ops when not initialized
- Test SharedPreferences index persistence: increments correctly, survives across calls
- Test non-mobile platform guard via `debugDefaultTargetPlatformOverride` (set to `TargetPlatform.linux` → init skips)
- Test `requestReviewForScreen()` fallback: mock adapter throws → verify `adapter.openStoreListing(...)` was called (observable behavior on adapter mock)
- Test `openStoreListing()` failure → verify `NotifyService` toast fired (see `ToastEventError` at `lib/core/utils/internal_notification/toast/toast_event.dart`)
- Test missing platform config (e.g., missing `APP_STORE_ID` on iOS) → `_isInitialized` stays false
- Test Android init succeeds without `APP_STORE_ID` (not required on Android)

### 6.2 ReviewTriggerHelper tests

- **File:** `test/core/utils/in_app_review/review_trigger_helper_test.dart` (new)
- Test `captureSessionCount` returns correct sum of synced + pending
- Test `triggerReviewIfNeeded` calls service after 2s delay
- Test error handling: exceptions in session count queries don't crash

### 6.3 RateAppViewModel tests

- **File:** `test/settings/rate_app_view_model_test.dart` (new)
- Test `openStoreListing()` delegates to service on supported platforms (native path)
- Test `openStoreListing()` launches fallback URL on unsupported platforms
- Test `requestReviewForScreen()` delegates to service
- **CTA state model tests:**
  - `isServiceInitialized` reflects service state
  - `hasFallbackStoreConfig` reflects env config + platform
  - `canOpenStoreListing = isServiceInitialized || hasFallbackStoreConfig`
  - Android + service initialized + no `PLAY_STORE_PACKAGE_NAME` → `canOpenStoreListing = true` (native)
  - Web + `PLAY_STORE_PACKAGE_NAME` + no service → `canOpenStoreListing = true` (fallback)
  - Web + no config + no service → `canOpenStoreListing = false`
- **Fallback URL platform mapping tests:**
  - iOS/macOS → App Store URL with `APP_STORE_ID`
  - Android/web/Windows/Linux → Play Store URL with `PLAY_STORE_PACKAGE_NAME`
  - At least one desktop platform tested (macOS with `APP_STORE_ID`)
- Test missing fallback config: `hasFallbackStoreConfig = false`, CTA disabled
- Test fallback launch failure: `url_launcher` throws → verify toast shown via `NotifyService`

### 6.4 Callback-future orchestration integration test

- **File:** `test/home/post_modal_review_trigger_test.dart` (new)
- Verifies the full post-modal trigger sequencing:
  1. `captureSessionCount` Future initiated when `onSessionLogged` fires
  2. Future runs concurrently (not blocked by modal)
  3. After modal dismiss simulation, `await sessionCountFuture` resolves with correct count
  4. `triggerReviewIfNeeded` called after dismiss with captured count
  5. 2-second delay before `requestReviewIfNeeded` fires
- Uses mock `ReviewTriggerHelper`, `FakeAsync` for delay verification

### 6.5 Settings tile routing

- Test `SettingsViewModel.goToRateApp()` calls `RouterService.goTo(Path(name: '/settings/rate-app'))`

---

## Phase 7 — Update Documentation

### 7.1 Create Rate App screen prompt

- **File:** `docs/best_practices/design/screen-prompts/12-rate-app-screen.md` (new)
- Follow format of `docs/best_practices/design/screen-prompts/11-settings-screen.md`
- Layout, semantic tokens, route (`/settings/rate-app`), widget tree, CTA definitions
- Document navigation: `RouterService.goTo()` / `RouterService.back()` (NOT GoRouter/Navigator)
- Document unsupported platform behavior: fallback config validation, CTA disabling, launch failure toast

### 7.2 Update Settings screen prompt

- **File:** `docs/best_practices/design/screen-prompts/11-settings-screen.md` (line 44)
- Rate the App tile row: trailing icon `external-link` → `chevron-right`, action text from placeholder to "Navigate to /settings/rate-app via RouterService"

### 7.3 Update Settings screen spec

- **File:** `docs/specs/20260227120000_spec_settings_screen.md`
- Tile Definitions table (line 83): update Rate the App action to "Navigate to /settings/rate-app"
- Remove "App Store rating integration" from Out of Scope section (lines 143-147)
- Add `in_app_review` to Dependencies section (line 128-131)
- Update note block under Tile Definitions (line 87): remove placeholder language

### 7.4 Update screen functional specifications

- **File:** `docs/best_practices/design/screen-functional-specifications.md`
- Add "11. Rate App Screen" section: Route, Wireframe, States, Navigation (RouterService), Invariants
- Fix quick-reference metadata counts in summary header to reflect actual screen count

### 7.5 Update README

- **File:** `docs/README.md`
- Add screen prompt link after Settings Screen entry (line 38):
  ```
  - [Rate App Screen](./best_practices/design/screen-prompts/12-rate-app-screen.md) - rate app, in-app review, openStoreListing, requestReview
  ```
- Add/update spec link in Feature Specs section (line 65):
  ```
  - [Spec: Rate App / In-App Review](./specs/202603162012_spec_rate_app_integration.md) - InAppReviewService, requestReview, openStoreListing, session milestone trigger
  ```

---

## Files Changed (Summary)

| File | Action | Phase |
|------|--------|-------|
| `pubspec.yaml` | Edit — add `in_app_review` | 1.1 |
| `env/default.env.json` | Edit — add `APP_STORE_ID`, `PLAY_STORE_PACKAGE_NAME` | 1.2 |
| `lib/core/utils/in_app_review/in_app_review_adapter.dart` | **New** — test seam interface + default impl | 2.1 |
| `lib/core/utils/in_app_review/in_app_review_service.dart` | **New** — service wrapper | 2.2 |
| `lib/core/utils/in_app_review/review_trigger_helper.dart` | **New** — shared trigger logic | 2.3 |
| `test/mocks/mock_services.dart` | Edit — add `MockInAppReviewService`, `MockInAppReviewAdapter` | 2.4 |
| `lib/config/locator_config.dart` | Edit — register `InAppReviewService` + `ReviewTriggerHelper` lazy singletons | 3.1 |
| `lib/startup/startup_view_model.dart` | Edit — call `init()` after UserOrient init | 3.2 |
| `lib/config/route_config.dart` | Edit — add `/settings/rate-app` route | 4.1 |
| `lib/settings/rate_app_view_model.dart` | **New** — ViewModel with fallback URL + config validation + NotifyService | 4.2 |
| `lib/settings/rate_app_view.dart` | **New** — Rate App screen UI | 4.3 |
| `lib/core/ui/constants/widget_keys.dart` | Edit — add Rate App widget keys | 4.4 |
| `lib/settings/settings_view_model.dart` | Edit — add `goToRateApp()` via `RouterService.goTo()` | 5.1 |
| `lib/settings/settings_view.dart` | Edit — wire `onRateAppTap` to ViewModel (line 109) | 5.2 |
| `lib/settings/widgets/settings_support_section.dart` | Edit — trailing icon `externalLink` → `chevronRight` (line 64-69) | 5.3 |
| `lib/home/home_view.dart` | Edit — add `Future<int>?` trigger via ReviewTriggerHelper in `_showLogSessionModal` | 5.4 |
| `lib/progress/progress_view.dart` | Edit — add `Future<int>?` trigger via ReviewTriggerHelper in `_showLogSessionModal` | 5.5 |
| `test/core/utils/in_app_review/in_app_review_service_test.dart` | **New** — threshold, persistence, guard, fallback tests | 6.1 |
| `test/core/utils/in_app_review/review_trigger_helper_test.dart` | **New** — capture count, trigger delay, error handling tests | 6.2 |
| `test/settings/rate_app_view_model_test.dart` | **New** — ViewModel + CTA state model + fallback URL + config + launch failure tests | 6.3 |
| `test/home/post_modal_review_trigger_test.dart` | **New** — callback-future orchestration integration test | 6.4 |
| `docs/best_practices/design/screen-prompts/12-rate-app-screen.md` | **New** — screen prompt | 7.1 |
| `docs/best_practices/design/screen-prompts/11-settings-screen.md` | Edit — update tile table (line 44) | 7.2 |
| `docs/specs/20260227120000_spec_settings_screen.md` | Edit — remove placeholder, update deps, update out-of-scope | 7.3 |
| `docs/best_practices/design/screen-functional-specifications.md` | Edit — add Rate App screen entry, fix metadata counts | 7.4 |
| `docs/README.md` | Edit — add screen prompt link + spec link | 7.5 |

---

## Testing Notes

- **Unit tests (Phase 6):** threshold logic, index persistence, platform guard, init guard, fallback behavior, toast on failure, ViewModel CTA state model (`isServiceInitialized`/`hasFallbackStoreConfig`/`canOpenStoreListing`), fallback URL platform mapping (Apple → App Store, others → Play Store), desktop platform coverage, fallback config validation, fallback launch failure, callback-future orchestration integration test, trigger sequencing, ReviewTriggerHelper capture + delay
- **Smoke test:** Run app, navigate to Settings → tap "Rate the App" → verify Rate App screen opens with both buttons
- **Programmatic trigger:** Log 5 sessions, verify `requestReview()` fires after the 5th (debug logs)
- **Missing config:** Remove `APP_STORE_ID` from `env/env.json`, run on iOS — verify no crash, warning logged, service degrades gracefully
- **Unsupported platform fallback:** Run on web, verify "Rate on App Store" opens store URL via browser, verify "Quick Rating" is disabled
- **Missing fallback config:** Run on web with empty env config — verify primary CTA disabled, no crash
- **Web build:** `flutter build web --dart-define-from-file=env/env.json` — verify no compile errors, service is inert
- **Existing tests:** `flutter test` must pass (no regressions)
- **Analyze:** `flutter analyze` must pass

---

## Key References

| Reference | Location |
|-----------|----------|
| in_app_review docs | [pub.dev](https://pub.dev/packages/in_app_review) |
| iOS 18 freeze issue | [GitHub #147](https://github.com/britannio/in_app_review/issues/147) |
| Android NullPointerException | [GitHub #175](https://github.com/britannio/in_app_review/issues/175) |
| UserOrientService (pattern) | `lib/core/utils/userorient/userorient_service.dart` |
| TrialReminderService (SharedPrefs pattern) | `lib/paywall/data/trial_reminder_service.dart` |
| NotifyService (toasts) | `lib/core/utils/internal_notification/notify_service.dart` |
| ToastEvent types | `lib/core/utils/internal_notification/toast/toast_event.dart` |
| SessionLocalDataSource (session counts) | `lib/features/session/data/data_sources/session_local_data_source.dart` |
| LogSessionModal (trigger entry point) | `lib/features/session/presentation/log_session_modal.dart` |
| HomeView (programmatic trigger site) | `lib/home/home_view.dart` |
| ProgressView (programmatic trigger site) | `lib/progress/progress_view.dart` |
| SettingsViewModel | `lib/settings/settings_view_model.dart` |
| Settings view tap site | `lib/settings/settings_view.dart:109` |
| Support section widget | `lib/settings/widgets/settings_support_section.dart:64-69` |
| Route config | `lib/config/route_config.dart` |
| Locator config | `lib/config/locator_config.dart` |
| Startup init sequence | `lib/startup/startup_view_model.dart:58-111` |
| ContactView (navigation pattern) | `lib/settings/contact_view.dart:36` |
| RouterService | `lib/core/utils/navigation/router_service.dart` |
| AppPrimaryCta widget | `lib/core/ui/widgets/app_primary_cta.dart` |
| AppSemanticColors | `lib/core/ui/extensions/app_semantic_colors.dart` |
| AppSpacing constants | `lib/core/ui/constants/spacing.dart` |
| Widget keys | `lib/core/ui/constants/widget_keys.dart` |
| Mock services | `test/mocks/mock_services.dart` |
| Env template | `env/default.env.json` |
| Settings screen spec | `docs/specs/20260227120000_spec_settings_screen.md` |
| Settings screen prompt | `docs/best_practices/design/screen-prompts/11-settings-screen.md` |
| Screen functional specs | `docs/best_practices/design/screen-functional-specifications.md` |
| Rate App spec | `docs/specs/202603162012_spec_rate_app_integration.md` |
