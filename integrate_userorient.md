# Implementation Plan: UserOrient Integration (Feature Request)

**Spec:** `docs/specs/20260315140000_spec_userorient_integration.md`
**UI Design:** Feature Request tile already exists — no new UI, only wiring the tap action

---

## Phase 1 — Add Package & Environment Key

### 1.1 Add `userorient_flutter` dependency

- **File:** `pubspec.yaml`
- Add `userorient_flutter: ^2.1.0` under `dependencies` (after existing deps around line 66)
- Run `flutter pub get` — verify no version conflicts with transitive deps (`device_info_plus`, `package_info_plus`, `shared_preferences`, `url_launcher`)

### 1.2 Add `USERORIENT_API_KEY` to environment template

- **File:** `env/default.env.json`
- Add `"USERORIENT_API_KEY": "<Key from UserOrient dashboard>"` after the existing `REVENUECAT_API_KEY` entry (line 4)
- Pattern: matches existing `REVENUECAT_API_KEY` placeholder style (see `env/default.env.json:4`)
- Developer must also add the real key to their local `env/env.json` (gitignored)

---

## Phase 2 — Create `UserOrientService` Wrapper

### 2.1 Create the service file

- **File:** `lib/core/utils/userorient/userorient_service.dart` (new)
- Thin static wrapper — follows `RevenueCatService` pattern (`lib/paywall/data/revenuecat_service.dart:37-60`)
- Three public methods — all with explicit signatures:
  - `void init()` — **synchronous**. Guards unsupported platforms (`kIsWeb` or non-iOS/Android `defaultTargetPlatform`) with debug log + early return. Reads API key via `const String.fromEnvironment('USERORIENT_API_KEY')`, guards empty key with warning log + early return (see RevenueCat empty-key pattern at `revenuecat_service.dart:148`), calls:
    - `UserOrient.configure(apiKey: apiKey)`
    - `UserOrient.setLanguage(Language.en)` — **NOT** via deprecated `languageCode` param (v2.1.0 breaking change)
    - `UserOrient.setTheme(light: ..., dark: ...)` — map from `KitColorsExtension` (see Phase 2.2)
    - Sets `_isInitialized = true` on success
  - `void openBoard(BuildContext context, {required String userId, required bool isPaying})` — guards `_isInitialized` (returns immediately if `false`), calls `UserOrient.setUser(uniqueIdentifier: userId, isPaying: isPaying)` then `UserOrient.openBoard(context)`. Lazy `setUser()` before each `openBoard()` per design decision.
  - `Future<void> clearCache()` — guards `_isInitialized` (returns `Future.value()` if `false`), calls `UserOrient.clearCache()`. Returns the future for callers that want to await it.
- Internal state: `bool _isInitialized = false` (no `Completer` — init is synchronous, no async race conditions)

### 2.2 Theme mapping

- Called inside `init()` via `UserOrient.setTheme()`
- Color mapping from `KitColorsExtension` (`lib/core/ui/constants/kit_colors.dart`):
  - **Light mode:** `UserOrientColors(backgroundColor: kitColors.neutral100, accentColor: kitColors.neutral950)`
  - **Dark mode:** `UserOrientColors(backgroundColor: kitColors.background, accentColor: kitColors.brandSky)`
- Source for color roles: `lib/core/ui/app_theme.dart:44-61` — `surface` and `primary` color assignments per brightness
- `KitColorsExtension` is a const class — instantiate directly: `const KitColorsExtension()`

### 2.3 Add `MockUserOrientService`

- **File:** `test/mocks/mock_services.dart`
- Add `MockUserOrientService` (mocktail mock) for downstream unit tests
- Follows existing mock pattern in the file

### 2.4 Platform scope

- `userorient_flutter` supports **iOS and Android only**. The repo has `web/` and `macos/` targets.
- `init()` adds an early-return platform guard (`kIsWeb` or unsupported `defaultTargetPlatform`) before calling any SDK methods. On unsupported platforms, logs a debug message and leaves `_isInitialized = false`.
- `openBoard()` and `clearCache()` already guard on `_isInitialized` — no additional per-method guards needed.
- This avoids conditional imports or stub classes while keeping `flutter analyze` and `flutter build web` clean.

---

## Phase 3 — Register in DI & Inject into AuthService

### 3.1 Register `UserOrientService` in locator

- **File:** `lib/config/locator_config.dart`
- Add import: `import 'package:neurostack/core/utils/userorient/userorient_service.dart';`
- Add `Module<UserOrientService>` as a lazy singleton, placed after `RevenueCatService` registration (after line 68):
  ```
  Module<UserOrientService>(
    builder: () => UserOrientService(),
    lazy: true,
  ),
  ```

### 3.2 Inject `UserOrientService` into `AuthService`

- **File:** `lib/config/locator_config.dart` (line 177-189, `AuthService` module)
- Add `userOrientService: locator<UserOrientService>()` to `AuthService` constructor call
- Pattern: same as `revenueCatService: locator<RevenueCatService>()` already on line 186
- **File:** `lib/features/auth/data/auth_service.dart` — add `UserOrientService` constructor parameter and `_userOrientService` field

### 3.3 Initialize at app startup

- **File:** `lib/startup/startup_view_model.dart`
- Add import for `UserOrientService`
- Call `init()` after RevenueCat init block (after line 86), before auth init (line 88):
  ```
  // Init UserOrient (synchronous, non-blocking)
  try {
    locator<UserOrientService>().init();
  } catch (e, st) {
    _logger.warning('UserOrient init failed', e, st);
  }
  ```
- `init()` is **synchronous** — no `await` needed. Wrapped in try-catch with `_logger.warning()`.
- If init fails, app continues — Feature Request tap becomes a no-op via `_isInitialized` guard.
- No dispose chain entry — `UserOrientService` has no disposable resources (no listeners, no subscriptions, no notifiers).

---

## Phase 4 — Wire Feature Request Tap via ViewModel

### 4.1 Add `UserOrientService` to `SettingsViewModel` and `openFeatureRequestBoard` method

- **File:** `lib/settings/settings_view_model.dart`
- Add `UserOrientService` as a constructor parameter (same pattern as other deps at `settings_view_model.dart:21-39` — constructor injection, not `locator<>()`)
- Add `openFeatureRequestBoard(BuildContext context)` method that encapsulates all business logic:
  1. Extracts user ID from `_authService.authState.value` via pattern match: `AuthenticatedOnline(user)` / `AuthenticatedOffline(user)` — see `lib/features/auth/domain/auth_state.dart:19-29`
  2. If not authenticated, returns early (no-op guard)
  3. Derives `isPaying` from `_resolver.resolveEffectiveStatus(user: user, snapshot: _revenueCatService.entitlementSnapshot.value).isPremium` — see `lib/features/user/domain/enums/subscription_status.dart` for `isPremium` getter
  4. Calls `_userOrientService.openBoard(context, userId: user.id, isPaying: isPaying)`
- All deps are constructor-injected — consistent with existing ViewModel pattern

### 4.2 Delegate tap from view to ViewModel

- **File:** `lib/settings/settings_view.dart` (line 108)
- **Current:** `onFeatureRequestTap: () {}, // TODO: Wiredash`
- **Replace with:** `onFeatureRequestTap: () => _viewModel.openFeatureRequestBoard(context),`
- **ViewModel construction** (`settings_view.dart:31-37`): add `userOrientService: locator<UserOrientService>()` to constructor call
- `BuildContext` is available from the `ValueListenableBuilder` builder at line 88
- `onFeatureRequestTap` stays `VoidCallback` — no signature change to `SettingsSupportSection` (`lib/settings/widgets/settings_support_section.dart:38`)
- View remains a thin delegate — all logic in ViewModel

---

## Phase 5 — Logout & Auth Event Cleanup

### 5.1 Add `clearCache()` to explicit logout

- **File:** `lib/features/auth/data/auth_service.dart` (line 85, `logout()` method)
- Add after RevenueCat logout (line 91), before Supabase signOut (line 93):
  ```
  // Clear UserOrient cached user data (best-effort, awaited like RevenueCat)
  try {
    await _userOrientService.clearCache();
  } catch (e, st) {
    _logger.fine('UserOrient clearCache skipped: $e', e, st);
  }
  ```
- `_userOrientService` is constructor-injected (done in Phase 3.2)
- Pattern: mirrors RevenueCat logout at lines 87-91 — `await` with try-catch, best-effort

### 5.2 Add `clearCache()` to signedOut auth event

- **File:** `lib/features/auth/data/auth_service.dart` (`_handleAuthChange()` method, signedOut case ~line 158)
- Add after RevenueCat logout in the same block:
  ```
  unawaited(
    _userOrientService.clearCache().catchError((e, st) {
      _logger.fine('UserOrient clearCache skipped: $e', e, st);
    }),
  );
  ```
- This is the implicit sign-out path (token revocation, server-side logout) — uses `unawaited()` with `.catchError()` on the future chain, matching the existing RevenueCat pattern at lines 160-167. Note: `try-catch` does NOT catch async errors from unawaited futures — must use `.catchError()`.
- Without this, UserOrient cache survives account switches via implicit sign-out

---

## Phase 6 — Unit Tests

### 6.1 SettingsViewModel tests (board-opening behavior)

- **File:** `test/settings/settings_view_model_test.dart`
- Test: authenticated tap calls `openBoard` on `MockUserOrientService` with correct `userId` and `isPaying`
- Test: unauthenticated auth state (e.g., `Unauthenticated()`) → tap is no-op, `openBoard` never called
- Test: `isPaying` derived from `SubscriptionStatus.isPremium` — premium user gets `true`, free user gets `false`
- Uses `MockUserOrientService` from `test/mocks/mock_services.dart`

### 6.2 AuthService tests (cleanup in both logout paths)

- **File:** `test/features/auth/data/auth_service_test.dart`
- Test: `logout()` triggers `clearCache()` on `MockUserOrientService`
- Test: `signedOut` auth event triggers `clearCache()` on `MockUserOrientService`
- Uses `MockUserOrientService` from `test/mocks/mock_services.dart`

---

## Phase 7 — Update Documentation

### 7.1 Update settings screen spec

- **File:** `docs/specs/20260227120000_spec_settings_screen.md`
- **Tile Definitions table** (line 79-83): update to list ALL 5 currently rendered tiles:
  | # | Label | Icon | Trailing | Action | Visibility |
  |---|-------|------|----------|--------|------------|
  | 1 | Contact Us | `LucideIcons.mail` | Chevron | Navigates to `/settings/contact` | Always |
  | 2 | Send Feedback | `LucideIcons.messageSquare` | Chevron | **Placeholder (no-op, pending Wiredash)** | Always |
  | 3 | Rate the App | `LucideIcons.star` | External-link | **Placeholder (no-op, pending App Store rating)** | Always |
  | 4 | Feature Request | `LucideIcons.lightbulb` | Chevron | Opens UserOrient board (`UserOrient.openBoard`) | Always |
  | 5 | Cancel Subscription | `LucideIcons.creditCard` | External-link | Opens platform subscription management | Premium only |
- **Dependencies section** (line 125): add `userorient_flutter: ^2.1.0` — needed for Feature Request (UserOrient board)
- **Note** (line 84): update to reflect Feature Request is now functional via UserOrient. Clarify that Send Feedback and Rate the App tiles exist in code as placeholder tiles with no-op callbacks (`settings_support_section.dart:57-69`), pending Wiredash and App Store rating integrations respectively.
- **Out of Scope section** (line 140): remove Feature Request from the list. Keep Send Feedback (pending Wiredash) and Rate the App (pending App Store). Add note that these tiles exist in code as placeholders.

### 7.2 Update settings screen prompt

- **File:** `docs/best_practices/design/screen-prompts/11-settings-screen.md`
- **Tile definitions table** (line 39-43): update to list ALL 5 currently rendered tiles:
  | Label | Icon | Trailing | Visibility |
  |-------|------|----------|------------|
  | Contact Us | mail | chevron-right | Always |
  | Send Feedback | message-square | chevron-right | Always (placeholder) |
  | Rate the App | star | external-link | Always (placeholder) |
  | Feature Request | lightbulb | chevron-right | Always |
  | Cancel Subscription | credit-card | external-link | Premium only |

---

## Files Changed (Summary)

| File | Action | Phase |
|------|--------|-------|
| `pubspec.yaml` | Edit — add `userorient_flutter: ^2.1.0` | 1.1 |
| `env/default.env.json` | Edit — add `USERORIENT_API_KEY` placeholder | 1.2 |
| `lib/core/utils/userorient/userorient_service.dart` | **New** — thin SDK wrapper | 2.1 |
| `test/mocks/mock_services.dart` | Edit — add `MockUserOrientService` | 2.3 |
| `lib/config/locator_config.dart` | Edit — register `UserOrientService`, inject into `AuthService` | 3.1-3.2 |
| `lib/features/auth/data/auth_service.dart` | Edit — add constructor param, `clearCache()` in `logout()` AND `_handleAuthChange(signedOut)` | 3.2, 5.1-5.2 |
| `lib/startup/startup_view_model.dart` | Edit — call `init()` in startup sequence | 3.3 |
| `lib/settings/settings_view_model.dart` | Edit — add `UserOrientService` constructor param + `openFeatureRequestBoard(context)` | 4.1 |
| `lib/settings/settings_view.dart` | Edit — delegate `onFeatureRequestTap` to ViewModel (line 108) | 4.2 |
| `test/settings/settings_view_model_test.dart` | Edit — add tests for board-opening behavior | 6.1 |
| `test/features/auth/data/auth_service_test.dart` | Edit — add tests for cleanup in both logout paths | 6.2 |
| `docs/specs/20260227120000_spec_settings_screen.md` | Edit — list all 5 rendered tiles, add dep, clarify placeholder tiles | 7.1 |
| `docs/best_practices/design/screen-prompts/11-settings-screen.md` | Edit — update tile table to list all 5 rendered tiles | 7.2 |

---

## Testing Notes

- **Unit tests (Phase 6):** authenticated tap opens board, unauthenticated tap is no-op, isPaying derived correctly, logout/signedOut triggers clearCache
- **Smoke test:** Run app, navigate to Settings, tap Feature Request — verify board opens with correct user
- **Empty key:** Remove `USERORIENT_API_KEY` from `env/env.json`, run app — verify no crash, warning logged, tap is a no-op
- **Web build:** `flutter build web --dart-define-from-file=env/env.json` — verify no compile errors, `init()` is a no-op via platform guard
- **Logout:** Log out, verify no errors from `clearCache()`
- **Existing tests:** `flutter test` must pass (no regressions)
- **Analyze:** `flutter analyze` must pass

---

## Key References

| Reference | Location |
|-----------|----------|
| userorient_flutter docs | [pub.dev](https://pub.dev/packages/userorient_flutter) |
| v2.1.0 breaking change | [changelog](https://pub.dev/packages/userorient_flutter/changelog) — `configure()` no longer accepts `languageCode` |
| RevenueCat service pattern | `lib/paywall/data/revenuecat_service.dart` |
| AuthService DI injection | `lib/config/locator_config.dart:177-189` |
| Auth signedOut handler | `lib/features/auth/data/auth_service.dart:158` |
| Startup init sequence | `lib/startup/startup_view_model.dart:58-111` |
| Settings ViewModel | `lib/settings/settings_view_model.dart` |
| Settings view tap site | `lib/settings/settings_view.dart:108` |
| Support section widget | `lib/settings/widgets/settings_support_section.dart:71-76` |
| Auth state sealed class | `lib/features/auth/domain/auth_state.dart` |
| Subscription isPremium | `lib/features/user/domain/enums/subscription_status.dart` |
| App theme colors | `lib/core/ui/app_theme.dart:44-77` |
| KitColors constants | `lib/core/ui/constants/kit_colors.dart` |
| Locator config | `lib/config/locator_config.dart` |
| Env template | `env/default.env.json` |
| Settings screen spec | `docs/specs/20260227120000_spec_settings_screen.md` |
| Settings screen prompt | `docs/best_practices/design/screen-prompts/11-settings-screen.md` |
| Mock services | `test/mocks/mock_services.dart` |
