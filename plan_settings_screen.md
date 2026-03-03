# Implementation Plan: Settings Screen

**Spec:** `docs/specs/20260227120000_spec_settings_screen.md`
**UI Design:** `docs/best_practices/design/screen-prompts/11-settings-screen.md`
**Figma:** `docs/design_screenshots/11-settings.png`

---

## Phase 1 — Bottom Navigation (4th Tab)

### 1.1 Add `settings` to the bottom tab enum ✅

- **File:** `lib/core/models/home_bottom_tab.dart`
- Add `settings` as the 4th value: `enum HomeBottomTab { stack, library, progress, settings }`

### 1.2 Fix enum exhaustiveness across codebase ✅

- Search for all exhaustive switch/map usage of `HomeBottomTab` and add the `settings` case.
- **Known impacted files:**
  - `lib/home/home_bottom_tab_coordinator.dart` — add routing case (Phase 1.3)
  - `lib/home/widgets/home_bottom_nav.dart` — add 4th nav item (Phase 1.4)
  - `lib/home/home_state.dart` — `activeTab` default is `HomeBottomTab.stack` (no change needed, but verify)
  - `lib/library/library_state.dart` — `activeTab` default is `HomeBottomTab.library` (no change needed, but verify)
- **Action:** Run `flutter analyze` after adding the enum value to catch any remaining exhaustiveness errors before proceeding.

### 1.3 Add Settings tab to `HomeBottomNav` widget ✅

- **File:** `lib/home/widgets/home_bottom_nav.dart`
- Add a 4th `_NavItem` after the Progress entry (around line 50):
  - `label: 'Settings'`
  - `icon: LucideIcons.settings`
  - `isActive: activeTab == HomeBottomTab.settings`
  - `onTap: () => onSelect(HomeBottomTab.settings)`

### 1.4 Add routing case to `HomeBottomTabCoordinator` ✅

- **File:** `lib/home/home_bottom_tab_coordinator.dart`
- Add case in `onSelect` switch (after line 25):
  ```dart
  case HomeBottomTab.settings:
    _routerService.replaceAll([Path(name: '/settings')]);
    break;
  ```

### 1.5 Remove gear icon from Progress screen ✅

- **File:** `lib/progress/progress_view.dart`
- Remove the `IconButton` with `LucideIcons.settings` (lines 219-229)
- Replace the header `Row(mainAxisAlignment: spaceBetween)` with just the `Column` containing the title and subtitle (remove the `Row` wrapper entirely since there's no longer a trailing widget)

---

## Phase 2 — SettingsViewModel Refactor

### 2.1 Add tab coordination and subscription awareness to `SettingsViewModel` ✅

- **File:** `lib/settings/settings_view_model.dart`
- Mix in `EntitlementListenerMixin` (same pattern as `LibraryViewModel` line 36):
  ```dart
  class SettingsViewModel with EntitlementListenerMixin {
  ```
- Accept via constructor:
  - `RouterService` — for navigation
  - `AuthService` — for resolving current user synchronously from `authState.value`
  - `SubscriptionStatusResolver` — for `resolveEffectiveStatus()`
  - `RevenueCatService` — for entitlement snapshot (also satisfies mixin's `entitlementListenerService`)
  - `CachedUserStore` — for offline user fallback (defensive, if authState unexpectedly unavailable)
  - `HomeBottomTabCoordinator` — for tab switching (optional, defaults to `HomeBottomTabCoordinator(routerService: routerService)`)
  - `Future<bool> Function(Uri, {LaunchMode mode}) launch` — injectable URL launcher, defaults to `launchUrl` (enables unit testing without platform binding mocking)
- Required mixin override (must be explicit for compilation):
  ```dart
  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;
  ```
- Expose `ValueNotifier<bool> isPremium`
- Compute initial `isPremium` **synchronously** in constructor/`init()` to avoid flicker (spec says "no loading states"):
  1. Extract user from `_authService.authState.value` — route requires auth, so `AuthenticatedOnline` or `AuthenticatedOffline` is guaranteed. Fall back to `CachedUserStore` only if authState is unexpectedly `AuthUnknown`/`Unauthenticated`.
  2. Compute: `_resolver.resolveEffectiveStatus(user: user, snapshot: _revenueCatService.entitlementSnapshot.value).isPremium`
  3. Initialize `isPremium` with this value immediately (no async gap)
- Add `init()` method: call `initEntitlementListener()` to subscribe to live updates
- Implement `onEntitlementChanged()` (mixin callback): re-extract user from authState + re-compute `isPremium`
- Add `onSelectBottomTab(HomeBottomTab tab)` method:
  ```dart
  void onSelectBottomTab(HomeBottomTab tab) {
    _tabCoordinator.onSelect(tab, currentTab: HomeBottomTab.settings);
  }
  ```
- Add `goToPaywall()` method: `_routerService.goTo(Path(name: '/paywall'))`
- Add `goToContact()` method: `_routerService.goTo(Path(name: '/settings/contact'))`
- Add `openSubscriptionManagement()` method (see Phase 5.2) — delegates to injected `_launch` function
- Remove existing `RestoreResult` enum and `restorePurchases()` method
- Update `dispose()`: call `disposeEntitlementListener()`, dispose `isPremium` notifier

### User resolution helper

- Extract user synchronously from `AuthService.authState.value`:
  ```dart
  User? _resolveUser() {
    final authState = _authService.authState.value;
    return switch (authState) {
      AuthenticatedOnline(:final user) => user,
      AuthenticatedOffline(:final user) => user,
      _ => null,
    };
  }
  ```
- This avoids async SharedPreferences reads and the premium-state flicker on a screen with "no loading states"

### 2.2 Product decision: Restore Purchases ✅

- **Decision:** Restore Purchases is removed from Settings per spec.
- **Rationale:** RevenueCat SDK automatically restores on app launch via `configure()`. Manual restore is only needed as a recovery path for edge cases (device change, reinstall). The spec explicitly lists it as out of scope.
- **Future:** If re-added later, it can be a 6th tile in the Support section or moved to a debug/account screen.
- **Cleanup:** Update `RevenueCatService.restorePurchases()` docstring to remove "Must be exposed in Settings UI" (no longer accurate per spec).

### Source references for patterns
- EntitlementListenerMixin: `lib/core/abstractions/entitlement_listener_mixin.dart`
- Tab coordinator wiring: `lib/progress/progress_view_model.dart` (lines 49-53, 91-95)
- User resolution: `lib/core/utils/auth_helpers.dart` — `resolveCachedUser()` pattern
- Paywall navigation: `lib/library/library_view_model.dart` (lines 171-173)
- Subscription resolution: `lib/features/user/domain/enums/subscription_status.dart` (`isPremium` getter)
- Mixin usage: `lib/library/library_view_model.dart` (line 36, lines 94-104)

---

## Phase 3 — SettingsView Rewrite

### 3.1 Restructure `SettingsView` as a tab screen ✅

- **File:** `lib/settings/settings_view.dart`
- Replace current pushed-route layout (back button header) with tab-screen layout
- Wrap in `AppGridBackground` > `Scaffold(backgroundColor: transparent)` > `SafeArea(bottom: false)` (match tab-screen pattern from `LibraryView` line 78-79)
- Use `Stack` with:
  - Scrollable content area: `CustomScrollView` with `PageStorageKey('settings-scroll')` for scroll position retention across tab switches
  - `Positioned` bottom nav: `HomeBottomNav(activeTab: HomeBottomTab.settings, onSelect: _viewModel.onSelectBottomTab)`
  - Fake home indicator pill (same pattern as `ProgressView` lines 127-143)
- Add trailing `SizedBox(height: 120 + bottomInset)` spacer in scroll content
- Update `_viewModel` initialization to pass all new constructor dependencies from `locator<>()`
- In `initState()`, call `_viewModel.init()` to start entitlement listener; in `dispose()`, call `_viewModel.dispose()` (mirrors Home/Library pattern)

### 3.2 Screen header ✅

- **File:** `lib/settings/settings_view.dart`
- Title: "Settings" using `textTheme.headlineLarge` with `fontSize: 32, fontStyle: FontStyle.italic, letterSpacing: -0.8, color: kitColors.white90`
- Padding: `EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0)` (px-6, pt-6)
- No back button, no row — standalone `Text` widget

### Source reference
- Existing header style: `lib/settings/settings_view.dart` (lines 56-63) — reuse the text style, drop the `Row` + `IconButton`

### 3.3 Upgrade banner widget ✅

- **File:** `lib/settings/widgets/settings_upgrade_banner.dart` (new)
- Conditional: only render when `!isPremium`
- Container: `BoxDecoration` with `color: Colors.white.withOpacity(0.02)`, `borderRadius: BorderRadius.circular(24)`, `border: Border.all(color: kitColors.brandSky.withOpacity(0.3))`
- Content row: crown icon (32px, brandSky, shadow glow) + column (headline + subtitle) + chevron
- Wrap in `GestureDetector` or `InkWell` → calls `_viewModel.goToPaywall()`
- Padding: `EdgeInsets.symmetric(horizontal: spacing.lg)`, top margin: `spacing.xl` (mt-8 = 32)

### 3.4 Support & Resources section ✅

- **File:** `lib/settings/widgets/settings_support_section.dart` (new)
- Section header: uppercase "SUPPORT & RESOURCES" label with `textTheme.labelSmall` or custom Inter mono style, `kitColors.white40`, letterSpacing 0.15em
- Tile container: `BoxDecoration` with `color: Colors.white.withOpacity(0.02)`, `borderRadius: BorderRadius.circular(24)`, `border: Border.all(color: kitColors.white10)`
- Contains a `Column` of `SettingsTile` widgets with dividers between (1px `white5`, mx-5)

### 3.5 Settings tile widget ✅

- **File:** `lib/settings/widgets/settings_tile.dart` (new)
- Reusable tile: accepts `icon` (leading), `label`, `trailing` (chevron or external-link), `onTap`, `isVisible` (defaults true)
- Layout: `Row` with leading icon (20px, `white40`, strokeWidth 1.5) + label (`Inter 15px, w400, white80`, flex-1) + trailing icon (16px, `white20`)
- Press state: `bg-white/[0.03]` via `Material` + `InkWell` with 200ms transition
- Touch target: min 56px height, full width
- Padding: `px-5, py-4` (20h, 16v)
- Settings-only widget, not extracted to core/shared

### 3.6 Wire up the 5 tiles ✅

| Tile | Leading Icon | `onTap` | Trailing | Visibility |
|------|-------------|---------|----------|------------|
| Contact Us | `LucideIcons.mail` | `_viewModel.goToContact()` | `LucideIcons.chevronRight` | Always |
| Send Feedback | `LucideIcons.messageSquare` | no-op (TODO) | `LucideIcons.chevronRight` | Always |
| Rate the App | `LucideIcons.star` | no-op (TODO) | `LucideIcons.externalLink` | Always |
| Feature Request | `LucideIcons.lightbulb` | no-op (TODO) | `LucideIcons.chevronRight` | Always |
| Cancel Subscription | `LucideIcons.creditCard` | `_viewModel.openSubscriptionManagement()` | `LucideIcons.externalLink` | `isPremium` only |

### 3.7 Animations ✅

- Use existing `StaggeredFadeIn` widget (`lib/core/ui/widgets/staggered_fade_in.dart`) for entrance animations:
  - Wrap upgrade banner in `StaggeredFadeIn(index: 0, child: ...)`
  - Wrap support section in `StaggeredFadeIn(index: 1, child: ...)`
- Tile press: per spec, `scale(0.99)` on active with 150ms animation. Use a single gesture surface — `InkResponse` with `onHighlightChanged` driving `AnimatedScale` — to avoid double-handling taps. Highlight color `Colors.white.withOpacity(0.03)` for visual feedback

### Source reference for animation patterns
- `StaggeredFadeIn` widget: `lib/core/ui/widgets/staggered_fade_in.dart` — already used by Home and Library views
- Existing usage: `lib/home/home_view.dart`, `lib/library/library_view.dart`

---

## Phase 4 — Contact Us Placeholder Page

### 4.1 Create `ContactView` ✅

- **File:** `lib/settings/contact_view.dart` (new)
- Bare scaffold: `AppGridBackground` > `Scaffold` > `SafeArea`
- Header: back chevron (`LucideIcons.chevronLeft`) + "Contact Us" title (Newsreader italic, 32px)
- Back button: `locator<RouterService>().back()`
- No bottom nav (pushed route)
- Body: empty (placeholder for future content)

### 4.2 Register `/settings/contact` route ✅

- **File:** `lib/config/route_config.dart`
- Add import: `import 'package:neurostack/settings/contact_view.dart';`
- Add new `RouteEntry`:
  ```dart
  RouteEntry(
    path: '/settings/contact',
    requiresAuth: true,
    builder: (key, routeData) => const ContactView(),
  ),
  ```

---

## Phase 5 — Add `url_launcher` Dependency

### 5.1 Add package ✅

- **File:** `pubspec.yaml`
- Add `url_launcher: ^6.3.1` under dependencies
- Run `flutter pub get`

### 5.2 Use in ViewModel ✅

- **File:** `lib/settings/settings_view_model.dart`
- `openSubscriptionManagement()` with platform branching, delegates to injected `_launch`:
  ```dart
  Future<void> openSubscriptionManagement() async {
    final uri = defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse('https://play.google.com/store/account/subscriptions')
        : Uri.parse('https://apps.apple.com/account/subscriptions');
    await _launch(uri, mode: LaunchMode.externalApplication);
  }
  ```
- Uses `defaultTargetPlatform` from `package:flutter/foundation.dart` (already available)
- Calls `_launch` directly (https URLs are always launchable; `canLaunchUrl` produces false negatives on some platforms)
- `_launch` defaults to `launchUrl` from `url_launcher`, overridable in tests via constructor injection
- Web guard: if `kIsWeb`, use `LaunchMode.platformDefault` instead of `externalApplication` (web doesn't support external mode)

---

## Phase 6 — Update `docs/README.md`

### 6.1 Add spec link

- **File:** `docs/README.md`
- Under `## Feature Specs`, add:
  ```
  - [Spec: Settings Screen](./specs/20260227120000_spec_settings_screen.md) - SettingsView, 4th bottom tab, upgrade banner, support tiles, contact page, subscription management
  ```

### 6.2 Add screen prompt link

- **File:** `docs/README.md`
- Under `### Screen Prompts`, add:
  ```
  - [Settings Screen](./best_practices/design/screen-prompts/11-settings-screen.md) - settings, support, contact, upgrade banner, cancel subscription, rate app, feedback
  ```

### 6.3 Add plan link

- **File:** `docs/README.md`
- Under `## Implementation Plans`, add:
  ```
  - [Plan: Settings Screen](../plan_settings_screen.md) - Settings tab, upgrade CTA, support tiles, contact page, url_launcher, bottom nav 4th tab
  ```

---

## Files Changed (Summary)

| File | Action |
|------|--------|
| `lib/core/models/home_bottom_tab.dart` | Edit — add `settings` |
| `lib/home/widgets/home_bottom_nav.dart` | Edit — add 4th `_NavItem` |
| `lib/home/home_bottom_tab_coordinator.dart` | Edit — add `settings` case |
| `lib/progress/progress_view.dart` | Edit — remove gear icon, simplify header to `Column` only |
| `lib/settings/settings_view_model.dart` | Rewrite — EntitlementListenerMixin, tab coordinator, subscription, navigation |
| `lib/settings/settings_view.dart` | Rewrite — tab screen layout, banner, tiles, bottom nav, PageStorageKey |
| `lib/settings/widgets/settings_upgrade_banner.dart` | New |
| `lib/settings/widgets/settings_support_section.dart` | New |
| `lib/settings/widgets/settings_tile.dart` | New |
| `lib/settings/contact_view.dart` | New |
| `lib/config/route_config.dart` | Edit — add import + `/settings/contact` route |
| `pubspec.yaml` | Edit — add `url_launcher` |
| `docs/README.md` | Edit — add spec, prompt, plan links |

---

## Testing Notes

- **Unit test `HomeBottomTabCoordinator`:** verify `settings` case calls `replaceAll` with `/settings`
- **Unit test `SettingsViewModel`:**
  - Verify `isPremium` drives banner/tile visibility
  - Verify `goToPaywall` calls router with `/paywall`
  - Verify `openSubscriptionManagement` calls injected `launch` function with correct platform-specific URI and `LaunchMode.externalApplication`
  - **Live subscription update:** start as free user (isPremium = false), flip entitlement notifier to premium snapshot, assert `isPremium.value` updates to `true` without recreating the VM (mirrors `LibraryViewModel` test pattern in `test/library/library_view_model_test.dart`)
- **Widget test `SettingsView`:** verify upgrade banner shown/hidden based on subscription, 5 tiles render with correct leading icons, Cancel Subscription conditional on premium
- **Widget test `HomeBottomNav`:** verify 4 tabs render, Settings tab active state
- **Enum exhaustiveness:** `flutter analyze` must pass after Phase 1.1 changes before proceeding
