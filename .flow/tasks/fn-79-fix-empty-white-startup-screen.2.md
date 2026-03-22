# fn-79-fix-empty-white-startup-screen.2 Defer PackageInfo.fromPlatform() after runApp()

## Description
Remove `PackageInfo.fromPlatform()` from pre-`runApp()` in `main()` and resolve it inside `StartupViewModel.initializeApp()` using phased bootstrap. This reduces the time users spend on the native launch surface before Flutter renders its first frame.

**Size:** M
**Files:**
- `lib/main.dart` — remove `PackageInfo.fromPlatform()` await, remove `packageInfo` from `_AppLifecycleObserver` and `StartupView` constructor calls
- `lib/startup/startup_view.dart` — remove `packageInfo` constructor parameter, stop passing it to `StartupViewModel`
- `lib/startup/startup_view_model.dart` — remove `packageInfo` constructor parameter; in `initializeApp()`: (1) register core modules synchronously via `buildModules()`, (2) await `PackageInfo.fromPlatform()`, (3) register PackageInfo module separately via `locator.registerMany([Module<PackageInfo>(...)])`
- `lib/config/locator_config.dart` — remove `packageInfo` from `buildModules()` signature, remove `Module<PackageInfo>` from the returned list

## Approach

**Critical constraint**: `StartupView.initState()` calls `_viewModel.initializeApp()` (async, not awaited) then immediately calls `locator<RouterService>()` on the next line (`startup_view.dart:44-45`). This means all startup-critical modules (RouterService, NotifyService, etc.) MUST be registered synchronously before the first `await` in `initializeApp()`.

**Phased bootstrap**:
1. `locator.registerMany(buildModules(sharedPreferences: ...))` — synchronous, registers RouterService and all core modules. No PackageInfo in this call.
2. `final packageInfo = await PackageInfo.fromPlatform()` — async, now safe because RouterService is already registered.
3. `locator.registerMany([Module<PackageInfo>(builder: () => packageInfo, lazy: false)])` — registers PackageInfo as a separate module.
4. Continue with existing initialization (onboarding, RevenueCat, auth, etc.)

This works because `ModuleLocator.registerMany()` at `lib/core/utils/locator.dart:27` checks for `ModuleAlreadyRegisteredException` per type, so calling it twice with disjoint types is safe.

## Key context

- fn-78 (commit `e6b041f`) added `PackageInfo.fromPlatform()` before `runApp()` and threaded it through constructors — this change reverses that placement decision
- `buildModules()` at `lib/config/locator_config.dart:60` currently takes `{required PackageInfo packageInfo}` — this parameter is removed, and `Module<PackageInfo>` (line 65) moves out of the list
- `_AppLifecycleObserver` at `lib/main.dart:27` wraps `StartupView` — currently passes `packageInfo` through
- The `retryInitialization()` path calls `locator.reset()` then `initializeApp()` again — PackageInfo will be re-fetched on retry, which is safe (platform channel call reading static data)
- PackageInfo's only consumer is `SettingsView` via `locator<PackageInfo>()` (accessed lazily, long after startup)
- If `PackageInfo.fromPlatform()` throws inside `initializeApp()`, the existing `try/catch` routes to `AppInitializationError` state with retry

## Acceptance
- [ ] `PackageInfo.fromPlatform()` is NOT awaited before `runApp()` in `main()`
- [ ] `packageInfo` parameter removed from `_AppLifecycleObserver`, `StartupView`, and `StartupViewModel` constructors
- [ ] `buildModules()` no longer takes `packageInfo` parameter; `Module<PackageInfo>` removed from its list
- [ ] In `initializeApp()`: core modules registered synchronously FIRST (via `buildModules()`), THEN `PackageInfo.fromPlatform()` awaited, THEN PackageInfo module registered separately
- [ ] `locator<RouterService>()` in `StartupView.initState()` still works (registered before first await)
- [ ] `retryInitialization()` path still works (re-fetches PackageInfo on retry)
- [ ] `flutter analyze` passes
- [ ] All existing tests pass (update test mocks for changed constructor signatures)

## Done summary
Deferred PackageInfo.fromPlatform() from pre-runApp() into StartupViewModel.initializeApp() using phased DI bootstrap, removing the packageInfo parameter from constructors and buildModules to reduce time on the native launch surface before Flutter renders its first frame.
## Evidence
- Commits: 25d6fb906fccd583fa6d7b1cf86c4056ad2665be
- Tests: flutter analyze, flutter test
- PRs: