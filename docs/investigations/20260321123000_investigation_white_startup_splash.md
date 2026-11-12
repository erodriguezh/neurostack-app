# Investigation: White/Empty Splash Screen Before App UI

## Summary
The white launch screen is primarily caused by native startup surfaces being configured as white/placeholder on both Android and iOS. A secondary contributor is async work before `runApp()` that extends time spent on those native surfaces.

## Symptoms
- On launch, user sees a fully white/empty screen.
- After a delay, app transitions into normal in-app UI.
- In-app Flutter splash implementation is intended to be dark/branded.

## Investigation Log

### Phase 1 - Initial Assessment
**Hypothesis:** White screen comes from either native launch configuration, Flutter splash rendering, or native→Flutter handoff delay.

**Findings:**
- Relevant launch/startup files exist in Android/iOS native folders and Flutter startup flow.
- This required broad cross-platform context analysis.

**Evidence:**
- Context gathered via `context_builder` + Oracle initial assessment (`chat_id: splash-white-gap-CEE46B`).

**Conclusion:** Needs direct verification with line-level evidence across native + Flutter startup files.

### Phase 2 - Broad Context Gathering (context_builder + Oracle)
**Hypothesis:** Native launch assets/themes are white and mismatch dark Flutter splash.

**Findings:**
- Oracle ranked native launch mismatch as primary candidate.
- Oracle ranked pre-`runApp()` async work as duration amplifier.

**Evidence:**
- Selected files included native launch resources + Flutter startup stack.

**Conclusion:** Proceed to verify with exact file lines + git history.

### Phase 3 - Agent Verification & Evidence Gathering
**Hypothesis:** White is from native config; Flutter splash is not white.

**Findings:**
- Android native launch is explicitly white/light in key files.
- iOS launch storyboard and main storyboard are explicitly white.
- iOS launch image assets are tiny transparent placeholders.
- Flutter splash route paints dark background (#030303).
- `main()` awaits async calls before first `runApp()`, increasing native-only visibility.

**Evidence:**
- **Android native white/light setup**
  - `android/app/src/main/res/drawable/launch_background.xml:4`
    - `<item android:drawable="@android:color/white" />`
  - `android/app/src/main/res/drawable/launch_background.xml:7-11`
    - launch image `<item>` block is commented out.
  - `android/app/src/main/res/drawable-v21/launch_background.xml:4`
    - `<item android:drawable="?android:colorBackground" />`
  - `android/app/src/main/res/values/styles.xml:4`
    - `LaunchTheme` parent = `Theme.Light.NoTitleBar`
  - `android/app/src/main/res/values/styles.xml:15`
    - `NormalTheme` parent = `Theme.Light.NoTitleBar`
  - `android/app/src/main/AndroidManifest.xml:16`
    - activity theme = `@style/LaunchTheme`
  - `android/app/src/main/AndroidManifest.xml:25-26`
    - Flutter metadata binds `@style/NormalTheme`.
  - No Android 12-specific splash attrs found under `android/app/src/main/res` for:
    - `windowSplashScreenBackground`
    - `windowSplashScreenAnimatedIcon`
    - `postSplashScreenTheme`

- **iOS native white setup**
  - `ios/Runner/Info.plist:44-45`
    - `UILaunchStoryboardName` = `LaunchScreen`
  - `ios/Runner/Info.plist:46-47`
    - `UIMainStoryboardFile` = `Main`
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard:22`
    - white background color (`red="1" green="1" blue="1" alpha="1"`).
  - `ios/Runner/Base.lproj/Main.storyboard:19`
    - root Flutter view white background (`white="1" alpha="1"`).

- **iOS launch image placeholders are effectively blank**
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json:4,9,14`
    - references `LaunchImage.png`, `LaunchImage@2x.png`, `LaunchImage@3x.png`.
  - Runtime asset inspection:
    - `sips` output: each is `1x1`, `hasAlpha: yes`.
    - raw PNG decode (Python stdlib) indicates grayscale+alpha pixel data `[255, 0]` (transparent white).

- **Flutter splash is dark (not white)**
  - `lib/startup/startup_view.dart:70`
    - `InitializingApp() => const SplashScreen(),`
  - `lib/startup/splash_screen.dart:112`
    - splash wrapped in `DarkThemeScope`.
  - `lib/startup/splash_screen.dart:114`
    - `backgroundColor: kitColors.background,`
  - `lib/core/ui/constants/kit_colors.dart:472`
    - `background = Color(0xFF030303)`.

- **Pre-`runApp()` async delay**
  - `lib/main.dart:12`
    - `await initDataSource();`
  - `lib/main.dart:13`
    - `await SharedPreferences.getInstance();`
  - `lib/main.dart:14`
    - `await PackageInfo.fromPlatform();`
  - `lib/main.dart:16`
    - `runApp(...)` called only after these complete.
  - `lib/core/utils/data_source/data_source_init.dart:4`
    - `await Supabase.initialize(...)`.

- **Git history / chronology**
  - `git blame` shows Android/iOS launch white defaults introduced in initial commit `8011877` (2025-11-29).
  - `git blame` + `git show` show `await PackageInfo.fromPlatform()` added in commit `9586c08` (2026-03-20), increasing pre-`runApp` work.

**Conclusion:** Confirmed. Native white/placeholder startup is root cause; pre-`runApp()` work amplifies its visibility.

### Phase 4 - Refocused Oracle Deep Dive
**Hypothesis:** There may still be an alternative primary cause in Flutter startup rendering.

**Findings:**
- Oracle agreed strongest explanation is native white/placeholder surfaces.
- Oracle identified pre-`runApp` delay as secondary contributor and iOS `Main.storyboard` as extra handoff white frame contributor.

**Evidence:**
- Oracle response in `splash-white-gap-CEE46B` based on verified line-level evidence above.

**Conclusion:** Flutter splash/widget logic is not primary cause.

## Root Cause
Primary cause: native startup surfaces are configured as white/default placeholders and do not match the dark branded Flutter splash.

- Android launch drawable is white and launch image is inactive (commented).
- iOS launch storyboard is white.
- iOS `Main.storyboard` root background is white, adding white during handoff.
- iOS `LaunchImage` assets are 1x1 transparent placeholders, so no visible branding appears.

Secondary cause: startup work awaited before `runApp()` extends the duration users remain on native launch surfaces.

## Eliminated Hypotheses
- Flutter `SplashScreen` is white → **Eliminated** (dark `#030303` background and `DarkThemeScope`).
- Router/onboarding/auth redirects create pre-splash white screen → **Eliminated as primary** (`InitializingApp` routes directly to `SplashScreen`).
- Missing custom splash retention in `MainActivity`/`AppDelegate` is root cause → **Eliminated** (native resource configuration itself is white).

## Recommendations
1. **Fix native visuals first (highest impact, lowest risk)**
   - Android:
     - Update `android/app/src/main/res/drawable/launch_background.xml` and `drawable-v21/launch_background.xml` to dark background matching `#030303`.
     - Activate/provide a real launch image (or intentionally no image, but dark bg).
     - Update `android/app/src/main/res/values/styles.xml` launch/normal themes to avoid light default mismatch.
     - Optionally add Android 12 splash attributes for consistency.
   - iOS:
     - Change `ios/Runner/Base.lproj/LaunchScreen.storyboard` background to dark.
     - Replace 1x1 transparent `LaunchImage*.png` placeholders with actual branding or remove image view usage.
     - Change `ios/Runner/Base.lproj/Main.storyboard` root view background to dark to avoid handoff flash.

2. **Reduce pre-`runApp()` work (second pass)**
   - Move non-critical awaits after `runApp()` where safe (start with `PackageInfo.fromPlatform()`).
   - Keep only strictly required bootstrap work before first frame.

3. **Measure startup timeline after fixes**
   - Add startup timestamps around pre-runApp tasks and first Flutter frame.
   - Capture launch screen video on both platforms to confirm no white gap remains.

## Preventive Measures
- Add a startup visual parity checklist for native launch vs first Flutter screen (background, logo, theme mode).
- Add release smoke test on Android + iOS that records first 2–3 seconds of startup.
- Document policy: any pre-`runApp()` await requires explicit justification and expected duration impact.
