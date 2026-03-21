# Fix Empty/White Startup Screen

## Overview

Users see a white/light native launch surface before Flutter's dark splash screen appears. Root cause: Android and iOS native launch surfaces are configured white/light (#FFFFFF), while the Flutter `SplashScreen` widget uses dark (#030303). Pre-`runApp()` async work (`Supabase`, `SharedPreferences`, `PackageInfo`) extends time on the white native surface.

**Investigation**: `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`

## Scope

1. **Native launch surfaces → dark #030303** (Android + iOS)
2. **Defer `PackageInfo.fromPlatform()` after `runApp()`** to reduce pre-render wait

Out of scope: Supabase/SharedPreferences deferral, flutter_native_splash package adoption, animated native splash.

## Key Decisions

- **Color**: Exactly `#030303` via custom `colors.xml` / explicit storyboard RGB — NOT `@android:color/black` (#000000), which is perceptibly different on OLED
- **DI strategy — phased bootstrap**: Remove `PackageInfo` from `buildModules()` signature. In `initializeApp()`: (1) call `locator.registerMany(buildModules(sharedPreferences: ...))` synchronously first (registers RouterService and all core modules), (2) then `await PackageInfo.fromPlatform()`, (3) then `locator.registerMany([Module<PackageInfo>(...)])` as a separate registration. This preserves the `StartupView.initState()` contract where `locator<RouterService>()` is called synchronously after the non-awaited `initializeApp()` call.
- **PackageInfo failure**: Caught by existing `try/catch` in `initializeApp()` → error screen with retry (consistent behavior)
- **Android 12+**: Create `values-v31` + `values-night-v31` with `windowSplashScreenBackground`. The existing Flutter embedding `NormalTheme` metadata in AndroidManifest handles `postSplashScreenTheme` implicitly — the system transitions from the v31 splash to NormalTheme automatically via `io.flutter.embedding.android.NormalTheme`. Add `setOnExitAnimationListener` in `MainActivity.kt` to prevent fade flicker.
- **Night mode**: Create `drawable-night/launch_background.xml` for future-proofing

## Quick commands

```bash
# Build and run on iOS simulator (clear cache first)
flutter clean && flutter pub get && flutter run -d 1EA9596A-EBDF-4B22-9781-181F20DEB836 --dart-define-from-file=env/env.json

# Analyze
flutter analyze

# Run tests
flutter test
```

## Acceptance

- [ ] No white flash visible on cold start (Android pre-12, Android 12+, iOS)
- [ ] Native launch surface matches Flutter splash background (#030303)
- [ ] `PackageInfo.fromPlatform()` no longer blocks `runApp()`
- [ ] `flutter analyze` passes
- [ ] Existing tests pass
- [ ] Retry initialization path still works (error → retry → success)

## Verification Matrix

Cold-start validation (uninstall + reinstall, or `flutter clean` + rebuild):
- [ ] Android pre-12 (API 24–30): dark launch surface, no white flash
- [ ] Android 12+ (API 31+): dark system splash, no crossfade artifact, no white flash
- [ ] iOS: dark launch screen, no white flash (requires `flutter clean` + app reinstall to clear storyboard cache)
- [ ] At least one light-mode and one dark-mode system setting tested per platform

## References

- Flutter Android splash docs: https://docs.flutter.dev/platform-integration/android/splash-screen
- Flutter iOS splash docs: https://docs.flutter.dev/platform-integration/ios/splash-screen
- Android 12 SplashScreen API: https://developer.android.com/develop/ui/views/launch/splash-screen
- Investigation: `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`
- Related epics: fn-78 (established PackageInfo injection), fn-75 (dark-first route policy)
