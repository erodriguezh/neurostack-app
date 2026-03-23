# Spec: App Launch Handoff to Flutter

## Goal & Context

The Flutter `SplashScreen` is only visible for a few milliseconds because `main()` blocks on two heavyweight awaits — `Supabase.initialize()` and `SharedPreferences.getInstance()` — before calling `runApp()`. All real wait time is absorbed by the native launch surface, and by the time Flutter renders its first frame the bootstrap is nearly done.

The goal is a seamless cold-start experience:

1. Native splash covers engine startup (already dark-themed — commit `d5e219d`).
2. Flutter `SplashScreen` appears immediately and stays visible for at least 1000ms (entrance animation + breathing glow).
3. Bootstrap runs concurrently behind the splash.
4. Transition to the app happens only after both bootstrap and the minimum display time finish.

Reference: `docs/best_practices/architecture/app_launch_and_handoff_to_flutter.md`

## Current State (Problem)

### Pre-`runApp()` blockers (`lib/main.dart:9-17`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDataSource();                              // Supabase init — network + disk I/O
  final sharedPreferences = await SharedPreferences.getInstance(); // disk I/O
  configureUrlStrategy();
  runApp(_AppLifecycleObserver(sharedPreferences: sharedPreferences));
}
```

- `initDataSource()` (`lib/core/utils/data_source/data_source_init.dart:3-14`) — awaits `Supabase.initialize()`.
- `SharedPreferences.getInstance()` — disk I/O, called and awaited before `runApp()`.
- `configureUrlStrategy()` — synchronous, not a problem.

### Synchronous `locator<RouterService>()` in `initState()` (`lib/startup/startup_view.dart:38-42`)

```dart
void initState() {
  super.initState();
  _viewModel.initializeApp();
  _routerConfig = BestRouterConfig(routerService: locator<RouterService>());
}
```

- `initializeApp()` is async but not awaited — it fires and returns.
- The next line calls `locator<RouterService>()` synchronously, which works only because `buildModules()` (Phase 1 of `initializeApp()`) registers `RouterService` before the first `await`.
- `BestRouterConfig` (`lib/core/utils/navigation/best_router.dart:7-50`) wraps the router delegate, information provider, and parser.
- The `SplashScreen` never uses the router — it's only needed for `AppInitialized` state.

### `SharedPreferences` dependency chain (`lib/config/locator_config.dart:59-61`)

```dart
List<Module> buildModules({
  required SharedPreferences sharedPreferences,
}) => [ ... ]
```

- `SharedPreferences` is registered eagerly (lazy: false) and consumed by 9+ stores/services: `NavigationIntentStore`, `CachedUserStore`, `CachedProtocolStore`, `CachedWeekProgressStore`, `OnboardingStore`, `TrialExpirationDecisionStore`, `InAppReviewService`, `TrialReminderService`, `SessionLocalDataSource`.
- Currently passed as a constructor parameter through `_AppLifecycleObserver` → `StartupView` → `StartupViewModel` → `buildModules()`.

### `StartupViewModel.initializeApp()` sequential awaits (`lib/startup/startup_view_model.dart:61-143`)

After DI registration, the method awaits sequentially:
- `PackageInfo.fromPlatform()` (line 74) — already deferred post-`runApp()` in commit `25d6fb9`
- `onboardingStore.init()` (line 88)
- `revenueCatService.init()` (line 99)
- `authService.init()` (line 121)

### Splash screen is expensive for a first frame (`lib/startup/splash_screen.dart`)

- Fragment shader load via `ui.FragmentProgram.fromAsset('shaders/beam.frag')` (line 88)
- SVG decode via `SvgPicture.asset('assets/logo.svg')` (line 197)
- Grid pattern, two animation controllers, breathing glow with box shadows

## Proposed Changes

### Change 1: Lean `main()` — move Supabase + SharedPreferences after `runApp()`

**Practice 2** from the handoff doc: *Keep main() lean and reach runApp() fast.*

**Before** (`lib/main.dart:9-17`):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDataSource();
  final sharedPreferences = await SharedPreferences.getInstance();
  configureUrlStrategy();
  runApp(_AppLifecycleObserver(sharedPreferences: sharedPreferences));
}
```

**After**:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  runApp(const _AppLifecycleObserver());
}
```

- `initDataSource()` moves into `StartupViewModel.initializeApp()`, before `buildModules()`.
- `SharedPreferences.getInstance()` moves into `StartupViewModel.initializeApp()`, before `buildModules()`.
- `_AppLifecycleObserver` no longer receives `sharedPreferences` as a constructor parameter.

**Files affected:**
- `lib/main.dart` — remove awaits, remove `sharedPreferences` parameter from `_AppLifecycleObserver` constructor and its pass-through
- `lib/startup/startup_view.dart` — remove `sharedPreferences` constructor parameter, stop passing it to `StartupViewModel`
- `lib/startup/startup_view_model.dart` — remove `sharedPreferences` constructor parameter; acquire both `Supabase.initialize()` and `SharedPreferences.getInstance()` at the start of `initializeApp()`

### Change 2: Defer `BestRouterConfig` creation until `AppInitialized`

**Practice 1** from the handoff doc: *Handoff to the first Flutter frame, not to "another splash".*

The `SplashScreen` does not use the router. `BestRouterConfig` (and therefore `locator<RouterService>()`) is only needed when the app transitions to `AppInitialized`.

**Before** (`lib/startup/startup_view.dart:38-42`):
```dart
void initState() {
  super.initState();
  _viewModel.initializeApp();
  _routerConfig = BestRouterConfig(routerService: locator<RouterService>());
}
```

**After**: Remove `_routerConfig` from `initState()`. Create it lazily when the `AppInitialized` branch is reached in `build()`. During `InitializingApp`, render `SplashScreen` without a `MaterialApp.router` — a simple `MaterialApp` (non-router) or just a themed widget is sufficient.

**Files affected:**
- `lib/startup/startup_view.dart` — restructure `initState()` and `build()` so that `BestRouterConfig` is created on first `AppInitialized` render, not on init

### Change 3: Minimum splash display time (1000ms)

**Practice 7** from the handoff doc: *Make the first Flutter route cheap to render* + product intent for a polished first impression.

The entrance animation is 500ms (`lib/startup/splash_screen.dart:46-49`). Bootstrap should not dismiss the splash before the animation completes.

**Approach**: In `StartupViewModel.initializeApp()`, wrap the bootstrap in a `Future.wait` with a `Future.delayed(Duration(milliseconds: 1000))`. The splash stays visible for whichever takes longer.

**Files affected:**
- `lib/startup/startup_view_model.dart` — add minimum display time via `Future.wait`

### Change 4: Remove `sharedPreferences` from constructor chain

With `SharedPreferences.getInstance()` moving inside `initializeApp()`, the parameter must be removed from the constructor chain.

**Files affected:**
- `lib/main.dart` — `_AppLifecycleObserver` no longer takes `sharedPreferences`
- `lib/startup/startup_view.dart` — `StartupView` no longer takes `sharedPreferences`
- `lib/startup/startup_view_model.dart` — `StartupViewModel` no longer takes `sharedPreferences`; acquires it internally
- `lib/config/locator_config.dart` — no signature change; `buildModules()` still receives `sharedPreferences` as a parameter, just from `initializeApp()` instead of `main()`

## Edge Cases & Constraints

- **`retryInitialization()` path** (`startup_view_model.dart:145-152`): Calls `locator.reset()` then `initializeApp()` again. Both Supabase and SharedPreferences will be re-acquired on retry. `Supabase.initialize()` may need a guard or re-init check; `SharedPreferences.getInstance()` is safe to call multiple times (returns cached instance).
- **Supabase re-initialization**: Verify that `Supabase.initialize()` can be called after a `locator.reset()` without throwing. If it throws on double-init, add a guard.
- **`configureUrlStrategy()`** remains synchronous before `runApp()` — no change needed.
- **Lifecycle events during bootstrap**: `_AppLifecycleObserver.didChangeAppLifecycleState()` already guards against missing DI with a `try/catch` on `ModuleNotFoundException` (`main.dart:57-59`). No change needed.
- **1000ms minimum is not artificial delay**: On fast devices, the 1000ms covers the entrance animation (500ms) plus a brief breathing glow (~500ms). On slow devices, bootstrap takes longer and is the natural bottleneck. The `Future.wait` pattern ensures no unnecessary waiting.

## Acceptance Criteria

- [ ] `main()` contains no `await` — reaches `runApp()` synchronously
- [ ] `Supabase.initialize()` and `SharedPreferences.getInstance()` both run inside `StartupViewModel.initializeApp()`
- [ ] `sharedPreferences` parameter removed from `_AppLifecycleObserver`, `StartupView`, and `StartupViewModel` constructors
- [ ] `BestRouterConfig` is not created until `AppInitialized` state — `locator<RouterService>()` is not called during `initState()`
- [ ] `SplashScreen` is visible for at least 1000ms after first paint (bootstrap starts from post-frame callback, 1000ms minimum enforced via `Future.wait`)
- [ ] 1000ms minimum applies to all terminal outcomes (success, offline-no-user, error) — no instant flash for any path
- [ ] `retryInitialization()` path still works correctly (router config cleared, Supabase re-init is idempotent)
- [ ] No white or black flash between native splash and first Flutter frame
- [ ] `flutter analyze` passes
- [ ] All existing tests pass (update test mocks for changed constructor signatures)

## Boundaries

- Native splash theme/assets: out of scope (already handled in commit `d5e219d`)
- Splash screen widget changes (shader, animations, SVG): out of scope — addressed separately
- Parallelizing sequential awaits inside `initializeApp()` (e.g., `onboardingStore.init()` + `revenueCatService.init()`): out of scope for this change
- `PackageInfo.fromPlatform()` deferral: already done in commit `25d6fb9`

## Decision Context

**Why move Supabase + SharedPreferences after `runApp()` instead of using `flutter_native_splash.preserve()`?**

Practice 3 says use one hold mechanism. Adding `preserve()`/`remove()` would keep the native splash visible longer but wouldn't solve the core problem — the Flutter splash screen would still be invisible. Moving the work after `runApp()` means the Flutter splash is the loading surface, which is the product intent (branded, animated, professional first impression).

**Why not parallelize all bootstrap awaits?**

Ordering constraints exist: `buildModules()` needs `SharedPreferences`, RevenueCat must init before auth rehydration. Parallelizing where safe is a future improvement but not required for this fix.
