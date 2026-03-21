# fn-79-fix-empty-white-startup-screen.1 Make native launch surfaces dark on Android and iOS

## Description
Make all native launch surfaces dark (#030303) on both Android and iOS to match the Flutter `SplashScreen` background, eliminating the white flash on cold start.

**Size:** M
**Files:**
- `android/app/src/main/res/values/colors.xml` (create) — define `launch_background` color `#FF030303`
- `android/app/src/main/res/drawable/launch_background.xml` — change `@android:color/white` → `@color/launch_background`
- `android/app/src/main/res/drawable-v21/launch_background.xml` — change `?android:colorBackground` → `@color/launch_background`
- `android/app/src/main/res/drawable-night/launch_background.xml` (create) — same dark color for night mode
- `android/app/src/main/res/values/styles.xml` — change LaunchTheme + NormalTheme parent to `Theme.Black.NoTitleBar`; set `NormalTheme` `android:windowBackground` to `@color/launch_background` explicitly (not relying on theme-resolved `?android:colorBackground`)
- `android/app/src/main/res/values-v31/styles.xml` (create) — `android:windowSplashScreenBackground` = `@color/launch_background`
- `android/app/src/main/res/values-night-v31/styles.xml` (create) — same for night mode
- `android/app/src/main/kotlin/com/example/flutter_kit/MainActivity.kt` — override `onCreate` to install splash screen and add `setOnExitAnimationListener` for Android 12+ fade prevention
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` — change white RGB → `red="0.012" green="0.012" blue="0.012"`
- `ios/Runner/Base.lproj/Main.storyboard` — change `white="1"` → matching dark color

## Approach

- Define `#FF030303` once in `values/colors.xml` and reference `@color/launch_background` everywhere for DRY
- Match Flutter `kitColors.background` at `lib/core/ui/constants/kit_colors.dart:472` — `Color(0xFF030303)`
- Change theme parents to `Theme.Black.NoTitleBar` AND explicitly set `android:windowBackground` to `@color/launch_background` in `NormalTheme` — do not rely on theme-resolved `?android:colorBackground` which gives `#000000` (not `#030303`)
- `values-night/styles.xml:4` already uses `Theme.Black.NoTitleBar` — update its drawable reference + explicit windowBackground as well
- `values-v31` LaunchTheme inherits from base LaunchTheme and adds `android:windowSplashScreenBackground`. No explicit `postSplashScreenTheme` needed — the Flutter embedding declares `NormalTheme` via `io.flutter.embedding.android.NormalTheme` metadata in `AndroidManifest.xml:25-26`, which the system uses automatically for the post-splash transition. (This intentionally supersedes the investigation doc's broader recommendation.)
- For Android 12+ exit animation: override `onCreate` in `MainActivity.kt`, call `installSplashScreen()`, then `splashScreen.setOnExitAnimationListener { it.remove() }`. This requires `Build.VERSION_CODES.S` guard. Check if `androidx.core:core-splashscreen` is already in dependencies; if not, use the native `android.window.SplashScreen` API directly since the project targets API 31+.
- For iOS, use `colorSpace="custom" customColorSpace="sRGB"` format for exact color match
- LaunchImage assets are 1x1px transparent placeholders (68 bytes each) — effectively invisible, no conflict with dark background

## Key context

- `drawable-v21/launch_background.xml:4` uses `?android:colorBackground` which resolves per theme — replace with explicit `@color/launch_background` for consistency
- Android 12+ ignores `windowBackground`; must use `windowSplashScreenBackground` in `values-v31`
- `MainActivity.kt` is at `android/app/src/main/kotlin/com/example/flutter_kit/MainActivity.kt`
- iOS caches launch screens aggressively — testing requires `flutter clean` + app reinstall
- `compileSdkVersion` resolves to 36 via Flutter toolchain; `minSdkVersion` 24 — `values-v31` resources will take effect on API 31+ devices

## Acceptance
- [ ] `values/colors.xml` defines `launch_background` as `#FF030303`
- [ ] `drawable/launch_background.xml` references `@color/launch_background` (not `@android:color/white`)
- [ ] `drawable-v21/launch_background.xml` references `@color/launch_background` (not `?android:colorBackground`)
- [ ] `drawable-night/launch_background.xml` exists with dark color
- [ ] `values/styles.xml` LaunchTheme and NormalTheme use `Theme.Black.NoTitleBar`
- [ ] `NormalTheme` explicitly sets `android:windowBackground` to `@color/launch_background`
- [ ] `values-v31/styles.xml` sets `android:windowSplashScreenBackground`
- [ ] `values-night-v31/styles.xml` sets `android:windowSplashScreenBackground`
- [ ] `MainActivity.kt` installs splash screen and calls `setOnExitAnimationListener` for API 31+
- [ ] `LaunchScreen.storyboard` background is dark (#030303, not white)
- [ ] `Main.storyboard` background is dark (#030303, not white)
- [ ] `flutter analyze` passes
- [ ] App builds and runs on both platforms without errors
- [ ] Visual verification: cold start on Android pre-12, Android 12+, and iOS shows no white flash (uninstall + reinstall to clear caches)

## Done summary
Made all native launch surfaces dark (#030303) on both Android and iOS: defined color once in colors.xml, updated all drawable/style resources for day/night/v31, added Android 12+ setOnExitAnimationListener in MainActivity.kt, and updated both iOS storyboard backgrounds from white to dark.
## Evidence
- Commits: d5e219d3956401c53f85ba1d76bd107cbba864e2
- Tests: flutter analyze
- PRs: