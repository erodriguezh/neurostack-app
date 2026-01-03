# Implementation Plan: Onboarding Flow

> **Spec:** `on_boarding_specs.md`
> **Depth:** STANDARD
> **Status:** Ready for Implementation

---

## Overview & Scope

Implement a 4-screen emotional onboarding flow (PAS → AIDA framework) that serves as the first experience for new users. The flow captures user attention, agitates the problem, presents the solution with trial offer, and builds trust via disclaimer.

**In Scope:**
- 4 onboarding screens with animations
- Shared scaffold with grid background and progress dots
- Page navigation with PageView + PageStorageKey for state preservation
- SharedPreferences flag for completion tracking (with migration for existing users)
- Startup flow integration (before auth init)
- Portrait orientation lock (with restore)
- Offline retry path (/offline route)

**Out of Scope:**
- Subscription/payment (handled post-auth)
- Analytics/tracking implementation
- A/B testing infrastructure
- Localization/i18n

---

## Approach

### Phase 1: Setup & Dependencies

**Task 1.1: Add dependencies**
```yaml
# pubspec.yaml - add to dependencies:
lucide_icons_flutter: ^3.1.9  # Value prop icons only
```
Run `flutter pub get`

**Note:** Prefer existing `CustomCurves` and implicit animations (`AnimatedOpacity`, `AnimatedSlide`) over `flutter_animate` and `sprung` to minimize dependencies.

**Task 1.2: Create folder structure**
```
lib/features/onboarding/
├── presentation/
│   ├── onboarding_view.dart
│   ├── onboarding_view_model.dart
│   ├── screens/
│   │   ├── hook_screen.dart
│   │   ├── agitate_screen.dart
│   │   ├── offer_screen.dart
│   │   └── disclaimer_screen.dart
│   └── widgets/
│       ├── onboarding_scaffold.dart
│       ├── onboarding_progress_dots.dart
│       ├── onboarding_ghost_button.dart
│       └── onboarding_checkbox.dart
└── data/
    └── onboarding_store.dart

# Note: Primary CTA uses shared AppPrimaryCta from core/ui/widgets/

lib/core/ui/widgets/
├── enum_page_view.dart          # Reusable page navigation
└── app_grid_background.dart     # Extract from auth/startup
```

**Task 1.3: Add route**
- File: `lib/config/route_config.dart` (after line 18)
- Add: `RouteEntry(path: '/onboarding', builder: (key, routeData) => const OnboardingView())`

---

### Phase 2: Extract Shared Core Widgets

**Task 2.1: AppGridBackground (DRY extraction)**
- Location: `lib/core/ui/widgets/app_grid_background.dart`
- Extract the grid painter logic from `AuthBackground` (`lib/features/auth/presentation/widgets/auth_background.dart`)
- **Layer boundary:** Extract only the painting logic (CustomPainter) - do NOT import from `startup/widgets`
- Props: `child`, `showTopGlow`, `glowColor` (default: brandSky/10)
- Update `AuthBackground` and `SplashGridBackground` to use the new shared painter
- Reusable across auth, startup, and onboarding

**Task 2.2: AppPrimaryCta (DRY extraction)**
- Location: `lib/core/ui/widgets/app_primary_cta.dart`
- Extract CTA styling from `AuthView` (`lib/features/auth/presentation/auth_view.dart:375-404`)
- Props: `label`, `onPressed`, `enabled`, `loading`, `showGlow`
- Includes haptic feedback (`HapticFeedback.lightImpact()`)

---

### Phase 3: Onboarding-Specific Components

**Task 3.1: OnboardingScaffold**
- Location: `lib/features/onboarding/presentation/widgets/onboarding_scaffold.dart`
- Wraps `AppGridBackground` with progress dots and safe area
- Props: `scrollableContent`, `bottomCta`, `currentStep` (0-3), `showTopGlow` (true only for Screen 3 / step index 2)
- **Layout pattern** (use CustomScrollView to avoid IntrinsicHeight performance issues):
```dart
Scaffold(
  body: SafeArea(
    child: Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: scrollableContent),
              // Flexible spacer that fills remaining space
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: false,
                child: SizedBox.shrink(),  // Empty spacer
              ),
            ],
          ),
        ),
        // Fixed bottom region (outside scroll)
        Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              progressDots,
              SizedBox(height: spacing.md),
              bottomCta,
            ],
          ),
        ),
      ],
    ),
  ),
)
```
- Bottom region stays fixed outside scroll
- Content scrolls only when it overflows viewport
- `SliverFillRemaining` provides spacing without `IntrinsicHeight` layout overhead
- Progress dots + CTA pinned together at bottom per spec §4

**Task 3.2: OnboardingProgressDots**
- Location: `lib/features/onboarding/presentation/widgets/onboarding_progress_dots.dart`
- Styling: 6px dots, 8px gap (`context.spacing.sm`), filled=white, empty=white/20
- Non-tappable (visual only per spec)

**Task 3.3: OnboardingGhostButton**
- Location: `lib/features/onboarding/presentation/widgets/onboarding_ghost_button.dart`
- Styling: Full width, h-14, rounded-full, bg-white/5, border white/10
- Props: `label`, `onPressed`
- Arrow icon animation: Use `CustomDurations.duration150` and `CustomCurves.easeOut`

**Task 3.4: OnboardingCheckbox**
- Location: `lib/features/onboarding/presentation/widgets/onboarding_checkbox.dart`
- Custom widget with: 24px size, rounded-lg, brand colors, scale animation on check
- Props: `value`, `onChanged`, `label`

---

### Phase 4: EnumPageView Widget (Reusable)

**Task 4.1: Create EnumPageView**
- Location: `lib/core/ui/widgets/enum_page_view.dart`
- Generic: `EnumPageView<T extends Enum>`
- Props: `value` (current enum), `values` (all enum values), `builder`
- **Animation mechanism:** Use `PageView` with `PageController` for true sliding animation:
```dart
class EnumPageView<T extends Enum> extends StatefulWidget {
  const EnumPageView({
    required this.value,
    required this.values,
    required this.builder,
    super.key,
  });

  final T value;
  final List<T> values;
  final Widget Function(T) builder;

  @override
  State<EnumPageView<T>> createState() => _EnumPageViewState<T>();
}

class _EnumPageViewState<T extends Enum> extends State<EnumPageView<T>> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.value.index);
  }

  @override
  void didUpdateWidget(EnumPageView<T> old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _controller.animateToPage(
        widget.value.index,
        duration: Duration(milliseconds: 750),
        curve: CustomCurves.emphasizedDecelerate,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();  // Clean up PageController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: NeverScrollableScrollPhysics(),  // Disable swipe
      children: widget.values.map((v) =>
        // Use PageStorageKey to preserve each page's state
        KeyedSubtree(
          key: PageStorageKey(v),
          child: widget.builder(v),
        ),
      ).toList(),
    );
  }
}
```
- **Scroll preservation:** `PageStorageKey` preserves scroll position per page (checkbox state lives in ViewModel - see Task 6.2)
- **True slide animation:** `animateToPage` provides smooth horizontal transition
- **Proper cleanup:** `_controller.dispose()` in `dispose()` method
- Physics disabled to prevent user swipe (navigation via CTAs only)
- **Note:** Removed unused `onPageChanged` prop - navigation is ViewModel-driven

---

### Phase 5: Individual Screens

**Task 5.1: HookScreen (Screen 1)**
- Location: `lib/features/onboarding/presentation/screens/hook_screen.dart`
- Animations: Staggered text reveal using `AnimatedOpacity` + `AnimatedSlide` with delays (0ms → 400ms → 700ms → 1000ms → 1500ms)
- **Skip behavior:** Wrap content in `GestureDetector` that sets all animations to complete state. **Exclude CTA area** from gesture detector to prevent tap conflicts.
- Use `CustomDurations.duration500` for fade-in
- Copy from spec Appendix A

**Task 5.2: AgitateScreen (Screen 2)**
- Location: `lib/features/onboarding/presentation/screens/agitate_screen.dart`
- Animations: Body paragraphs fade in with 200ms stagger using `AnimatedOpacity`
- Warning color for "go to die" text: `kitColors.warning`
- **Border note:** Per spec, Screen 2's secondary CTA uses `border: white/20` (not white/10 like other screens) for emphasis
- Copy from spec Appendix A

**Task 5.3: OfferScreen (Screen 3)**
- Location: `lib/features/onboarding/presentation/screens/offer_screen.dart`
- Background: Include top brandSky/10 glow (`showTopGlow: true`)
- Icons: `LucideIcons.eye`, `LucideIcons.flame`, `LucideIcons.sparkles`
- Two CTAs: Primary "Start my free trial", Secondary "Sign in instead"
- Both navigate to Screen 4 (no functional difference)

**Task 5.4: DisclaimerScreen (Screen 4)**
- Location: `lib/features/onboarding/presentation/screens/disclaimer_screen.dart`
- **Checkbox state comes from ViewModel** (`state.disclaimerAccepted`) - NOT local widget state
- This ensures checkbox state persists when navigating back and forward via PageView
- Icon: `LucideIcons.shieldCheck` or `LucideIcons.heartPlus`
- **CTA enabled wiring (CRITICAL):**
```dart
AppPrimaryCta(
  label: "Let's go",
  enabled: state.disclaimerAccepted,  // Checkbox gates the CTA
  onPressed: viewModel.completeOnboarding,
)
```
- On "Let's go": Call `viewModel.completeOnboarding()` (handles markCompleted, authService.init, and auth-state-based routing)
- **Do NOT navigate directly** - completeOnboarding() handles all routing based on auth state
- **Double-tap guard:** ViewModel maintains `_isCompleting` flag to prevent concurrent calls:
```dart
bool _isCompleting = false;

Future<void> completeOnboarding() async {
  if (_isCompleting) return;  // Guard against double-tap
  _isCompleting = true;
  try {
    // ... completion logic
  } finally {
    _isCompleting = false;
  }
}
```

---

### Phase 6: ViewModel & Main View

**Task 6.1: OnboardingStep Enum**
- Location: `lib/features/onboarding/presentation/onboarding_view_model.dart`
- Values: `hook`, `agitate`, `offer`, `disclaimer`

**Task 6.2: OnboardingViewModel**
- Location: `lib/features/onboarding/presentation/onboarding_view_model.dart`
- Pattern: Mirror `AuthViewModel` (single `ValueNotifier`, injected dependencies)
- Dependencies: `OnboardingStore`, `NavigationIntentStore`, `RouterService`, `AuthService`
- **State:** Single `ValueNotifier<OnboardingState>` per codebase rule (CLAUDE.md: "Single sealed state")
```dart
// Immutable state class
class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.hook,
    this.disclaimerAccepted = false,
  });

  final OnboardingStep currentStep;
  final bool disclaimerAccepted;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    bool? disclaimerAccepted,
  }) => OnboardingState(
    currentStep: currentStep ?? this.currentStep,
    disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
  );
}

// ViewModel exposes:
final ValueNotifier<OnboardingState> state = ValueNotifier(const OnboardingState());
```
- Methods:
  - `void goToStep(OnboardingStep step)` - updates `state.value = state.value.copyWith(currentStep: step)`
  - `void nextStep()`
  - `bool previousStep()` - returns `true` if step changed, `false` if already on first screen
  - `void setDisclaimerAccepted(bool value)` - updates `state.value = state.value.copyWith(disclaimerAccepted: value)`
  - `Future<void> completeOnboarding()`:
```dart
Future<void> completeOnboarding() async {
  try {
    await _store.markCompleted();
    await _navigationIntentStore.clearForceOnboarding();
    await _authService.init();

    // Handle all auth states explicitly
    final state = _authService.authState.value;
    switch (state) {
      case AuthenticatedOnline():
        // AuthService._handlePostAuthNavigation() handles this
        // It will consume intended route if present
        break;
      case AuthenticatedOffline():
        // Offline cached users - route to home
        // Clear intended route to prevent stale deep links being replayed later
        await _navigationIntentStore.clearIntendedRoute();
        _routerService.replaceAll([Path(name: '/')]);
        break;
      case OfflineNoUser():
        // No cached user, offline - route to dedicated offline screen
        await _navigationIntentStore.clearIntendedRoute();
        _routerService.replaceAll([Path(name: '/offline')]);
        break;
      case Unauthenticated():
        // Keep intended route - will be replayed after auth completes
        _routerService.replaceAll([Path(name: '/auth')]);
        break;
      default:
        // AuthUnknown, Authenticating - wait for auth to settle
        _routerService.replaceAll([Path(name: '/auth')]);
    }
  } catch (e) {
    // Auth init failed - route to auth and let user retry
    _routerService.replaceAll([Path(name: '/auth')]);
  }
}
```
- **NOTE:** Do NOT use `restartApp()` - it resets locator which desyncs RouterService
- Dispose: dispose the single `state` ValueNotifier

**Task 6.2b: Add /offline route with retry (REQUIRED)**
- File: `lib/config/route_config.dart`
- Add: `RouteEntry(path: '/offline', builder: (key, routeData) => const OfflineRetryView())`

**OfflineRetryViewModel (follows MVVM pattern per CLAUDE.md):**
- Location: `lib/features/offline/offline_retry_view_model.dart`
```dart
class OfflineRetryViewModel {
  OfflineRetryViewModel({
    required AuthService authService,
    required RouterService routerService,
    required NavigationIntentStore navigationIntentStore,
  })  : _authService = authService,
        _routerService = routerService,
        _navigationIntentStore = navigationIntentStore;

  final AuthService _authService;
  final RouterService _routerService;
  final NavigationIntentStore _navigationIntentStore;
  final ValueNotifier<bool> isRetrying = ValueNotifier(false);

  Future<void> retry() async {
    if (isRetrying.value) return;
    isRetrying.value = true;
    try {
      await _authService.init();

      final state = _authService.authState.value;
      switch (state) {
        case AuthenticatedOnline():
          // AuthService._handlePostAuthNavigation() handles this
          // Do NOT route - auth service already triggered navigation
          break;
        case AuthenticatedOffline():
          // Clear stale intended routes when manually routing to home
          await _navigationIntentStore.clearIntendedRoute();
          _routerService.replaceAll([Path(name: '/')]);
          break;
        case Unauthenticated():
          // Keep intended route - will be replayed after auth completes
          _routerService.replaceAll([Path(name: '/auth')]);
          break;
        case OfflineNoUser():
          // Still offline - stay on screen
          break;
        default:
          break;
      }
    } catch (e) {
      // Auth init failed - stay on screen for retry
      // No logging here per codebase pattern (failures returned via Either)
    } finally {
      isRetrying.value = false;
    }
  }

  void dispose() => isRetrying.dispose();
}
```

**OfflineRetryView:**
- Location: `lib/features/offline/offline_retry_view.dart`
- StatefulWidget that creates ViewModel in `initState`, disposes in `dispose`
- Uses `ValueListenableBuilder` to show loading state during retry
- **No direct service access** - follows "Views never use services directly" rule

**Task 6.3: OnboardingView**
- Location: `lib/features/onboarding/presentation/onboarding_view.dart`
- StatefulWidget that creates `OnboardingViewModel` in `initState`
- **Back navigation:** Wrap in `PopScope` with the following logic (per spec §2.5 "Android back works normally"):
```dart
ValueListenableBuilder<OnboardingState>(
  valueListenable: _viewModel.state,
  builder: (context, state, _) => PopScope(
    canPop: state.currentStep == OnboardingStep.hook,  // Allow system back on first screen
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;  // System handled it (first screen → exit)
      _viewModel.previousStep();  // Navigate back within onboarding
    },
    // EnumPageView MUST be built inside the builder to react to step changes
    child: EnumPageView<OnboardingStep>(
      value: state.currentStep,  // Current step from state
      values: OnboardingStep.values,
      builder: (s) => _buildScreen(s, state),  // Pass state to access disclaimerAccepted
    ),
  ),
)
```
- On first screen: `canPop: true` allows Android back to exit to launcher
- On screens 2-4: `canPop: false` intercepts back to navigate within onboarding
- **IMPORTANT:** EnumPageView must be inside the builder (not in `child` parameter) to receive step updates
- Use `ValueListenableBuilder` with `EnumPageView<OnboardingStep>`
- **Portrait lock:** Set in `initState`, restore in `dispose`:
```dart
@override
void initState() {
  super.initState();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _viewModel = OnboardingViewModel(...);
}

@override
void dispose() {
  SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  _viewModel.dispose();
  super.dispose();
}
```

---

### Phase 7: Data Layer & Integration

**Task 7.1: OnboardingStore**
- Location: `lib/features/onboarding/data/onboarding_store.dart`
- Pattern: Mirror `NavigationIntentStore` (`lib/core/utils/navigation/navigation_intent_store.dart`)
- Keys: `has_completed_onboarding`, `has_ever_launched`, `onboarding_migration_version` (consistent snake_case)
- API:
  - `Future<void> init()` - async migration, sets `isInitialized` when done
  - `bool get isInitialized` - gate for router guard race condition
  - `bool get isCompleted` - sync getter (cached after init)
  - `Future<void> markCompleted()` - sets completion flag

**Task 7.1b: Migration for Existing Users (CRITICAL)**
- **Problem:** Existing users will be forced through onboarding on app update
- **Solution:** Durable `has_ever_launched` marker + version-based migration with `isInitialized` gate:
```dart
class OnboardingStore {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  static const _hasCompletedKey = 'has_completed_onboarding';
  static const _hasEverLaunchedKey = 'has_ever_launched';  // Survives logout/cache clears
  static const _migrationVersionKey = 'onboarding_migration_version';
  static const _currentMigrationVersion = 1;  // Bump when migration logic changes

  bool _isInitialized = false;      // Gate for router guard race condition
  bool _isCompletedCached = false;  // Cached result for sync access

  /// Returns true once init() has completed - used by router guard
  bool get isInitialized => _isInitialized;

  /// Call once at startup before any routing
  Future<void> init() async {
    // Check persisted flag first
    if (_prefs.getBool(_hasCompletedKey) ?? false) {
      _isCompletedCached = true;
      _isInitialized = true;
      return;
    }

    // Durable marker: has_ever_launched survives logout and cache clears
    // This was seeded by pre-onboarding versions on first launch
    final hasEverLaunched = _prefs.getBool(_hasEverLaunchedKey) ?? false;

    // Version-based migration: runs once per migration version
    final storedVersion = _prefs.getInt(_migrationVersionKey) ?? 0;
    if (storedVersion < _currentMigrationVersion) {
      // Check for existing user signals (durable marker OR legacy data)
      // NOTE: intended_route is NOT included - guard now writes it on deep links
      final hasLegacyAppData = _prefs.getKeys().any((key) =>
        key == 'cached_user' ||
        key == 'auth_email'
      );

      if (hasEverLaunched || hasLegacyAppData) {
        // Existing user from pre-onboarding version - skip onboarding
        await markCompleted();
        // CRITICAL: Set migration version AFTER markCompleted() succeeds
        // This ensures migration retries if app crashes mid-migration
        await _prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
        _isCompletedCached = true;
        _isInitialized = true;
        return;
      }

      // New install - set migration version to prevent future migration attempts
      await _prefs.setInt(_migrationVersionKey, _currentMigrationVersion);
    }

    // NOTE: Do NOT set has_ever_launched here - it's only seeded by pre-onboarding releases
    // This ensures future migration bumps don't auto-complete for users who never finished onboarding

    // New install OR returning user who didn't have legacy data
    // Show onboarding - user must complete to set has_completed_onboarding
    _isCompletedCached = false;
    _isInitialized = true;
  }

  /// Sync access for routing guards - MUST call init() first
  bool get isCompleted => _isCompletedCached;

  Future<void> markCompleted() async {
    await _prefs.setBool(_hasCompletedKey, true);
    _isCompletedCached = true;
  }
}
```
- **Init/sync pattern:** `init()` runs migration once async, `isCompleted` is sync getter
- **Race-safe:** `isInitialized` gate prevents routing before init completes
- **Durable marker:** `has_ever_launched` survives logout and cache clears - seeded by pre-onboarding versions
- **Crash-safe migration:** Migration version written AFTER `markCompleted()` succeeds, so crash retries work
- **Layered detection:** Checks durable marker OR legacy app data (cached_user, auth_email only - NOT intended_route which guard now writes)
- **Cache corruption tolerant:** Users with cleared cache but `has_ever_launched` still skip onboarding
- **App kill safe:** New installs won't auto-complete - must complete onboarding to set flag
- **Future-proof:** `has_ever_launched` is ONLY set by pre-onboarding releases (see Task 7.1c); new installs with onboarding don't set it, so future migration bumps won't auto-complete for users who never finished

**Task 7.1c: Pre-Onboarding Seed Release (REQUIRED before onboarding release)**
- **Purpose:** Seed `has_ever_launched` for existing installs before onboarding feature ships
- **Location:** Add to `StartupViewModel.initializeApp()` in a SEPARATE release BEFORE onboarding
```dart
// Add to initializeApp() in pre-onboarding release ONLY (remove after onboarding ships):
if (!(_sharedPreferences.getBool('has_ever_launched') ?? false)) {
  await _sharedPreferences.setBool('has_ever_launched', true);
}
```
- **Deployment sequence:**
  1. Ship seed release (sets `has_ever_launched` for all existing users)
  2. Wait for 95%+ of users to update
  3. Ship onboarding release (migration checks `has_ever_launched`)
- **Seed-window trade-off:** NEW users who install during the seed-release window will have `has_ever_launched` set and will skip onboarding. This is an acceptable trade-off for a small cohort during a short deployment window. For a larger window, consider version tracking: store `install_version` and only auto-complete when `install_version < onboarding_release_version`.
- **Alternative:** If staged rollout isn't possible, accept that logged-out existing users without cached_user/auth_email will see onboarding (document in release notes)

**Task 7.2: Register in Locator**
- File: `lib/config/locator_config.dart`
- Add: `Module<OnboardingStore>(builder: () => OnboardingStore(locator<SharedPreferences>()), lazy: true)`

**Task 7.3: Modify StartupViewModel (CRITICAL ORDER)**
- File: `lib/startup/startup_view_model.dart`
- **Move onboarding check BEFORE auth init** to prevent auth-driven navigation override:

**Task 7.3b: Add Router-Level Onboarding Guard (Injected Callback)**
- **Problem:** Direct `locator<OnboardingStore>()` in RouterService creates core→feature dependency
- **Solution:** Inject a lightweight gate callback

**Step 1:** Add optional gate callback to existing `RouterService` constructor:
```dart
class RouterService {
  RouterService({
    required this.supportedRoutes,  // Existing parameter
    this.routeGuard,  // NEW: optional gate callback
  });

  final bool Function(String path)? routeGuard;  // Returns true if allowed
```

**Step 2:** Apply guard with stack-clearing semantics:
```dart
// In _resolveNavigation (internal helper, called by all navigation methods):
({List<Path> paths, bool forceReplaceAll}) _resolveNavigation(List<Path> paths) {
  if (routeGuard != null && paths.isNotEmpty) {
    final targetPath = paths.last.name;
    if (!routeGuard!(targetPath)) {
      // Force stack clear to prevent back navigation escaping onboarding
      return (paths: [Path(name: '/onboarding')], forceReplaceAll: true);
    }
  }
  return (paths: paths, forceReplaceAll: false);
}

// Example usage in goTo():
void goTo(Path path) {
  final result = _resolveNavigation([path]);
  if (result.forceReplaceAll) {
    _replaceAllInternal(result.paths);  // Clears entire stack
  } else {
    _pushInternal(result.paths.last);
  }
}
```
- **CRITICAL:** When guard denies, ALWAYS clear the stack via replaceAll semantics
- This prevents `back()` from escaping onboarding to guarded routes

**Step 3:** Wire up in `locator_config.dart`:
```dart
// Required import: import 'dart:async' show unawaited;

Module<RouterService>(
  builder: () => RouterService(
    supportedRoutes: routes,  // Existing parameter
    routeGuard: (path) {
      // Use Uri.parse to handle query params correctly
      final pathOnly = Uri.parse(path).path;
      if (pathOnly == '/onboarding') return true;  // Always allow onboarding

      final onboardingStore = locator<OnboardingStore>();
      final navStore = locator<NavigationIntentStore>();

      // CRITICAL: Check force flag FIRST - forced onboarding starts fresh (no deep link preservation)
      // This must come before isInitialized check to handle app relaunch with deep link during forced flow
      if (navStore.shouldForceOnboarding()) return false;

      // Helper: only save paths that require auth (skip public routes)
      // Prevents stale deep links from being replayed after auth
      // NOTE: Derives from RouteEntry.requiresAuth for single source of truth
      bool isProtectedPath(String p) {
        RouteEntry? matchedRoute;
        for (final route in routes) {
          if (matchRoute(route.path, Uri.parse(p)) != null) {
            matchedRoute = route;
            break;
          }
        }
        // Unmatched routes and public routes (requiresAuth: false) are not saved
        return matchedRoute != null && matchedRoute.requiresAuth;
      }

      // Gate: if onboarding hasn't initialized yet, store path and redirect
      if (!onboardingStore.isInitialized) {
        if (isProtectedPath(pathOnly)) {
          unawaited(navStore.saveIntendedRoute(path));  // Preserve protected deep link
        }
        return false;  // Redirect to /onboarding (splash until init completes)
      }

      // Check first-time onboarding - preserve deep link for after completion
      if (!onboardingStore.isCompleted) {
        if (isProtectedPath(pathOnly)) {
          unawaited(navStore.saveIntendedRoute(path));  // Preserve protected deep link
        }
        return false;
      }

      return true;
    },
  ),
),
```

- **Decoupled:** RouterService has no feature dependencies, gate logic is injected
- **Testable:** Tests inject `routeGuard: (_) => true` to bypass
- **Centralized:** All navigation methods use `_resolveNavigation()`
- **Force flag first:** Checked before isInitialized to prevent deep link preservation during forced onboarding
- **Sync access:** Guard uses cached `isCompleted` getter (init runs at startup)
- **Race-safe:** `isInitialized` gate defers routing until init completes
- **Protected paths only:** Only saves deep links for auth-required routes (skips /auth*, /offline, /404)
- **Import note:** Requires `import 'dart:async' show unawaited;`

**Task 7.3 Implementation:**
```dart
Future<void> initializeApp() async {
  appStateNotifier.value = const InitializingApp();
  try {
    locator.registerMany(buildModules(sharedPreferences: _sharedPreferences));
    loggingSubscription?.cancel();
    loggingSubscription = _loggingAbstraction.initializeLogging();
    locator<AppLifecycleService>().attachStartupViewModel(this);

    // INIT ONBOARDING STORE FIRST (runs migration, caches result)
    final onboardingStore = locator<OnboardingStore>();
    await onboardingStore.init();  // Async migration, then sync access

    // CHECK ONBOARDING (before auth init)
    if (!onboardingStore.isCompleted) {  // Sync getter (cached)
      final routerService = locator<RouterService>();
      routerService.replaceAll([Path(name: '/onboarding')]);
      appStateNotifier.value = const AppInitialized();
      return; // Skip auth init entirely
    }

    // Then proceed with auth
    final authService = locator<AuthService>();
    await authService.init();
    // ... rest of existing logic
  }
}
```

**Task 7.4: Handle Sign-Out Flow (Deterministic with Force Flag)**
- **Problem:** `logout()` calls `restartApp()` which races with `_handleAuthChange` routing
- **Solution:** Use a "force onboarding" flag in `NavigationIntentStore` that survives restart

**Step 1:** Add method to `NavigationIntentStore` (`lib/core/utils/navigation/navigation_intent_store.dart`):
```dart
static const _forceOnboardingKey = 'force_onboarding';

Future<void> setForceOnboarding() async {
  await _prefs.setBool(_forceOnboardingKey, true);
}

bool shouldForceOnboarding() {
  return _prefs.getBool(_forceOnboardingKey) ?? false;
}

Future<void> clearForceOnboarding() async {
  await _prefs.remove(_forceOnboardingKey);
}
```

**Step 2:** Modify `logout()` in `AuthService` (line 76):
```dart
// AuthService constructor now takes UserBootstrapService as injected dependency:
// AuthService({
//   required UserBootstrapService userBootstrapService,
//   // ... other deps
// }) : _userBootstrapService = userBootstrapService;

Future<void> logout() async {
  await _navigationIntentStore.setForceOnboarding();
  await _dataSource.auth.signOut(scope: supabase.SignOutScope.local);
  await _cachedUserStore.clearUser();
  await _navigationIntentStore.clearIntendedRoute();
  await _navigationIntentStore.clearAuthEmail();

  // CRITICAL: Reset user-scoped services to prevent state leaking across sessions
  // This replaces the global reset that restartApp() used to provide
  // Uses injected dependency (not locator) per CLAUDE.md: "All dependencies injected through constructors"
  _userBootstrapService.invalidatePresenceCache();  // Clear user-scoped state
  // Add other user-scoped service resets as needed (inject them in constructor)

  _currentUser = null;
  authState.value = const Unauthenticated();
  // Route to onboarding - router guard will enforce this
  _routerService.replaceAll([Path(name: '/onboarding')]);
  // DO NOT call restartApp() - it causes RouterService desync
  // Route guard + force flag handle all edge cases
}
```
**IMPORTANT:** Removed `restartApp()` from logout to prevent RouterService desync. The force flag survives any app restarts and the router guard prevents bypassing onboarding. User-scoped services are explicitly reset via injected dependencies (not locator access) to prevent state leaking across sessions.

**Step 3:** Modify `StartupViewModel.initializeApp()` to check force flag FIRST:
```dart
// At start of initializeApp(), after locator registration:

// ALWAYS init onboarding store first (sets isInitialized, runs migration)
// This must happen before ANY routing to prevent guard race condition
final onboardingStore = locator<OnboardingStore>();
await onboardingStore.init();

// Then check force flag
final navigationIntentStore = locator<NavigationIntentStore>();
if (navigationIntentStore.shouldForceOnboarding()) {
  // DO NOT clear flag here - clear only when onboarding completes
  final routerService = locator<RouterService>();
  routerService.replaceAll([Path(name: '/onboarding')]);
  appStateNotifier.value = const AppInitialized();
  return;
}

// Then check onboarding completion...
if (!onboardingStore.isCompleted) { ... }
```

**Step 4:** Force flag cleared by `OnboardingViewModel.completeOnboarding()` (see Task 6.2):
- OnboardingStore.markCompleted() only sets the completion flag
- Force flag clearing is handled by ViewModel with injected NavigationIntentStore
- This keeps OnboardingStore simple and testable (no hidden locator dependency)

- **Deterministic:** Flag survives restart, only cleared when onboarding finishes
- **App kill during forced onboarding:** Relaunches to onboarding (flag still set)
- **No race condition:** Force flag is checked before any auth init

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Auth init navigation override | Check onboarding BEFORE auth.init() in StartupViewModel |
| Existing users forced into onboarding | Migration checks has_ever_launched OR cached_user/auth_email (Task 7.1b); requires pre-onboarding release to seed marker |
| RouterService desync after restart | Removed restartApp() from logout(); use explicit routing + force flag |
| Deep links bypass onboarding | Router guard checks both isCompleted() AND force flag |
| Router core→feature dependency | Inject gate callback, don't use locator in RouterService |
| Offline/no-user after onboarding | Explicit routing to /offline in completeOnboarding() |
| Authenticated offline after onboarding | Explicit routing to / in completeOnboarding() |
| Auth init failure | try/catch in completeOnboarding(), route to /auth on error |
| Animation skip gesture conflicts | Scope skip handler to non-CTA areas only |
| State loss on back navigation | Use `PageView` with `PageStorageKey` per screen |
| Orientation lock persists | Reset to `DeviceOrientation.values` in dispose |
| Typography mismatches (15px, 26px) | Use inline TextStyle for non-standard sizes |
| Long content overflow | Use CustomScrollView + SliverFillRemaining pattern (Task 3.1) |
| Sign-out routing vs restartApp race | Removed restartApp(); force flag + router guard handle all cases |
| App kill during forced onboarding | Force flag persists, relaunches to onboarding |
| Guard needs sync access to onboarding state | OnboardingStore.init() runs at startup; guard uses cached sync getter |
| Router guard race with deep links | `isInitialized` gate defers routing; deep links stored via `setIntendedRoute` |
| Checkbox state lost on PageView page dispose | Checkbox state in ViewModel (`disclaimerAccepted`), not widget state |

---

## Acceptance Checks

- [ ] First launch shows onboarding (Screen 1)
- [ ] CTA navigation works: 1→2→3→4→(auth, home, or offline based on auth state)
- [ ] Authenticated offline after onboarding → routes to home
- [ ] **Back button: Screen 1 exits app; Screens 2-4 step back within onboarding**
- [ ] "Sign in instead" on Screen 3 goes to Screen 4
- [ ] Tap-to-skip reveals all text on Screen 1 **without blocking CTA**
- [ ] **Checkbox state preserved when going back to Screen 3 and returning**
- [ ] **Screen 4 "Let's go" CTA disabled until checkbox checked**
- [ ] Completing onboarding sets SharedPreferences flag
- [ ] Second launch (unauthenticated) goes to /auth, not onboarding
- [ ] **Sign out returns to onboarding Screen 1**
- [ ] Haptic feedback fires on primary CTAs
- [ ] Portrait orientation locked during onboarding
- [ ] **Orientation restored after leaving onboarding**
- [ ] All animations play correctly (stagger, fade, slide)
- [ ] Progress dots update correctly per screen
- [ ] Brand-sky glow only appears on Screen 3
- [ ] **Content scrollable on small screens**

---

## Test Notes

- Create `test/features/onboarding/` directory
- Test `OnboardingStore`:
  - `markCompleted_setsFlag`
  - `isCompleted_returnsTrueAfterMark`
  - `init_existingUserWithCachedUser_autoCompletesOnboarding` (migration test)
  - `init_newUserNoLegacyData_showsOnboarding`
  - `init_calledTwice_idempotent` (migration version check)
  - `isInitialized_falseBeforeInit_trueAfter`
- **Widget tests use real `OnboardingViewModel`** (per CLAUDE.md: "Widget tests use real ViewModels")
- Use `SharedPreferences.setMockInitialValues` for store tests
- Navigation tests: verify route transitions and back navigation
- Test skip-animation-on-tap doesn't interfere with CTA

**Startup/Sign-Out Routing Tests:**
- `test/startup/startup_view_model_test.dart`:
  - `initializeApp_onboardingNotCompleted_routesToOnboarding`
  - `initializeApp_onboardingCompleted_callsAuthInit`
  - `initializeApp_onboardingCompletedUnauthenticated_routesToAuth`
  - `initializeApp_forceOnboardingFlag_routesToOnboarding`
- `test/features/auth/data/auth_service_test.dart`:
  - `logout_setsForceOnboardingFlag`
  - `logout_routesToOnboarding`
  - `logout_doesNotCallRestartApp` (verify restartApp removed)
- `test/features/onboarding/presentation/onboarding_view_model_test.dart`:
  - `completeOnboarding_callsMarkCompleted`
  - `completeOnboarding_clearsForceFlag`
  - `completeOnboarding_callsAuthInit`
  - `completeOnboarding_authenticatedOnline_letsAuthServiceHandleNavigation`
  - `completeOnboarding_authenticatedOffline_routesToHome`
  - `completeOnboarding_unauthenticated_routesToAuth`
  - `completeOnboarding_offlineNoUser_routesToOffline`
  - `completeOnboarding_authInitThrows_routesToAuth`
  - `completeOnboarding_doubleTap_ignoredSecondCall`
- `test/features/offline/offline_retry_view_test.dart`:
  - `retry_authenticatedOnline_routesToHome`
  - `retry_offlineNoUser_staysOnScreen`

**Router Guard Tests:**
- `test/navigation/router_service_test.dart`:
  - Existing tests: inject `routeGuard: (_) => true` to bypass guard
  - New tests:
    - `replaceAll_guardReturnsFalse_redirectsToOnboarding`
    - `goTo_guardReturnsFalse_redirectsToOnboarding`
    - `goTo_guardReturnsFalse_clearsStack`
    - `replace_guardReturnsFalse_redirectsToOnboarding`
    - `replaceAllWithRoute_guardReturnsFalse_redirectsToOnboarding`
    - `back_afterGuardDenial_cannotEscapeOnboarding` - verify stack is cleared so back() doesn't reveal guarded routes
    - `guard_isInitializedFalse_savesIntendedRouteAndRedirects` - verify deep link preserved during init
    - `guard_isInitializedTrue_allowsRouting` - verify guard passes after init completes

**Deep Link Recovery Tests:**
- `test/features/auth/data/auth_service_test.dart`:
  - `handlePostAuthNavigation_withIntendedRoute_navigatesToIntendedRoute` - verify AuthService replays saved deep link
- `test/features/onboarding/presentation/onboarding_view_model_test.dart`:
  - `completeOnboarding_authenticatedOnline_doesNotNavigate` - verify ViewModel defers to AuthService for navigation

---

## References

| Item | Path | Lines |
|------|------|-------|
| Spec | `on_boarding_specs.md` | Full file |
| StartupViewModel modification point | `lib/startup/startup_view_model.dart` | 53-79 |
| Route config | `lib/config/route_config.dart` | 7-19 |
| AuthBackground pattern | `lib/features/auth/presentation/widgets/auth_background.dart` | 5-50 |
| SplashGridBackground | `lib/startup/widgets/splash_grid_background.dart` | Full file |
| CTA styling | `lib/features/auth/presentation/auth_view.dart` | 375-404 |
| SharedPreferences pattern | `lib/core/utils/navigation/navigation_intent_store.dart` | Full file |
| AuthViewModel pattern | `lib/features/auth/presentation/auth_view_model.dart` | Full file |
| Design tokens | `lib/core/ui/constants/` | kit_colors, spacing, durations, curves |
| Locator config | `lib/config/locator_config.dart` | buildModules() |
| AuthService logout & auth change | `lib/features/auth/data/auth_service.dart` | logout() at 76-84, _handleAuthChange() at 111-148 |
| RouterService (guard location) | `lib/core/utils/navigation/router_service.dart` | Route resolution/guards |

---

## Open Questions (Resolved)

1. **Typography inline vs. theme**: Use inline styles for 15px/26px sizes (don't pollute design system)
2. **Custom checkbox**: Create custom for brand consistency and animation control
3. **flutter_animate vs implicit**: Use implicit animations (`AnimatedOpacity`, `AnimatedSlide`) with existing `CustomCurves` and `CustomDurations`
4. **EnumPageView location**: Place in `lib/core/ui/widgets/` for reusability
5. **Checkbox state on back nav**: Stored in `OnboardingState.disclaimerAccepted` via single ViewModel `state` notifier (not widget state) - PageView can dispose off-screen pages, so widget state would be lost (see Task 5.4, Task 6.2)

---

## Spec Alignment Notes

The following updates were made to `on_boarding_specs.md` to align with this plan:

1. **Key naming**: Changed `hasCompletedOnboarding` to `has_completed_onboarding` (snake_case consistency)
2. **Dependencies**: Removed `flutter_animate` and `sprung` - using implicit animations instead
3. **Architecture**: Updated to reflect `OnboardingViewModel` usage (follows codebase MVVM pattern)
4. **File structure**: Added `onboarding_store.dart` and `onboarding_view_model.dart`
5. **Animation curves**: Changed from `Sprung.overDamped` to `CustomCurves.emphasizedDecelerate`
