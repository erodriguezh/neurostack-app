# fn-79-fix-empty-white-startup-screen.3 Atomic startup refactor: sync main, defer router, idempotent init

## Description
Make `main()` synchronous by moving all async work (Supabase init, SharedPreferences) into `StartupViewModel.initializeApp()`. Defer `BestRouterConfig` creation until `AppInitialized` state. Make `initDataSource()` idempotent. Handle retry with router invalidation and view-driven re-bootstrap.

**Size:** L (atomic — cannot split without breaking startup sequence)
**Files:** `lib/main.dart`, `lib/startup/startup_view.dart`, `lib/startup/startup_view_model.dart`, `lib/core/utils/data_source/data_source_init.dart`

## Approach

Follow `plan_app_launch_handoff.md` Phase 1 (1a + 1b + 1c). All subparts must land together.

### 1a. Idempotent `initDataSource()` (`data_source_init.dart`)
- Add Completer-based guard: first call runs init, concurrent calls share same future, failure resets completer for retry
- Add `@visibleForTesting resetDataSourceInitGuard()` test seam
- Note: Supabase 2.10.3 has built-in idempotency (`_isInitialized` check) but the completer additionally protects against concurrent in-flight calls racing

### 1b. Remove `sharedPreferences` from constructor chain
- Strip param from `_AppLifecycleObserver`, `StartupView`, `StartupViewModel` constructors
- Move `initDataSource()` + `SharedPreferences.getInstance()` into top of `initializeApp()`, before `buildModules()`
- Order: `initDataSource()` → `SharedPreferences.getInstance()` → `buildModules(sharedPreferences: ...)` → services
- Make `main()` synchronous: remove `async`, remove awaits, make `_AppLifecycleObserver` const
- Add injectable test seams on `StartupViewModel`: `dataSourceInitializer`, `sharedPreferencesLoader`, `packageInfoLoader` (all `@visibleForTesting`, default to real implementations)
- Add optional `@visibleForTesting viewModel` param on `StartupView` for widget test injection
- `buildModules()` signature unchanged — still takes `sharedPreferences` param

### 1c. Defer `BestRouterConfig` + retry handling
- Remove eager `BestRouterConfig` from `initState()`
- Split build into `_buildAppShell()` (plain `MaterialApp`) and `_buildRouterApp()` (`MaterialApp.router`)
- Both share localization delegates, theme, dark theme, `Translate.init(context)`
- Cache `_routerConfig` as nullable, clear to `null` on `InitializingApp` state (router invalidation on retry)
- Schedule `initializeApp()` from post-frame callback when builder sees `InitializingApp` — handles both cold start and retry
- Update `retryInitialization()`: keep `Future<void>` return type, preserve flip-before-disposal ordering (`InitializingApp` → `_disposeServices()` → `locator.reset()`), remove direct `initializeApp()` call

## Key context

**Reentrancy guard (gap analyst finding):** `initializeApp()` can be called concurrently if two post-frame callbacks fire. Add a guard: if `_isBootstrapping == true`, return the existing future. `ModuleLocator.registerMany()` throws `ModuleAlreadyRegisteredException` on duplicate types — this is the crash path without the guard.

**Infinite scheduling loop (gap analyst finding):** The `_bootstrapScheduled` flag must stay `true` until `initializeApp()` completes (not be reset before the call). If reset before, `initializeApp()` sets `InitializingApp` → builder sees it → schedules again → loop. Solution: keep `_bootstrapScheduled = true` during execution, set `false` only after `initializeApp()` completes or errors.

**Double-tap retry (gap analyst finding):** Add debounce or disable retry button after first tap. The `onRetry` callback fires `retryInitialization()` — if tapped twice before the `InitializingApp` state causes rebuild, two cleanup cycles run. Either guard in ViewModel or disable button in View.

**Supabase on retry after success:** The completer in `initDataSource()` stays completed after first success. On retry, `initDataSource()` returns immediately (the completed future). This is correct — Supabase client is a singleton that survives `locator.reset()`. Document this explicitly in a code comment.

**`_disposeServices()` audit:** Currently disposes `SessionSyncService`, `AuthService`, `ConnectivityService`, `RevenueCatService`. Missing: `AppLifecycleService` (holds `_startupViewModel` reference), `OnboardingStore` (if it holds listeners). Audit and add as needed.

**`Translate.init(context)` must be idempotent** — it's called in both `_buildAppShell` and `_buildRouterApp` builders, on every rebuild.

**Existing pattern ref:** `lib/core/utils/locator.dart:31` — `registerMany` throws `ModuleAlreadyRegisteredException`; `lib/core/utils/locator.dart:52-58` — `reset()` clears map but does NOT dispose instances.
## Acceptance
- [ ] `main()` is synpromchronous — no `async`, no `await` before `runApp()`
- [ ] `_AppLifecycleObserver` constructor is `const`
- [ ] `sharedPreferences` parameter removed from `_AppLifecycleObserver`, `StartupView`, `StartupViewModel`
- [ ] `initDataSource()` + `SharedPreferences.getInstance()` called inside `initializeApp()` before `buildModules()`
- [ ] `initDataSource()` is idempotent: no-op after success, resets on failure for retry, concurrent calls share same future
- [ ] `BestRouterConfig` created lazily on first `AppInitialized`, not in `initState()`
- [ ] `_routerConfig` cleared to `null` on `InitializingApp` (router invalidation)
- [ ] Splash/error/offline states use plain `MaterialApp` with shared localization + theme config
- [ ] `retryInitialization()` preserves flip-before-disposal ordering, does not call `initializeApp()` directly
- [ ] View-driven re-bootstrap: `InitializingApp` triggers post-frame callback that calls `initializeApp()`
- [ ] Reentrancy guard on `initializeApp()` prevents concurrent execution
- [ ] No infinite scheduling loop (bootstrap scheduled flag managed correctly)
- [ ] Injectable test seams on `StartupViewModel` (3 async function params with production defaults)
- [ ] Optional `viewModel` param on `StartupView` for widget test injection
- [ ] `@visibleForTesting resetDataSourceInitGuard()` exposed
- [ ] `flutter analyze` passes
## Done summary
Atomic startup refactor: made main() synchronous, moved initDataSource() and SharedPreferences loading into StartupViewModel.initializeApp(), deferred BestRouterConfig creation until AppInitialized state, added Completer-based idempotency to initDataSource(), added reentrancy guard on initializeApp(), and implemented post-frame callback scheduling so splash renders before bootstrap work begins.
## Evidence
- Commits: bbd3b043f60a93445d0f3f6da6fc3c6c3b4327e0
- Tests: flutter analyze, flutter test
- PRs: