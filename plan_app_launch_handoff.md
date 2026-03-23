# Plan: App Launch Handoff to Flutter

**Spec:** `docs/specs/20260322120000_spec_app_launch_handoff.md`
**Branch:** `feature/splash-screen`
**Practices:** P1, P2, P3, P7 from `docs/best_practices/architecture/app_launch_and_handoff_to_flutter.md`

---

> **Architecture note:** Phase 1 (subparts 1a–1c) is one atomic refactor — all subparts touch the same files (`main.dart`, `startup_view.dart`, `startup_view_model.dart`, `data_source_init.dart`) and must land together. Applying any subpart in isolation would break the startup sequence because `locator<RouterService>()` would not exist when the view needs it. Phase 2 (min splash time) can land as a separate commit after Phase 1, and Phase 3 (tests) after that.

## Phase 1: Atomic startup refactor (Phases 1-4 combined)

Move all pre-`runApp()` async work into `StartupViewModel.initializeApp()`, make `main()` synchronous, defer `BestRouterConfig`, and make `initDataSource()` idempotent. These changes are interdependent and must land as one commit.

### 1a. Make `initDataSource()` idempotent (`lib/core/utils/data_source/data_source_init.dart`)

- [ ] Replace the bare `Supabase.initialize()` call with a guarded completer pattern:
  ```dart
  import 'dart:async';
  import 'package:flutter/foundation.dart' show visibleForTesting;
  import 'package:supabase_flutter/supabase_flutter.dart';

  Completer<void>? _initCompleter;

  /// Initializes Supabase. Safe to call multiple times:
  /// - First call: runs initialization, returns when done.
  /// - Concurrent calls: return the same future.
  /// - After failure: resets so the next call retries.
  Future<void> initDataSource() async {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
        anonKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: ''),
      );
      _initCompleter!.complete();
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null; // Reset so retry can genuinely retry
      rethrow;
    }
  }

  /// Test seam: resets the init guard so tests can exercise idempotency
  /// and retry-after-failure scenarios deterministically.
  @visibleForTesting
  void resetDataSourceInitGuard() => _initCompleter = null;
  ```
- **Why:** `retryInitialization()` calls `locator.reset()` then re-runs `initializeApp()`. Without this guard, `Supabase.initialize()` throws on double-init after a successful first call, or silently fails after an error.
- **Test seam:** `resetDataSourceInitGuard()` allows tests to reset global state between test cases without relying on the real Supabase SDK. Tests can also inject a mock initializer by wrapping `initDataSource()` calls.

### 1b. Remove `sharedPreferences` from constructor chain

- [ ] **`lib/startup/startup_view_model.dart`**
  - Remove `sharedPreferences` constructor parameter (line 48)
  - Remove `_sharedPreferences` field (line 55)
  - At the top of `initializeApp()` (before `buildModules()`), add:
    ```dart
    await initDataSource();
    final sharedPreferences = await SharedPreferences.getInstance();
    ```
  - Pass `sharedPreferences` as a local variable to `buildModules(sharedPreferences: sharedPreferences)` (line 69)
  - Add import for `data_source_init.dart`
  - **Order:** `initDataSource()` → `SharedPreferences.getInstance()` → `buildModules()` — Supabase must init first because `DataSourceAbstraction.instance()` uses `Supabase.instance.client`

- [ ] **`lib/startup/startup_view.dart`**
  - Remove `sharedPreferences` constructor parameter from `StartupView` (line 23-24)
  - Remove `sharedPreferences` field (line 27)
  - Add an optional `viewModel` parameter for widget test injection:
    ```dart
    class StartupView extends StatefulWidget {
      const StartupView({
        super.key,
        @visibleForTesting this.viewModel,
      });

      /// Injected for widget tests. Production code passes null (default).
      final StartupViewModel? viewModel;

      @override
      State<StartupView> createState() => _StartupViewState();
    }
    ```
  - In the state, use the injected model or create a default:
    ```dart
    late final StartupViewModel _viewModel =
        widget.viewModel ?? StartupViewModel();
    ```
  - **Why:** Widget tests need to drive `StartupView` through init/retry states deterministically without triggering real `initDataSource()`/platform calls. Injecting a preconfigured `StartupViewModel` (with fake initializers) allows this.

- [ ] **`lib/main.dart`**
  - Remove `await initDataSource()` (line 11)
  - Remove `await SharedPreferences.getInstance()` (line 12)
  - Remove `sharedPreferences` parameter from `_AppLifecycleObserver` constructor (line 14-16, 25-29)
  - Remove `sharedPreferences` field from `_AppLifecycleObserver` (line 29)
  - Remove `sharedPreferences` pass-through to `StartupView` in `build()` (line 65-66)
  - Remove `shared_preferences` and `data_source_init.dart` imports
  - Change signature from `void main() async` to `void main()`
  - Make `_AppLifecycleObserver` constructor `const` (no mutable fields left)
  - Final shape:
    ```dart
    void main() {
      WidgetsFlutterBinding.ensureInitialized();
      configureUrlStrategy();
      runApp(const _AppLifecycleObserver());
    }
    ```

- **`lib/config/locator_config.dart`** — No signature change. `buildModules()` still receives `sharedPreferences` as a parameter, just from `initializeApp()` instead of `main()`.

### 1c. Defer `BestRouterConfig` until `AppInitialized` and handle retry

- [ ] **`lib/startup/startup_view.dart`**
  - Remove `late final BestRouterConfig _routerConfig` field (line 35)
  - Remove `_routerConfig = BestRouterConfig(...)` from `initState()` (line 41)
  - `initState()` no longer calls `initializeApp()` directly. Bootstrap is triggered from the `ValueListenableBuilder` callback when `InitializingApp` state is detected (see below). This ensures frame-anchored timing for both initial load and retry.
    ```dart
    void initState() {
      super.initState();
      // Bootstrap scheduling is handled in the builder callback below.
      // The initial InitializingApp state triggers the first post-frame callback.
    }
    ```
  - Add a nullable `_routerConfig` field that is **cleared on retry**:
    ```dart
    BestRouterConfig? _routerConfig;
    ```
  - In the `ValueListenableBuilder` callback, **clear the cached router and schedule bootstrap when returning to `InitializingApp`** (handles both initial load and retry with frame-anchored timing):
    ```dart
    bool _bootstrapScheduled = false;

    builder: (context, state, _) {
      if (state is InitializingApp) {
        // Clear cached router on retry so we get a fresh RouterService instance
        _routerConfig = null;
        // Schedule bootstrap after this frame paints — ensures the 1000ms
        // minimum timer starts after the splash is visible. Works for both
        // initial cold start and retry (retryInitialization sets InitializingApp
        // then this callback fires on the next build).
        if (!_bootstrapScheduled) {
          _bootstrapScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _bootstrapScheduled = false;
            _viewModel.initializeApp();
          });
        }
      }
      return switch (state) {
        InitializingApp() => _buildAppShell(child: const SplashScreen()),
        AppInitialized() => _buildRouterApp(),
        OfflineNoUserState() => _buildAppShell(
            child: _OfflineNoUserView(onRetry: _viewModel.retryInitialization),
          ),
        AppInitializationError() => _buildAppShell(
            child: _StartupErrorView(onRetry: _viewModel.retryInitialization),
          ),
      };
    }
    ```
  - **Why this works for retry:** `retryInitialization()` sets `appStateNotifier.value = InitializingApp()`, disposes services, and resets the locator — but no longer calls `initializeApp()` directly. Instead, the `ValueListenableBuilder` detects the `InitializingApp` state, clears the cached router, and schedules `initializeApp()` from a post-frame callback. This ensures the retry splash frame paints before the 1000ms timer starts, matching the cold-start behavior exactly.
  - Update `retryInitialization()` in `StartupViewModel` — preserve the existing "flip state before disposal" ordering to prevent widgets from reading disposed services, and keep `Future<void>` return type for the `AppLifecycleService.restartApp()` → `AuthService.logout()` await chain:
    ```dart
    Future<void> retryInitialization() async {
      // Set state to InitializingApp BEFORE disposing to prevent widgets from
      // reading disposed notifiers/services during the transition window.
      // (Preserves the existing safety guard from the current code.)
      appStateNotifier.value = const InitializingApp();
      _disposeServices();
      locator.reset();
      // initializeApp() is NOT called here — the view schedules it
      // from a post-frame callback when it sees InitializingApp state.
      // This future completes immediately after cleanup. Callers like
      // AppLifecycleService.restartApp() await this to ensure cleanup
      // finishes before returning, but bootstrap runs asynchronously
      // after the next frame.
    }
    ```
  - **`lib/core/utils/app_lifecycle_service.dart`** — No change needed. `restartApp()` already awaits `retryInitialization()`, which now completes after cleanup (dispose + reset). The actual re-bootstrap happens later via the view's post-frame callback. This is safe because `AuthService.logout()` only needs cleanup to complete before returning — it does not need to wait for re-bootstrap.
  - **Why clear `_routerConfig` on `InitializingApp`:** `locator.reset()` destroys the old `RouterService`. The cached `BestRouterConfig` holds a reference to the old `RouterService` delegate. Without clearing, the app would use a stale router after retry.

  - Extract shared `MaterialApp` configuration into a helper to avoid duplicating localization, theme, and `Translate.init()`:
    ```dart
    /// Non-router MaterialApp for splash, error, and offline states.
    /// Shares localization, theme, and Translate.init() with the router variant.
    Widget _buildAppShell({required Widget child}) {
      return MaterialApp(
        onGenerateTitle: (context) => context.translate.appName,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(Brightness.light),
        darkTheme: AppTheme.buildTheme(Brightness.dark),
        builder: (context, _) {
          Translate.init(context);
          return child;
        },
      );
    }

    /// Router-based MaterialApp for the initialized app.
    Widget _buildRouterApp() {
      _routerConfig ??= BestRouterConfig(
        routerService: locator<RouterService>(),
      );
      return MaterialApp.router(
        routerConfig: _routerConfig,
        onGenerateTitle: (context) => context.translate.appName,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(Brightness.light),
        darkTheme: AppTheme.buildTheme(Brightness.dark),
        builder: (context, child) {
          Translate.init(context);
          return InternalNotificationListener(
            child: _AuthStatusShell(child: child!),
          );
        },
      );
    }
    ```
  - **Why separate `MaterialApp` and `MaterialApp.router`:** The `SplashScreen`, error, and offline views do not use routing. Wrapping them in `MaterialApp.router` forces early `RouterService` resolution. A plain `MaterialApp` avoids that dependency while preserving localization delegates, theme, dark theme, and `Translate.init(context)`.

## Phase 2: Add minimum splash display time (1000ms)

Ensure the splash entrance animation completes before transitioning.

- [ ] **`lib/startup/startup_view_model.dart`**
  - Add injectable test seams for async platform calls that are hard to mock via global state:
    ```dart
    class StartupViewModel {
      StartupViewModel({
        LoggingAbstraction? loggingAbstraction,
        @visibleForTesting Future<void> Function()? dataSourceInitializer,
        @visibleForTesting Future<SharedPreferences> Function()? sharedPreferencesLoader,
        @visibleForTesting Future<PackageInfo> Function()? packageInfoLoader,
      }) : _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction(),
           _initDataSource = dataSourceInitializer ?? initDataSource,
           _getSharedPreferences = sharedPreferencesLoader ?? SharedPreferences.getInstance,
           _getPackageInfo = packageInfoLoader ?? PackageInfo.fromPlatform;

      final Future<void> Function() _initDataSource;
      final Future<SharedPreferences> Function() _getSharedPreferences;
      final Future<PackageInfo> Function() _getPackageInfo;
      // ... rest of fields
    }
    ```
  - **Why injectable:** `initDataSource()` wraps a global Supabase singleton, `SharedPreferences.getInstance()` returns a cached platform instance, and `PackageInfo.fromPlatform()` talks to native code. Injecting these as constructor parameters lets tests substitute fakes without relying on `resetDataSourceInitGuard()` or `SharedPreferences.setMockInitialValues()` — both of which leak global state across tests.
  - Production code uses default values (no change to call sites).

  - Extract current bootstrap body into a private `_bootstrap()` method.
  - `_bootstrap()` must return a typed result to handle branching outcomes:
    ```dart
    enum _BootstrapResult { initialized, offlineNoUser }

    Future<_BootstrapResult> _bootstrap() async {
      await _initDataSource();
      final sharedPreferences = await _getSharedPreferences();

      locator.registerMany(
        buildModules(sharedPreferences: sharedPreferences),
      );

      final packageInfo = await _getPackageInfo();
      locator.registerMany([
        Module<PackageInfo>(builder: () => packageInfo, lazy: false),
      ]);

      loggingSubscription?.cancel();
      loggingSubscription = _loggingAbstraction.initializeLogging();
      locator<AppLifecycleService>().attachStartupViewModel(this);

      final onboardingStore = locator<OnboardingStore>();
      await onboardingStore.init();

      final routerService = locator<RouterService>();
      routerService.setOnboardingGuard(() => !onboardingStore.isCompleted);

      final revenueCatService = locator<RevenueCatService>();
      try {
        await revenueCatService.init();
      } catch (e, st) {
        _logger.warning('RevenueCat init failed', e, st);
      }

      try { locator<UserOrientService>().init(); } catch (e, st) {
        _logger.warning('UserOrient init failed', e, st);
      }

      try { locator<InAppReviewService>().init(); } catch (e, st) {
        _logger.warning('InAppReview init failed', e, st);
      }

      final authService = locator<AuthService>();
      await authService.init();

      if (authService.authState.value is auth_state.OfflineNoUser) {
        return _BootstrapResult.offlineNoUser;
      }

      final syncService = locator<SessionSyncService>();
      syncService.init();
      unawaited(syncService.sync());

      return _BootstrapResult.initialized;
    }
    ```
  - Wrap `_bootstrap()` in `Future.wait` with a minimum delay, then set final state based on the result:
    ```dart
    Future<void> initializeApp() async {
      appStateNotifier.value = const InitializingApp();
      try {
        final results = await Future.wait([
          _bootstrap(),
          Future<void>.delayed(const Duration(milliseconds: 1000)),
        ]);
        final result = results[0] as _BootstrapResult;

        switch (result) {
          case _BootstrapResult.offlineNoUser:
            appStateNotifier.value = const OfflineNoUserState();
            return;
          case _BootstrapResult.initialized:
            appStateNotifier.value = const AppInitialized();
            final routerService = locator<RouterService>();
            final authService = locator<AuthService>();
            final onboardingStore = locator<OnboardingStore>();
            if (routerService.shouldShowOnboarding()) {
              routerService.replaceAll([Path(name: '/onboarding')]);
            } else if (authService.authState.value is auth_state.Unauthenticated) {
              routerService.replaceAll([Path(name: '/auth')]);
            }
        }
      } catch (e, st) {
        appStateNotifier.value = AppInitializationError(e, st);
      }
    }
    ```
  - **Why `_BootstrapResult`:** The original plan's pseudocode (`await Future.wait([...]); appStateNotifier.value = AppInitialized()`) would clobber the `OfflineNoUserState` branch. The typed return ensures all three outcomes (`initialized`, `offlineNoUser`, error via catch) are preserved after the min-delay completes.

- **Timing anchor:** `initializeApp()` is called from a post-frame callback (see Phase 1c), so the 1000ms minimum timer starts after the splash frame has painted. The splash entrance animation (`_entranceController.forward()`) starts in `SplashScreen.initState()` which fires during the first frame build. This ensures the full entrance animation (500ms) and breathing glow (~500ms) complete before any state transition.

- **Minimum duration applies to all outcomes:** The `Future.wait` pattern means the 1000ms minimum applies to `AppInitialized`, `OfflineNoUserState`, and `AppInitializationError` equally. This is intentional — a near-instant error flash is jarring. The splash stays visible for at least 1000ms regardless of outcome, giving the user a moment to orient before seeing an error or offline screen.

## Phase 3: Update tests

- [ ] **Constructor call updates**
  - Grep for `StartupViewModel(` and remove `sharedPreferences:` parameter
  - Grep for `StartupView(` and remove `sharedPreferences:` parameter
  - Grep for `_AppLifecycleObserver(` and remove `sharedPreferences:` parameter
  - Grep for `buildModules(` — verify `sharedPreferences` is still passed (it is, just sourced differently)

- [ ] **Mock changes**
  - If any tests mock `SharedPreferences` by injecting it through constructors, update to mock at the `SharedPreferences.getInstance()` level (via `SharedPreferences.setMockInitialValues({})`)
  - If any tests mock `initDataSource()`, update to account for it running inside `initializeApp()`

- [ ] **New regression tests** (targeted at the new failure modes)
  - `StartupView` renders `SplashScreen` in `InitializingApp` state **without** `RouterService` registered — verifies the non-router `MaterialApp` path works
  - Retry/restart recreates router wiring after `locator.reset()` — verifies `_routerConfig` is cleared and a fresh `BestRouterConfig` is created on re-init
  - `initDataSource()` second call after success is a no-op (idempotency guard) — use `resetDataSourceInitGuard()` between test cases
  - `initDataSource()` second call after failure retries (completer reset) — verify `_initCompleter` is nulled on error
  - Minimum splash duration: use `fakeAsync` to verify `AppInitialized` is not emitted before 1000ms even when bootstrap completes instantly; verify the same holds for `OfflineNoUserState` and `AppInitializationError`
  - Delayed router + deep link: verify that when `BestRouterConfig` is created lazily after `AppInitialized`, a non-`/` platform initial route (e.g., from a deep link) is still correctly received by `PlatformRouteInformationProvider` and funneled through auth/onboarding guards. This covers the web/browser edge case where the initial route is set before the router exists.

## Phase 4: Verify

- [ ] `flutter analyze` — clean
- [ ] `flutter test` — all pass
- [ ] Manual cold-start test (iOS device or simulator):
  - Native splash (dark) → Flutter splash (dark, animated) → app
  - No white/black flash between native and Flutter splash
  - Entrance animation (fade + slide, 500ms) completes before transition
- [ ] Manual retry test: trigger `AppInitializationError`, tap retry, confirm re-bootstrap works with fresh router
- [ ] Manual logout → restart test: verify router wiring is fresh after `locator.reset()`
- [ ] Profile mode startup trace:
  ```bash
  flutter run --profile --trace-startup
  ```
  Confirm time-to-first-Flutter-frame is faster than before (no pre-`runApp()` awaits)

---

## Summary of file changes

| File | Change |
|---|---|
| `lib/main.dart` | Remove 2 awaits, remove `async`, remove `sharedPreferences` param, remove imports, make constructor `const` |
| `lib/startup/startup_view_model.dart` | Remove `sharedPreferences` param, add `initDataSource()` + `SharedPreferences.getInstance()` to `_bootstrap()`, add 1000ms min display time via `Future.wait`, extract `_bootstrap()` returning `_BootstrapResult` |
| `lib/startup/startup_view.dart` | Remove `sharedPreferences` param, defer `BestRouterConfig` to `AppInitialized`, clear on retry, extract `_buildAppShell()` and `_buildRouterApp()` helpers sharing localization/theme config |
| `lib/core/utils/data_source/data_source_init.dart` | Add completer-based idempotency guard with failure reset for retry safety |
| `lib/core/utils/app_lifecycle_service.dart` | No change needed — `restartApp()` still awaits `retryInitialization()`, which now completes after cleanup |
| `lib/config/locator_config.dart` | No signature change — `buildModules()` still receives `sharedPreferences`, just from a different caller |
| `test/**` | Update constructor calls, mocks, and add regression tests for router lifecycle, Supabase idempotency, and min splash duration |
