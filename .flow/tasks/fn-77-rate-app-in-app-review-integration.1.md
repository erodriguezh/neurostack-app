# fn-77-rate-app-in-app-review-integration.1 Add in_app_review package, InAppReviewService, and env config

## Description
Add the `in_app_review` package, create `InAppReviewAdapter` interface (test seam), create `InAppReviewService` following the `UserOrientService` pattern, create `ReviewTriggerHelper` for shared trigger logic, update env config, register in service locator, and wire startup init.

**Size:** M
**Files:**
- `pubspec.yaml` (add `in_app_review` dependency)
- `lib/core/utils/in_app_review/in_app_review_adapter.dart` (new — interface + default impl)
- `lib/core/utils/in_app_review/in_app_review_service.dart` (new)
- `lib/core/utils/in_app_review/review_trigger_helper.dart` (new — shared trigger logic)
- `lib/config/locator_config.dart` (register lazy singleton)
- `lib/startup/startup_view_model.dart` (add init call)
- `env/default.env.json` (add `APP_STORE_ID`, `PLAY_STORE_PACKAGE_NAME`)
- `test/core/utils/in_app_review/in_app_review_service_test.dart` (new)
- `test/core/utils/in_app_review/review_trigger_helper_test.dart` (new)
- `test/mocks/mock_services.dart` (add `MockInAppReviewService`, `MockInAppReviewAdapter`)

## Approach

- **Test seam**: Create `InAppReviewAdapter` abstract class with `isAvailable()`, `requestReview()`, `openStoreListing({String? appStoreId})`. Default implementation `DefaultInAppReviewAdapter` delegates to `InAppReview.instance`. This enables full mocking in unit tests.
- Follow `UserOrientService` pattern at `lib/core/utils/userorient/userorient_service.dart`
- Plain class with `Logger`, `_isInitialized` guard
- **Platform guard**: Use `defaultTargetPlatform` (swappable in tests via `debugDefaultTargetPlatformOverride`) for iOS/Android check. `kIsWeb` for compile-time web guard (no unit test needed for this — it's compile-time).
- **Constructor dependencies**: `SharedPreferences` (review-request index), `NotifyService` (error toasts), `InAppReviewAdapter` (test seam), `String appStoreId` (default `const String.fromEnvironment('APP_STORE_ID')`), `String playStorePackageName` (default `const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME')`)
- **Config testability**: `const String.fromEnvironment(...)` is compile-time and cannot be varied per test. Constructor params with compile-time defaults enable tests to inject explicit values for present/missing config combinations. Production uses defaults.
- **Env config**: Defaults read via `const String.fromEnvironment(...)` — matching existing codebase pattern, NOT `AppEnvironment`
- **Platform-specific config validation**: On iOS, require `APP_STORE_ID` — if empty, log warning and keep `_isInitialized = false`. On Android, no env config needed for service init (plugin auto-detects package name from manifest). `PLAY_STORE_PACKAGE_NAME` is only used by `RateAppViewModel` for `url_launcher` fallback, not by the service.
- SharedPreferences key: `'review_request_index_<userId>'`, default 0
- Thresholds: `[5, 15, 35]` — index into this list

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

Tasks 2 and 3 depend on this contract. The `isInitialized` getter is used by `RateAppViewModel` for conditional UI. All methods no-op when `!isInitialized`. All async methods wrapped in try/catch.

### Three key service methods:
  - `requestReviewIfNeeded(int sessionCount, String userId)` — programmatic: check threshold, call `adapter.requestReview()`, increment index. Silent on failure.
  - `requestReviewForScreen()` — manual: try `adapter.requestReview()`, on failure fallback to `openStoreListing()`
  - `openStoreListing()` — pass `appStoreId` from env config. On failure, show error toast via `NotifyService`

### ReviewTriggerHelper (shared trigger logic):
- New file: `lib/core/utils/in_app_review/review_trigger_helper.dart`
- Constructor deps: `SessionLocalDataSource`, `InAppReviewService`
- `captureSessionCount(String userId)` — queries synced + pending sessions via `Future.wait`, returns total count
- `triggerReviewIfNeeded(int sessionCount, String userId)` — delays 2s then calls `requestReviewIfNeeded`
- Both HomeView and ProgressView will use this helper (in task 3), eliminating logic duplication
- Register as lazy singleton in `locator_config.dart`

- Register `InAppReviewService` as `Module<InAppReviewService>(builder: ..., lazy: true)` in `locator_config.dart` near `UserOrientService` registration (~line 186)
- Register `ReviewTriggerHelper` similarly
- Init in `startup_view_model.dart` after UserOrient init (~line 89), wrapped in try/catch
- `// TODO(analytics): track review prompt event` at trigger points

## Key context

- `isAvailable()` must be called before `requestReview()` — necessary but not sufficient
- iOS 18 freeze (#147): `requestReview()` can block main thread ~8s — try/catch mitigates
- Android NullPointerException (#175): wrap in try/catch
- `openStoreListing()` passes `appStoreId` on iOS (from env config); Android package name auto-detected by plugin (no env config needed). `PLAY_STORE_PACKAGE_NAME` is only used by `RateAppViewModel` for `url_launcher` fallback URLs.
- `requestReview()` gives zero feedback — no way to know if dialog was shown

## Unit tests

### InAppReviewService tests:
- Test threshold logic via mock `InAppReviewAdapter`: session count 4 → no trigger, 5 → trigger, 6 → no trigger (already fired), 15 → trigger, 35 → trigger, 36 → no trigger (exhausted)
- Test `_isInitialized` guard: methods are no-ops when not initialized
- Test SharedPreferences index persistence: increments correctly, survives across calls
- Test non-mobile platform guard via `debugDefaultTargetPlatformOverride` (set to linux → init skips)
- Test `requestReviewForScreen()` fallback: mock adapter throws → verify `adapter.openStoreListing(...)` was called (observable behavior on the adapter mock, not internal state)
- Test `openStoreListing()` failure → verify `NotifyService` toast fired
- Test missing platform config (e.g., missing `APP_STORE_ID` on iOS) → `_isInitialized` stays false
- Test Android init succeeds without `APP_STORE_ID` (not required on Android)

### ReviewTriggerHelper tests:
- Test `captureSessionCount` returns correct sum of synced + pending
- Test `triggerReviewIfNeeded` calls service after 2s delay
- Test error handling: exceptions in session count queries don't crash

## Acceptance
- [ ] `in_app_review` package added to `pubspec.yaml` and `flutter pub get` succeeds
- [ ] `InAppReviewAdapter` abstract class + `DefaultInAppReviewAdapter` created (test seam)
- [ ] `InAppReviewService` created at `lib/core/utils/in_app_review/in_app_review_service.dart`
- [ ] Public contract locked: `init()`, `isInitialized` getter, `requestReviewIfNeeded()`, `requestReviewForScreen()`, `openStoreListing()`
- [ ] Constructor injects `SharedPreferences`, `NotifyService`, and `InAppReviewAdapter`
- [ ] Platform guard uses `defaultTargetPlatform` (testable), `kIsWeb` for compile-time web check
- [ ] `requestReviewIfNeeded(int sessionCount, String userId)` checks thresholds `[5, 15, 35]`
- [ ] `requestReviewForScreen()` tries `requestReview()`, fallback to `openStoreListing()` on failure
- [ ] `openStoreListing()` passes `appStoreId` on iOS; Android auto-detected by plugin (no param needed)
- [ ] Error toast shown via `NotifyService` when `openStoreListing()` fails
- [ ] Env config read via `const String.fromEnvironment(...)` — NOT `AppEnvironment`
- [ ] Platform-specific config: iOS requires `APP_STORE_ID`, Android needs nothing for service init
- [ ] Missing platform config → `_isInitialized = false` on that platform, graceful degradation
- [ ] Review-request index persisted in SharedPreferences with user-scoped key
- [ ] `env/default.env.json` updated with `APP_STORE_ID` and `PLAY_STORE_PACKAGE_NAME` placeholder keys
- [ ] `ReviewTriggerHelper` created with `captureSessionCount()` and `triggerReviewIfNeeded()` methods
- [ ] Both `InAppReviewService` and `ReviewTriggerHelper` registered as lazy singletons in `locator_config.dart`
- [ ] `init()` called in `startup_view_model.dart` with try/catch
- [ ] `MockInAppReviewService` and `MockInAppReviewAdapter` added to `test/mocks/mock_services.dart`
- [ ] Unit tests cover: threshold logic, index persistence, platform guard, init guard, requestReviewForScreen fallback (verify adapter mock called), openStoreListing toast on failure, missing env config
- [ ] ReviewTriggerHelper unit tests cover: session count capture, trigger delay + service call, error handling
- [ ] Test assertions verify observable behavior on mocks (e.g., `verify adapter.openStoreListing(...)`) not internal state
- [ ] `// TODO(analytics)` comments at service-level trigger points
- [ ] `flutter analyze` passes

## Done summary
Added in_app_review package, InAppReviewAdapter test seam, InAppReviewService with threshold-based programmatic review prompts and manual review/fallback flows, ReviewTriggerHelper for shared post-session trigger logic, locator/startup wiring, env config placeholders, and 29 unit tests covering threshold logic, index persistence, platform guards, delay behavior, and error handling.
## Evidence
- Commits: 68c81a9, 5ee5528, a7f110d
- Tests: flutter test test/core/utils/in_app_review/, flutter analyze, flutter test
- PRs: