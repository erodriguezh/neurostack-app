# fn-79-fix-empty-white-startup-screen.5 Startup regression tests and doc updates

## Description
Add regression tests for the new startup lifecycle and update documentation that references the old constructor signatures.

**Size:** M
**Files:** `test/startup/startup_view_model_test.dart` (new), `test/startup/startup_view_test.dart` (new), `test/core/utils/data_source/data_source_init_test.dart` (new), `docs/best_practices/integration_test.md`, `docs/README.md`, `integration_test/utils/test_app.dart`

## Approach

Follow `plan_app_launch_handoff.md` Phase 3 + docs gap findings.

### Test conventions to follow
- Framework: `flutter_test` + `mocktail` (existing pattern in `test/`)
- Mock classes: centralized in `test/mocks/mock_services.dart`
- Pattern: `setUp`/`tearDown` with `locator.reset()` in tearDown
- No startup tests exist today — all net-new

<!-- Updated by plan-sync: fn-79-fix-empty-white-startup-screen.4 — StartupViewModel/StartupView never had sharedPreferences params; test_app.dart doesn't use StartupView -->
### Constructor/mock updates
- `StartupViewModel` accepts named test seams: `dataSourceInitializer`, `sharedPreferencesLoader`, `packageInfoLoader` (all `@visibleForTesting`)
- `StartupView` accepts `viewModel:` injection (`@visibleForTesting`)
- `integration_test/utils/test_app.dart` does NOT use `StartupView` — it builds `MaterialApp.router` directly with `BestRouterConfig`; no compile error to fix there
- Use `SharedPreferences.setMockInitialValues({})` or inject fakes via `StartupViewModel` constructor seams

### New regression tests

**`data_source_init_test.dart`:**
- `initDataSource()` second call after success is no-op (use `resetDataSourceInitGuard()` between tests)
- `initDataSource()` second call after failure retries (completer resets)
- Concurrent `initDataSource()` calls share same future

**`startup_view_model_test.dart`:**
- `initializeApp()` transitions through `InitializingApp` → `AppInitialized` on success
- `initializeApp()` transitions to `OfflineNoUserState` when auth is offline-no-user
- `initializeApp()` transitions to `AppInitializationError` on bootstrap failure
- Reentrancy guard: second `initializeApp()` call returns same future
- `retryInitialization()` resets state to `InitializingApp`, disposes, resets locator — does NOT call `initializeApp()` itself; the view reschedules it via post-frame callback when it sees `InitializingApp`
- Minimum splash duration: `AppInitialized` not emitted before 500ms (use `fakeAsync` + `pump`); can also override `StartupViewModel.minSplashDuration` static field (`@visibleForTesting`) to shorten in tests
- Same 500ms check for `OfflineNoUserState` and `AppInitializationError` — error path uses explicit `await splashTimer` safety net after catch
- Inject fake `dataSourceInitializer`, `sharedPreferencesLoader`, `packageInfoLoader` — no real platform calls

**`startup_view_test.dart`:**
<!-- Updated by plan-sync: fn-79-fix-empty-white-startup-screen.4 — added _OfflineNoUserView, _bootstrapScheduled guard, post-frame bootstrap -->
- Renders `SplashScreen` in `InitializingApp` without `RouterService` registered; schedules `initializeApp()` via post-frame callback (guarded by `_bootstrapScheduled` flag)
- Renders `_StartupErrorView` in `AppInitializationError` without router
- Renders `_OfflineNoUserView` in `OfflineNoUserState` without router
- On `AppInitialized`, creates `BestRouterConfig` (verify `locator<RouterService>()` called)
- Retry clears `_routerConfig` and creates fresh one on next `AppInitialized`
- Deep link: deferred `BestRouterConfig` preserves non-`/` initial route through auth/onboarding guards

### Doc updates

**`docs/README.md`:** Add architecture link for `app_launch_and_handoff_to_flutter.md` under the Architecture section (follows existing pattern for other best practice docs).

**`docs/best_practices/integration_test.md`:** Update `createTestApp()` helper — `StartupView(sharedPreferences: prefs)` at line 517 becomes `StartupView(viewModel: ...)` or `StartupView()`. Update the guidance at line 690 about startup testing to reference the `viewModel` injection seam.

**`docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`:** Add Resolution section pointing to the spec and relevant commits.

## Key context

- `testWidgets` runs in fakeAsync by default — `Future.delayed(500ms)` completes when `tester.pump(Duration(milliseconds: 500))` is called
- `tester.pump()` advances one frame — needed to fire post-frame callbacks
- Avoid `tester.runAsync()` — inject synchronous-completing fakes instead (avoids fakeAsync/realAsync mixing issues)
- `ModuleLocator` at `lib/core/utils/locator.dart` — mock classes need `locator.registerMany()` in setUp, `locator.reset()` in tearDown
## Acceptance
- [ ] `test/core/utils/data_source/data_source_init_test.dart` exists with idempotency + retry + concurrency tests
- [ ] `test/startup/startup_view_model_test.dart` exists with state transition + reentrancy + timing tests
- [ ] `test/startup/startup_view_test.dart` exists with router lifecycle + retry + deep-link tests
- [ ] No test uses real `initDataSource()`, `SharedPreferences.getInstance()`, or `PackageInfo.fromPlatform()`
<!-- Updated by plan-sync: test_app.dart doesn't use StartupView — no signature change needed -->
- [ ] `integration_test/utils/test_app.dart` compiles (already uses `MaterialApp.router` directly, not `StartupView`)
- [ ] `docs/README.md` links to `app_launch_and_handoff_to_flutter.md` under Architecture
- [ ] `docs/best_practices/integration_test.md` updated for new `StartupView` constructor
- [ ] `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md` has Resolution section
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (all new + existing tests)
## Done summary
Added startup regression tests (data_source_init guard, StartupViewModel state transitions/timing/reentrancy, StartupView lazy-router handoff/retry/widget lifecycle) and updated docs (README architecture link, integration_test.md aligned with real router-first harness, investigation resolution section).
## Evidence
- Commits: d16acb64a4debfe40ebed64a62ad48759d5beffe, 5b866de, 833693e, e21207f, c538cfb, 699981d, 6997460
- Tests: flutter analyze, flutter test
- PRs: