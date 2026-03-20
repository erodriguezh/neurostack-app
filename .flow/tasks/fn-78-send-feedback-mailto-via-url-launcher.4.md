# fn-78-send-feedback-mailto-via-url-launcher.4 Add package_info_plus, bootstrap DI, implement sendFeedback, wire callback

## Description
Add `package_info_plus` as a direct dependency, thread `PackageInfo` through the full startup/DI bootstrap path, implement `sendFeedback()` on `SettingsViewModel`, and wire the callback in `SettingsView`.

**Size:** M
**Files:**
- `pubspec.yaml`
- `lib/main.dart` (resolve `PackageInfo.fromPlatform()` + thread through `_AppLifecycleObserver`)
- `lib/startup/startup_view.dart` (accept + forward `PackageInfo`)
- `lib/startup/startup_view_model.dart` (accept + forward to `buildModules`)
- `lib/config/locator_config.dart` (extend `buildModules` signature, register non-lazy singleton)
- `lib/settings/settings_view_model.dart` (add `PackageInfo` param + `sendFeedback()` method)
- `lib/settings/settings_view.dart` (wire callback, pass `PackageInfo` from locator)

## Approach

### DI Bootstrap
- Follow the `SharedPreferences` threading pattern exactly: resolve in `main()`, pass through `_AppLifecycleObserver` → `StartupView` → `StartupViewModel` → `buildModules()`
- `main.dart:12-14` — resolve alongside `SharedPreferences`
- `main.dart:22-63` — `_AppLifecycleObserver` needs new `PackageInfo` field
- `startup_view.dart:18-30` — add constructor param, forward to `StartupViewModel`
- `startup_view_model.dart:46-64` — accept param, pass to `buildModules()` at L63-64
- `locator_config.dart:59-60` — extend signature: `buildModules({required SharedPreferences, required PackageInfo})`; register with `Module<PackageInfo>(builder: () => packageInfo, lazy: false)`

### sendFeedback() Method
- Combine auth extraction from `openFeatureRequestBoard()` (`settings_view_model.dart:114-131`) with launch pattern from `openSubscriptionManagement()` (`settings_view_model.dart:138-158`)
- Build mailto URI using `Uri(scheme: 'mailto', path: 'feedback@getneurostack.app', query: ...)` with an `encodeQueryParameters` helper using `Uri.encodeComponent()` per value — NOT `queryParameters:` (Dart SDK #43838 encodes spaces as `+`)
- Subject: `NeuroStack Feedback`
- Body: `App Version: {version}+{buildNumber}\nPlatform: {defaultTargetPlatform.name}\nSubscription: {effectiveStatus.name}`
- Launch with `LaunchMode.externalApplication` (native) / `LaunchMode.platformDefault` (web)
- Fire-and-forget try-catch, no fallback
- No-op when user is unauthenticated (same guard as `openFeatureRequestBoard`)

### Wiring
- Replace `onFeedbackTap: () {}, // TODO: Wiredash` at `settings_view.dart:108` with `_viewModel.sendFeedback`
- Pass `locator<PackageInfo>()` to `SettingsViewModel` constructor at `settings_view.dart:32-39`

## Key context
- `Uri(queryParameters:)` encodes spaces as `+` which breaks mailto on many mail clients — MUST use `query:` param with manual `Uri.encodeComponent()` (url_launcher README canonical helper)
- `PackageInfo` has a public constructor for testing — no mock needed
- The `_launch` function is already injected for testability (`settings_view_model.dart:32/42`)
## Acceptance
- [ ] `package_info_plus` added as direct dependency in `pubspec.yaml`
- [ ] `PackageInfo` resolved in `main()` and threaded through `_AppLifecycleObserver` → `StartupView` → `StartupViewModel` → `buildModules()`
- [ ] `PackageInfo` registered as non-lazy singleton in locator (survives `retryInitialization()`)
- [ ] `sendFeedback()` method on `SettingsViewModel` builds correct mailto URI
- [ ] mailto URI uses `Uri.encodeComponent` (spaces as `%20`, not `+`)
- [ ] `to` is `feedback@getneurostack.app`, subject is `NeuroStack Feedback`
- [ ] Body contains app version+build, platform name, effective subscription tier
- [ ] No-op when user is unauthenticated
- [ ] Callback wired in `SettingsView` — tapping "Send Feedback" invokes `sendFeedback()`
- [ ] `flutter analyze` clean
- [ ] `flutter test` passes (existing tests, no new tests in this task)
## Done summary
Duplicate — use task .1 instead
## Evidence
- Commits:
- Tests:
- PRs: