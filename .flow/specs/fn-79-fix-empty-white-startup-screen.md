# Fix Empty/White Startup Screen

## Overview

Users see a white/light native launch surface before Flutter's dark splash screen appears. Root cause: Android and iOS native launch surfaces are configured white/light (#FFFFFF), while the Flutter `SplashScreen` widget uses dark (#030303). Pre-`runApp()` async work (`Supabase`, `SharedPreferences`, `PackageInfo`) extends time on the white native surface.

**Investigation**: `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`

## Scope

1. **Native launch surfaces → dark #030303** (Android + iOS) — DONE (task .1)
2. **Defer `PackageInfo.fromPlatform()` after `runApp()`** — DONE (task .2)
3. **Move Supabase + SharedPreferences after `runApp()`** — make `main()` synchronous, defer `BestRouterConfig`, handle retry (task .3)
4. **Add 500ms minimum splash display time** — frame-anchored via post-frame callback, `_BootstrapResult` typed return (task .4)
5. **Tests + doc updates** — new regression tests, fix broken doc refs (task .5)

Out of scope: flutter_native_splash package adoption, animated native splash, parallelizing sequential awaits inside `initializeApp()`.

**Spec**: `docs/specs/20260322120000_spec_app_launch_handoff.md`
**Plan**: `plan_app_launch_handoff.md`
**Best practices**: `docs/best_practices/architecture/app_launch_and_handoff_to_flutter.md`

## Quick commands

```bash
flutter analyze
flutter test
flutter run --profile --trace-startup -d <device> --dart-define-from-file=env/env.json
```

## Acceptance

- [ ] `main()` contains no `await` — reaches `runApp()` synchronously
- [ ] Supabase + SharedPreferences init inside `StartupViewModel.initializeApp()`
- [ ] `sharedPreferences` removed from constructor chain
- [ ] `BestRouterConfig` deferred to `AppInitialized` state, cleared on retry
- [ ] Splash visible for at least 500ms after first paint (all outcomes)
- [ ] `retryInitialization()` works correctly with view-driven re-bootstrap
- [ ] No white/black flash between native splash and first Flutter frame
- [ ] `flutter analyze` passes
- [ ] All tests pass

## References

- Flutter Android splash docs: https://docs.flutter.dev/platform-integration/android/splash-screen
- Flutter iOS splash docs: https://docs.flutter.dev/platform-integration/ios/splash-screen
- Supabase 2.10.3: `initialize()` is idempotent (returns early if already init'd)
- SharedPreferences: `getInstance()` cached via internal Completer with error reset
