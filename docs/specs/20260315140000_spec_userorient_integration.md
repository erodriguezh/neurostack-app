# Spec: UserOrient Integration (Feature Request)

## Purpose

Integrate the `userorient_flutter` SDK (v2.1.0) into the Settings screen so users can submit and vote on feature requests via the existing "Feature Request" tile.

---

## Screen States

This integration adds no new screen states. The Feature Request tile is always visible (same as Contact Us). The UserOrient board is an SDK-managed overlay — no app-side loading/error states required.

---

## User Flow

1. User navigates to **Settings** tab
2. User taps **"Feature Request"** tile (`LucideIcons.lightbulb`, chevron-right trailing)
3. App extracts user ID from `AuthState` and determines `isPaying` from `SubscriptionStatus.isPremium`
4. App calls `UserOrient.setUser(uniqueIdentifier: userId, isPaying: isPaying)` then `UserOrient.openBoard(context)`
5. UserOrient board opens as a full-screen overlay (managed by SDK)
6. User browses, votes, or submits feature requests
7. User dismisses the board (SDK handles back navigation)

### Edge cases

| Case | Behavior |
|------|----------|
| User not authenticated (should not happen — route requires auth) | Tap is a no-op, guard on `AuthState` pattern match |
| API key missing/empty | `UserOrientService.init()` logs warning, skips `configure()`, leaves `_isInitialized = false`. `openBoard()` and `clearCache()` become no-ops. |
| Unsupported platform (web, macOS, etc.) | `UserOrientService.init()` detects `kIsWeb` or non-iOS/Android target, logs debug message, leaves `_isInitialized = false`. Entire service becomes inert — all methods are no-ops. |
| No network connectivity | SDK handles gracefully (shows cached content or error within its own UI) |
| User logs out (explicit) | `UserOrient.clearCache()` called in `AuthService.logout()` to prevent data leaking between accounts |
| User signed out (implicit, e.g. token revocation) | `UserOrient.clearCache()` called in `AuthService._handleAuthChange(signedOut)` — covers sign-out paths that bypass `logout()` |

---

## SDK API (v2.1.0)

### Breaking change from user-provided example

> `UserOrient.configure()` **no longer accepts `languageCode`** in v2.1.0. Must use `UserOrient.setLanguage(Language.en)` separately.
>
> Source: [userorient_flutter changelog](https://pub.dev/packages/userorient_flutter/changelog)

### Methods used

| Method | When called | Purpose |
|--------|------------|---------|
| `UserOrient.configure(apiKey:)` | App startup (once) | Initialize SDK with project key |
| `UserOrient.setLanguage(Language.en)` | App startup (once) | Set board language |
| `UserOrient.setTheme(light:, dark:)` | App startup (once) | Match app light/dark palette |
| `UserOrient.setUser(uniqueIdentifier:, isPaying:)` | Before each `openBoard()` | Identify current user lazily |
| `UserOrient.openBoard(BuildContext)` | On Feature Request tap | Show the feature request board |
| `UserOrient.clearCache()` | On logout | Clear cached user data |

---

## Architecture

### UserOrientService (thin wrapper)

- **Location:** `lib/core/utils/userorient/userorient_service.dart` (new file)
- **Pattern:** Follows `RevenueCatService` (`lib/paywall/data/revenuecat_service.dart`) — static SDK wrapper with init guard
- **Methods (explicit signatures):**
  - `void init()` — synchronous. Guards unsupported platforms (`kIsWeb` / non-iOS/Android) with debug log + early return. Guards empty API key with warning log + early return. On supported platforms with valid key, configures SDK, sets language, sets theme, sets `_isInitialized = true`.
  - `void openBoard(BuildContext, {required String userId, required bool isPaying})` — calls `setUser()` then `openBoard()`. No-ops if `!_isInitialized`.
  - `Future<void> clearCache()` — guards `_isInitialized` (returns `Future.value()` if `false`), calls `UserOrient.clearCache()`. Returns future for callers that want to await.
- **State:** `bool _isInitialized = false` (no `Completer` — init is synchronous, no async race conditions)

### Registration & Init

- **DI registration:** `lib/config/locator_config.dart` — register as lazy `Module<UserOrientService>`, inject into `AuthService` constructor
- **Startup init:** `lib/startup/startup_view_model.dart` — call `void init()` synchronously after RevenueCat init (line ~87), wrapped in try-catch + warning log. No `await` — init is synchronous.

### Tap wiring

- **ViewModel method:** `SettingsViewModel.openFeatureRequestBoard(BuildContext context)` encapsulates all business logic (auth state extraction, isPaying derivation, service call)
- **View delegation:** `settings_view.dart:108` delegates: `onFeatureRequestTap: () => _viewModel.openFeatureRequestBoard(context)`
- `BuildContext` is available from the `ValueListenableBuilder` builder at line 88
- `onFeatureRequestTap` remains `VoidCallback` (no signature change)
- Business logic stays in ViewModel — view is a thin delegate

### Theming

- Call `UserOrient.setTheme()` in `init()` with:
  - **Light:** `UserOrientColors(backgroundColor: kitColors.neutral100, accentColor: kitColors.neutral950)`
  - **Dark:** `UserOrientColors(backgroundColor: kitColors.background, accentColor: kitColors.brandSky)`
- Source: `lib/core/ui/app_theme.dart` (lines 44-77 for color mapping, lines 60-61 for primary colors)

### Logout & auth event cleanup

- `UserOrientService` is the sole integration surface — injected into `AuthService` via constructor (same pattern as `RevenueCatService`)
- `clearCache()` is called in TWO places:
  1. `AuthService.logout()` (line ~91) — explicit logout path, after RevenueCat logout, before Supabase signOut. **Awaited** best-effort cleanup with try-catch (same pattern as RevenueCat at `auth_service.dart:88`).
  2. `AuthService._handleAuthChange()` signedOut case (line ~158) — implicit sign-out path (token revocation, server-side logout). **Unawaited** with `.catchError()` on the future chain (matches existing RevenueCat pattern at `auth_service.dart:160-167`: `unawaited(_service.method().catchError(...))`). Note: `try-catch` does NOT catch async errors from unawaited futures — must use `.catchError()`.
- Without both paths, UserOrient cache can survive account switches via implicit sign-out

### User identification

- **Auth state:** `lib/features/auth/domain/auth_state.dart` — sealed class with `AuthenticatedOnline(User)` and `AuthenticatedOffline(User)`
- **User ID:** `user.id` (String, Supabase auth UUID)
- **isPaying:** `SubscriptionStatus.isPremium` — true for `premiumMonthly`, `premiumAnnual`, `grace`
- **Pattern match:** `switch` on `AuthState` to extract user, return early if not authenticated

---

## Environment

- **Key name:** `USERORIENT_API_KEY`
- **Template:** `env/default.env.json` — add `"USERORIENT_API_KEY": "<Key from UserOrient dashboard>"`
- **Access:** `const String.fromEnvironment('USERORIENT_API_KEY')` (same as `REVENUECAT_API_KEY` at `revenuecat_service.dart:148`)
- **Runtime:** passed via `--dart-define-from-file=env/env.json`

---

## Dependencies

- `userorient_flutter: ^2.1.0` — [pub.dev](https://pub.dev/packages/userorient_flutter)
- Transitive: `device_info_plus`, `package_info_plus`, `shared_preferences`, `url_launcher` (all likely already in dependency tree)

---

## Data Requirements

- `AuthService.authState` (`ValueNotifier<AuthState>`) — for user ID extraction
- `SubscriptionStatusResolver.resolveEffectiveStatus()` — for `isPaying` derivation
- `RevenueCatService.entitlementSnapshot` — input to status resolver

### Source references

- Auth state sealed class: `lib/features/auth/domain/auth_state.dart`
- Subscription status enum: `lib/features/user/domain/enums/subscription_status.dart` (`isPremium` getter)
- SubscriptionStatusResolver: `lib/paywall/domain/subscription_status_resolver.dart`
- Settings view model: `lib/settings/settings_view_model.dart` (already has all required dependencies injected)

---

## UI Specification

No new UI elements. The "Feature Request" tile already exists in `lib/settings/widgets/settings_support_section.dart` (line 71-76) with `LucideIcons.lightbulb` icon and `chevronRight` trailing. Only the `onTap` callback changes from no-op to opening the UserOrient board.

---

## Out of Scope

- "Rate the App" tile (remains pending App Store rating integration — exists in code as placeholder with no-op callback at `settings_support_section.dart:64-69`)
- Web / desktop platform support — `userorient_flutter` supports iOS and Android only. On unsupported targets (`kIsWeb` / non-iOS/Android), `UserOrientService` is an explicit no-op: `init()` returns early, `openBoard()` and `clearCache()` guard on `_isInitialized`. No conditional imports or stub classes needed.
- `UserOrient.setDataCollection()` configuration
- Reactive locale changes (English only, set once at startup)
- `UserOrient.openForm()` (only `openBoard()` is used)
