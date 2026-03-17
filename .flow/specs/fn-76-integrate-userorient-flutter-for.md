# Integrate userorient_flutter for Feature Request

## Overview
Add the `userorient_flutter` v2.1.0 SDK to enable the "Feature Request" tile in the Settings screen. When a user taps the tile, the UserOrient board opens — letting users vote on and submit feature requests. The integration follows the same patterns as RevenueCat: a thin service wrapper, env-based API key, constructor-injected DI throughout, startup initialization, and cleanup in both logout paths.

## Scope
- **In scope**: Add package, env key, thin `UserOrientService` wrapper, register in DI, constructor-inject into `AuthService` and `SettingsViewModel`, init at startup, wire Feature Request tap via ViewModel method, light/dark theming, `clearCache()` on both `logout()` and `signedOut` auth event, unit tests (scoped to correct files), update settings screen spec + screen prompt docs.
- **Out of scope**: "Send Feedback" tile (remains pending Wiredash), web platform support (see "Unsupported platforms" below), `setDataCollection()` configuration, reactive locale changes.

## Approach

### UserOrientService (thin wrapper)
- **Location:** `lib/core/utils/userorient/userorient_service.dart` (new)
- Constructor: no dependencies (reads API key from environment, colors from const `KitColorsExtension`)
- Three public methods with explicit signatures:
  - `void init()` — synchronous. Guards unsupported platforms (`kIsWeb` / non-iOS/Android) with debug log + early return. Guards empty API key with warning log + early return. On supported platforms with valid key, calls `UserOrient.configure(apiKey:)`, `UserOrient.setLanguage(Language.en)`, `UserOrient.setTheme(light:, dark:)`, sets `_isInitialized = true`.
  - `void openBoard(BuildContext context, {required String userId, required bool isPaying})` — guards `_isInitialized` (returns immediately if `false`), calls `UserOrient.setUser(uniqueIdentifier:, isPaying:)` then `UserOrient.openBoard(context)`.
  - `Future<void> clearCache()` — guards `_isInitialized` (returns `Future.value()` if `false`), calls `UserOrient.clearCache()`. Returns future for callers that want to await.
- Internal state: `bool _isInitialized = false` (no `Completer` — init is synchronous, no async race conditions)

### DI registration & injection
- Register `UserOrientService` as lazy singleton in `locator_config.dart`
- Constructor-inject into `AuthService` (same pattern as `RevenueCatService` at `locator_config.dart:186`)
- Constructor-inject into `SettingsViewModel` (same pattern as other deps at `settings_view_model.dart:21-39`)
- No `locator<UserOrientService>()` calls in ViewModel or AuthService — all via constructor injection

### SDK initialization
- Call `void init()` synchronously in `startup_view_model.dart` after RevenueCat init (line ~87), before `AuthService.init()` (line 88)
- Pattern: `try { locator<UserOrientService>().init(); } catch (e, st) { _logger.warning('UserOrient init failed', e, st); }`
- If init fails, app continues — `openBoard()` becomes a no-op via `_isInitialized` guard

### Feature Request tap
- Add `openFeatureRequestBoard(BuildContext context)` method to `SettingsViewModel`
- Method extracts user ID from `AuthState` via pattern match, derives `isPaying` from `SubscriptionStatusResolver`, calls `_userOrientService.openBoard()`
- `SettingsView` delegates: `onFeatureRequestTap: () => _viewModel.openFeatureRequestBoard(context)`
- Business logic stays in ViewModel — view is a thin delegate

### Theming
- Call `UserOrient.setTheme()` in `init()`:
  - **Light:** `UserOrientColors(backgroundColor: kitColors.neutral100, accentColor: kitColors.neutral950)`
  - **Dark:** `UserOrientColors(backgroundColor: kitColors.background, accentColor: kitColors.brandSky)`

### Logout & auth event cleanup
- `UserOrientService` is the sole integration surface — constructor-injected into `AuthService`
- `clearCache()` called in TWO places:
  1. `AuthService.logout()` (line ~91) — explicit logout, after RevenueCat logout, before Supabase signOut. **Awaited** best-effort cleanup with try-catch (same pattern as RevenueCat at `auth_service.dart:88`).
  2. `AuthService._handleAuthChange()` signedOut case (line ~158) — implicit sign-out (token revocation, server-side logout). **Unawaited** with `.catchError()` on the future chain (matches existing RevenueCat pattern at `auth_service.dart:160-167`: `unawaited(_service.method().catchError(...))`). Note: `try-catch` does NOT catch async errors from unawaited futures — must use `.catchError()`.

### Unsupported platforms
- `userorient_flutter` supports iOS and Android only. The repo has `web/` and `macos/` targets.
- `UserOrientService.init()` adds an early-return `kIsWeb` / unsupported-platform guard (before calling any SDK methods), setting `_isInitialized = false` with a debug log. This makes the entire service a no-op on non-mobile platforms — same degraded-behavior pattern as the empty API key guard.
- `openBoard()` and `clearCache()` already guard on `_isInitialized`, so no additional per-method guards are needed.
- This avoids conditional imports or stub classes while keeping `flutter analyze` and `flutter build web` clean.

### Testing
- **`test/settings/settings_view_model_test.dart`**: authenticated tap calls `openBoard` with correct userId and isPaying, unauthenticated tap is no-op, isPaying derived from `SubscriptionStatus.isPremium`
- **`test/features/auth/data/auth_service_test.dart`**: `logout()` triggers `clearCache()`, `signedOut` auth event triggers `clearCache()`
- `MockUserOrientService` in `test/mocks/mock_services.dart`

### v2.1.0 breaking change
- `configure()` no longer accepts `languageCode`. Must use `UserOrient.setLanguage(Language.en)` separately.

## Quick commands
```bash
flutter pub get
flutter test
flutter run -d 1EA9596A-EBDF-4B22-9781-181F20DEB836 --dart-define-from-file=env/env.json
```

## Risks
- **Low-star package** (23 GitHub stars): limited community validation. Test thoroughly.
- **Dependency conflicts**: `userorient_flutter` pulls in `device_info_plus`, `package_info_plus`, `shared_preferences`, `url_launcher` — verify no version conflicts.
- **Offline tap**: `openBoard()` may fail silently with no connectivity. SDK handles internally.

## Acceptance
- [ ] `userorient_flutter: ^2.1.0` in pubspec.yaml, `flutter pub get` succeeds
- [ ] `USERORIENT_API_KEY` in `env/default.env.json` as placeholder
- [ ] `UserOrientService` with `void init()`, `void openBoard(...)`, `Future<void> clearCache()`
- [ ] Service registered in `locator_config.dart`, constructor-injected into `AuthService` and `SettingsViewModel`
- [ ] `init()` called synchronously in startup: `try { locator<UserOrientService>().init(); } catch ...`
- [ ] `SettingsViewModel.openFeatureRequestBoard(context)` delegates to `_userOrientService`
- [ ] Tap opens board with correct user ID and `isPaying` flag
- [ ] Board respects app light/dark theme
- [ ] `clearCache()` called in both `AuthService.logout()` and `_handleAuthChange(signedOut)`
- [ ] `MockUserOrientService` in `test/mocks/mock_services.dart`
- [ ] SettingsViewModel tests: board-opening behavior (authenticated/unauthenticated/isPaying)
- [ ] AuthService tests: cleanup in both `logout()` and `signedOut` paths
- [ ] Settings screen spec tile table lists all 5 rendered tiles (Contact Us, Send Feedback placeholder, Rate the App placeholder, Feature Request via UserOrient, Cancel Subscription)
- [ ] Settings screen prompt tile table lists all 5 rendered tiles
- [ ] Platform guard: `init()` is a no-op on web/unsupported platforms (no crash, `_isInitialized` stays `false`)
- [ ] `flutter analyze` passes, all tests pass

## References
- [userorient_flutter v2.1.0](https://pub.dev/packages/userorient_flutter)
- RevenueCat pattern: `lib/paywall/data/revenuecat_service.dart`
- AuthService DI: `lib/config/locator_config.dart:177-189`
- Auth signedOut handler: `lib/features/auth/data/auth_service.dart:158`
- Startup sequence: `lib/startup/startup_view_model.dart:58-111`
- SettingsViewModel deps: `lib/settings/settings_view_model.dart:21-39`
- Settings view tap site: `lib/settings/settings_view.dart:108`
- Auth state: `lib/features/auth/domain/auth_state.dart`
- App theme: `lib/core/ui/app_theme.dart`
