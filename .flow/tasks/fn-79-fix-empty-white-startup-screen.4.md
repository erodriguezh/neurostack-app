# fn-79-fix-empty-white-startup-screen.4 Minimum splash display time with bootstrap extraction

## Description
Extract the bootstrap sequence into `_bootstrap()` returning a typed `_BootstrapResult` enum, wrap in `Future.wait` with a 500ms minimum delay, and ensure frame-anchored timing so the splash entrance animation completes before any state transition.

**Size:** M
**Files:** `lib/startup/startup_view_model.dart`, `lib/startup/startup_view.dart` (minor — verify post-frame callback timing)

## Approach

Follow `plan_app_launch_handoff.md` Phase 2.

<!-- Updated by plan-sync: fn-79-fix-empty-white-startup-screen.3 used _doInitializeApp() behind reentrancy guard, not initializeApp() directly -->
### Bootstrap extraction
- Extract current `_doInitializeApp()` body (the actual init logic) into `_bootstrap()` method
- `_bootstrap()` returns `_BootstrapResult` enum: `initialized` or `offlineNoUser`
- Preserve all existing service init ordering: `initDataSource()` → SharedPreferences → `buildModules()` → PackageInfo → logging → onboarding → RevenueCat → UserOrient → InAppReview → auth → sync
- Move routing logic (`shouldShowOnboarding`, auth check) out of `_bootstrap()` into `_doInitializeApp()` after the `Future.wait` resolves
- Note: `initializeApp()` is a thin reentrancy guard wrapper (`_bootstrapFuture ??= _doInitializeApp().whenComplete(...)`) — do not modify it; all changes go in `_doInitializeApp()`

### Minimum splash time
- `_doInitializeApp()` wraps `_bootstrap()` + `Future.delayed(500ms)` in `Future.wait`
- After both complete, read `_BootstrapResult` to set final state:
  - `initialized` → `AppInitialized` + routing
  - `offlineNoUser` → `OfflineNoUserState` (with `return` to skip routing)
  - Exception → caught by outer try/catch → `AppInitializationError`
- 500ms minimum applies to ALL outcomes (success, offline, error) — no instant flash for any path

### Timing anchor
- `initializeApp()` is called from the post-frame callback (set up in task .3), so the 500ms timer starts after the splash frame paints
- The splash entrance animation starts in `SplashScreen.initState()` via `_entranceController.forward()` — nearly simultaneous with the timer

## Key context

- `_BootstrapResult` is private to `startup_view_model.dart` — not part of public API
- `Future.wait` returns `List<Object?>` — cast `results[0]` to `_BootstrapResult`
- The routing logic (`routerService.replaceAll(...)`) must happen after `AppInitialized` is set, because the router needs to exist (deferred creation in task .3)
- `initializeApp()` is the public reentrancy guard; `_doInitializeApp()` holds the actual logic — all `Future.wait` and `_bootstrap()` changes go in `_doInitializeApp()`
- `SplashScreen` entrance animation is 500ms (`lib/startup/splash_screen.dart:46-49`, `CustomDurations.instance.duration500`)
## Acceptance
- [ ] `_bootstrap()` extracted as private method returning `Future<_BootstrapResult>`
- [ ] `_BootstrapResult` enum with `initialized` and `offlineNoUser` values
- [ ] `_doInitializeApp()` uses `Future.wait([_bootstrap(), Future.delayed(500ms)])`
- [ ] `OfflineNoUserState` preserved — not clobbered by naive `AppInitialized` after `Future.wait`
- [ ] Routing logic runs only on `_BootstrapResult.initialized` after `AppInitialized` is set (inside `_doInitializeApp()`)
- [ ] 500ms minimum applies to success, offline-no-user, and error outcomes
- [ ] `flutter analyze` passes
- [ ] Existing tests still pass (no test changes in this task)
## Done summary
Extracted bootstrap sequence into _bootstrap() returning typed _BootstrapResult enum, wrapped with Future.wait and 500ms minimum delay so the splash entrance animation always completes before any state transition. Error path also awaits the splash timer.
## Evidence
- Commits: cdb52b1, ba2646fd3a248b5a87549949367c05d1d295c1e4
- Tests: flutter analyze, flutter test
- PRs: