# fn-76-integrate-userorient-flutter-for.1 Add userorient_flutter package, service wrapper, and startup init

## Description
Add `userorient_flutter: ^2.1.0` to the project, create a thin `UserOrientService` wrapper, register it in the service locator, inject it into `AuthService`, and call `init()` during app startup.

**Size:** M
**Files:**
- `pubspec.yaml` — add dependency
- `env/default.env.json` — add `USERORIENT_API_KEY` placeholder
- `lib/core/utils/userorient/userorient_service.dart` — new thin service wrapper
- `lib/config/locator_config.dart` — register service, inject into AuthService
- `lib/startup/startup_view_model.dart` — call init in startup sequence
- `lib/features/auth/data/auth_service.dart` — add constructor parameter for UserOrientService
- `test/mocks/mock_services.dart` — add `MockUserOrientService`

## Approach
- Follow `RevenueCatService` pattern (`lib/paywall/data/revenuecat_service.dart`) for service structure
- `UserOrientService` has three public methods with explicit signatures:
  - `void init()` — synchronous. Guards unsupported platforms (`kIsWeb` / non-iOS/Android) with debug log + early return. Reads API key via `const String.fromEnvironment('USERORIENT_API_KEY')`, guards empty key (log warning + early return). On supported platforms with valid key, calls `UserOrient.configure()`, `UserOrient.setLanguage(Language.en)`, `UserOrient.setTheme(light:, dark:)`
  - `void openBoard(BuildContext, {required String userId, required bool isPaying})` — guards `_isInitialized` (returns immediately if `false`), calls `setUser()` then `openBoard()`
  - `Future<void> clearCache()` — guards `_isInitialized` (returns `Future.value()` if `false`), calls `UserOrient.clearCache()`
- Theme mapping from `KitColorsExtension` (`lib/core/ui/constants/kit_colors.dart`): light → `neutral100`/`neutral950`, dark → `background`/`brandSky` (see `lib/core/ui/app_theme.dart:44-61`)
- Register as lazy singleton in `locator_config.dart`
- Inject `UserOrientService` into `AuthService` constructor — same pattern as `RevenueCatService` at `locator_config.dart:186`
- Startup: synchronous `try { locator<UserOrientService>().init(); } catch (e, st) { _logger.warning(...); }` after RevenueCat init (line ~87), before `AuthService.init()` (line 88)
- No dispose chain entry — service has no disposable resources
- Add `MockUserOrientService` to `test/mocks/mock_services.dart`

## Key context
- **v2.1.0 breaking change**: `configure()` no longer accepts `languageCode`. Must use `UserOrient.setLanguage(Language.en)` separately.
- `init()` is synchronous — no `await`, no `Completer`, no async race conditions. Both `openBoard()` and `clearCache()` guard on `_isInitialized`.

## Acceptance
- [ ] `userorient_flutter: ^2.1.0` in pubspec.yaml, `flutter pub get` succeeds
- [ ] `USERORIENT_API_KEY` added to `env/default.env.json` with placeholder value
- [ ] `UserOrientService` created with `void init()`, `void openBoard(...)`, `Future<void> clearCache()`
- [ ] Platform guard: `init()` is a no-op on web/unsupported platforms (`kIsWeb` / non-iOS/Android), `_isInitialized` stays `false`
- [ ] Empty API key guard: logs warning, sets `_isInitialized = false` (no crash)
- [ ] `setLanguage(Language.en)` called (not via deprecated `languageCode` param)
- [ ] `setTheme()` called with light + dark `UserOrientColors` mapped from app palette
- [ ] Service registered in `locator_config.dart` as lazy singleton
- [ ] `UserOrientService` injected into `AuthService` constructor (same pattern as `RevenueCatService`)
- [ ] `init()` called synchronously in `startup_view_model.dart`: `try { locator<UserOrientService>().init(); } catch ...`
- [ ] `MockUserOrientService` added to `test/mocks/mock_services.dart`
- [ ] `flutter analyze` passes, existing tests pass

## Done summary
Added userorient_flutter v2.1.0 dependency, created UserOrientService wrapper with platform/API-key guards, registered in DI, injected into AuthService, and wired synchronous init in startup sequence.
## Evidence
- Commits: 9e24457c6d4feb9e4e90df43e7bca5e54744f603
- Tests: flutter analyze, flutter test
- PRs: