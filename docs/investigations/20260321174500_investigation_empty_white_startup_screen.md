# Investigation: Empty/White Screen Before Flutter Splash

## Summary
The empty/white startup frame is caused by native launch surfaces being configured as white/light on both Android and iOS. `SplashScreen` in Flutter is dark and correctly wired for `InitializingApp`, but it can only appear after `runApp()`. Pre-`runApp()` async work increases how long users see native launch surfaces.

## Symptoms
- On launch, a blank/white screen appears first.
- After that, app initialization continues and Flutter UI appears.
- Expected: `lib/startup/splash_screen.dart` visual should be seen instead of a white/empty frame.

## Investigation Log

### Phase 1 - Initial Assessment
**Hypothesis:** White frame could be from Flutter splash rendering, startup state routing, or native launch surfaces.

**Findings:**
- `StartupView` maps `InitializingApp` to `SplashScreen`.
- `main()` awaits async work before `runApp()`.

**Evidence:**
- `lib/startup/startup_view.dart:70` → `InitializingApp() => const SplashScreen()`
- `lib/main.dart:12-16` → awaited startup work then `runApp(...)`

**Conclusion:** Need cross-platform native launch verification.

### Phase 2 - Broad Context Gathering (`context_builder` + Oracle)
**Hypothesis:** Native launch resources/themes are white and mismatched with dark Flutter splash.

**Findings:**
- Context builder selected startup flow + Android/iOS launch files + DI/startup dependencies.
- Oracle initial assessment prioritized native launch misconfiguration + pre-`runApp` delay.

**Evidence:**
- `context_builder` run with `response_type: question`
- Oracle chat id: `startup-white-screen-E0D6EB`

**Conclusion:** Proceed with line-level verification and git chronology.

### Phase 3 - Agent Verification & Evidence Gathering
**Hypothesis:** Flutter splash is not the source of whiteness; native launch surfaces are.

**Findings:**
- Flutter splash path is dark and correctly configured.
- Android launch drawable/theme are white/light defaults.
- iOS launch + main storyboard backgrounds are white.
- `runApp()` is delayed by awaited startup work.

**Evidence:**

- **Flutter splash (dark, correct routing)**
  - `lib/startup/startup_view.dart:70`
    - `InitializingApp() => const SplashScreen(),`
  - `lib/startup/splash_screen.dart:114`
    - `backgroundColor: kitColors.background,`
  - `lib/core/ui/constants/kit_colors.dart:472`
    - `static const background = Color(0xFF030303);`

- **Pre-`runApp()` delay**
  - `lib/main.dart:12` → `await initDataSource();`
  - `lib/main.dart:13` → `await SharedPreferences.getInstance();`
  - `lib/main.dart:14` → `await PackageInfo.fromPlatform();`
  - `lib/main.dart:16` → `runApp(...)`
  - `lib/core/utils/data_source/data_source_init.dart:4` → `await Supabase.initialize(...)`

- **Android native white/light launch**
  - `android/app/src/main/res/drawable/launch_background.xml:4`
    - `<item android:drawable="@android:color/white" />`
  - `android/app/src/main/res/values/styles.xml:4`
    - `LaunchTheme` parent: `Theme.Light.NoTitleBar`
  - `android/app/src/main/res/values/styles.xml:15-16`
    - `NormalTheme` uses `Theme.Light.NoTitleBar` and `?android:colorBackground`
  - `android/app/src/main/AndroidManifest.xml:16`
    - activity theme: `@style/LaunchTheme`
  - `android/app/src/main/AndroidManifest.xml:25-26`
    - `io.flutter.embedding.android.NormalTheme` metadata points to `@style/NormalTheme`
  - Search in `android/app/src/main/res` found no Android 12 splash attrs:
    - `windowSplashScreenBackground`
    - `postSplashScreenTheme`

- **iOS native white launch/handoff**
  - `ios/Runner/Info.plist:44-47`
    - `UILaunchStoryboardName = LaunchScreen`, `UIMainStoryboardFile = Main`
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard:22`
    - white background (`red="1" green="1" blue="1"`)
  - `ios/Runner/Base.lproj/Main.storyboard:19`
    - white root background (`white="1" alpha="1"`)

- **Git chronology**
  - `git blame` shows native white defaults from initial commit `8011877` (2025-11-29):
    - Android `launch_background.xml`, `values/styles.xml`
    - iOS `LaunchScreen.storyboard`, `Main.storyboard`
  - `git blame` + diff show `PackageInfo.fromPlatform()` added pre-`runApp` in `e6b041f` (2026-03-21):
    - `lib/main.dart:14` now awaits package info before `runApp`

**Conclusion:** Confirmed. Root cause is native white launch surfaces; pre-`runApp()` awaits amplify visibility.

### Phase 4 - Refocused Oracle Deep Dive
**Hypothesis:** There may still be a primary Flutter-side explanation.

**Findings:**
- Oracle ruled out credible Flutter-primary causes given verified evidence.
- Recommended minimal, low-risk sequence: native surfaces first, then startup timing optimization.

**Evidence:**
- Oracle (`startup-white-screen-E0D6EB`) response after evidence handoff.

**Conclusion:** Root cause diagnosis is stable and actionable.

## Root Cause
Primary root cause: platform-native launch and handoff surfaces are configured white/light, while intended Flutter splash is dark. Therefore, users see white before first Flutter frame.

Secondary contributor: `main()` blocks `runApp()` on async startup tasks (`Supabase`, `SharedPreferences`, `PackageInfo`), extending time on native surfaces.

## Eliminated Hypotheses
- **`lib/startup/splash_screen.dart` itself is white** → Eliminated (dark `#030303` background).
- **Startup state bypasses splash** → Eliminated (`InitializingApp` explicitly returns `SplashScreen`).
- **Router redirect is primary cause** → Eliminated as primary (redirects happen after initialization path; initial white occurs before Flutter frame).

## Recommendations
1. **Fix native launch surfaces first (lowest risk / highest impact)**
   - Android:
     - Make launch background dark `#030303` in `drawable/launch_background.xml` and `drawable-v21/launch_background.xml`.
     - Update `values/styles.xml` and `values-night/styles.xml` Launch/Normal themes to dark backgrounds.
     - Add Android 12+ `values-v31` and `values-night-v31` splash attributes (`windowSplashScreenBackground`, `postSplashScreenTheme`).
   - iOS:
     - Set dark background in `ios/Runner/Base.lproj/LaunchScreen.storyboard`.
     - Set dark root background in `ios/Runner/Base.lproj/Main.storyboard` to avoid handoff flash.

2. **Then reduce pre-`runApp()` waits (targeted optimization)**
   - Defer `PackageInfo.fromPlatform()` until after `runApp()` (or later startup stage).
   - Keep `RouterService` registration timing safe for `StartupView.initState()` contract.
   - Keep `Supabase.initialize()` timing conservative unless explicitly validated.

3. **Validate visually on both platforms**
   - Android 12+ and pre-12 devices/emulators.
   - iOS simulator/device (clear launch screen cache by reinstalling app + `flutter clean` if needed).

## Resolution

Implemented across epic `fn-79-fix-empty-white-startup-screen` (branch `feature/splash-screen`):

1. **Native launch surfaces made dark (#030303)** on Android and iOS (task .1).
2. **`PackageInfo.fromPlatform()` deferred** after `runApp()` (task .2).
3. **Atomic startup refactor**: synchronous `main()`, deferred `BestRouterConfig`, idempotent `initDataSource` with Completer guard (task .3).
4. **Minimum splash display time** via `Future.wait([_bootstrap(), splashTimer])`, ensuring the entrance animation completes before any state transition (task .4). Originally 500ms; later increased to 1000ms in epic `fn-80-increment-splash-screen-min-visible` to allow the breathing glow to be briefly visible after the entrance animation.
5. **Regression tests and doc updates** covering `StartupViewModel`, `StartupView`, and `initDataSource` guard (task .5).

**Spec**: `docs/specs/20260322120000_spec_app_launch_handoff.md`
**Best practices**: `docs/best_practices/architecture/app_launch_and_handoff_to_flutter.md`

## Preventive Measures
- Add startup visual parity checklist: native launch bg must match first Flutter route bg.
- Require explicit justification for any new pre-`runApp()` await.
- Add startup smoke verification (first 2–3 seconds) in release QA on Android + iOS.
