# Flutter Launch Handoff Best Practices

## Scope

Use this document when implementing a smooth transition from the OS-managed native splash to the first Flutter-rendered screen in a Flutter app.

This document is intentionally narrow:

- It covers cold-start launch handoff for standard Flutter apps.
- It covers the common case where product wants a native splash and a visually matching Flutter startup screen.
- It does not cover full brownfield/add-to-app architecture beyond a few guardrails.

Reference files in a standard Flutter app:

- `lib/main.dart`
- `lib/app/app.dart`
- `lib/app/startup/startup_screen.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values-v31/styles.xml`
- `ios/Runner/Info.plist`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`

## Practice 1: Handoff To The First Flutter Frame, Not To "Another Splash"

Treat the first Flutter frame as the target of the native splash handoff.

Do this:

- Make the first Flutter route visually identical or very close to the native launch surface.
- If product needs additional loading UI, show it inside Flutter after the first frame is already visible.
- Keep the first Flutter screen static or nearly static for the first few frames.

Do not do this:

- Do not rely on a Dart widget to hide engine startup.
- Do not add a very different Flutter splash after the native splash unless the product explicitly wants a double-step transition.
- Do not delay `runApp()` just to keep the native splash visible longer.

Good mental model:

- Native splash covers engine startup.
- First Flutter frame makes the transition feel seamless.
- Any real app loading after that is a normal Flutter screen state, not a substitute for the native splash.

## Practice 2: Keep `main()` Lean And Reach `runApp()` Fast

The fastest path to a smooth launch is:

1. Initialize bindings.
2. Do only truly required synchronous setup.
3. Call `runApp()`.
4. Move non-critical work to after the first frame.

Allowed before `runApp()`:

- `WidgetsFlutterBinding.ensureInitialized()`
- Tiny synchronous config reads already in memory
- Minimal error-reporting/bootstrap wiring that does not block on network or disk

Move after the first frame:

- Firebase token fetches
- Remote config fetches
- Preferences or secure storage reads that are not required to paint the first route
- Dependency injection that triggers async I/O
- Deep-link navigation pushes
- Feature flag fetches

Common launch offenders:

- `FirebaseMessaging.instance.getToken()`
- `SharedPreferences.getInstance()`
- synchronous JSON parsing or database migrations
- several sequential `await` calls that could run concurrently with `Future.wait`

Preferred shape in `lib/main.dart`:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}
```

If some bootstrap must happen, keep it narrow and move it into Flutter:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _startNonCriticalBootstrap();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedStartupView();
  }
}
```

## Practice 3: Use One First-Frame Hold Mechanism, Not Several

Choose one of these approaches:

- No explicit hold at all. Preferred for most apps.
- `flutter_native_splash.preserve()` / `remove()` if critical bootstrap must finish before Flutter may present.
- Manual `deferFirstFrame()` / `allowFirstFrame()` only when you are intentionally working at the framework level and not using the plugin wrapper.

Do not combine:

- `flutter_native_splash.preserve()`
- `WidgetsBinding.deferFirstFrame()`
- any second custom splash control layer

If you must hold the first frame, release it on every path.

Safe pattern with `flutter_native_splash` in `lib/main.dart`:

```dart
void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const App());
}
```

Safe removal pattern inside the first route:

```dart
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _loadCriticalStartupState();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedStartupView();
  }
}
```

Rules:

- Keep the hold short.
- Put release logic in `finally`.
- Never wait on unbounded network calls while the native splash is held.
- Never navigate before a mounted widget tree exists.
- If you choose a pre-`runApp()` `preserve()` / `remove()` flow, keep it bounded and accept that it lengthens the native splash. Reserve it for hard blockers only.

## Practice 4: Match Android Launch Theme, Normal Theme, And First Flutter Screen

On Android, most visible flashes come from theme mismatch, not from Flutter itself.

Files to inspect:

- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values-v31/styles.xml`
- `android/app/src/main/AndroidManifest.xml`

Rules:

- `LaunchTheme` background must match `NormalTheme` background.
- `NormalTheme` background must match the first Flutter frame background color.
- Status bar and navigation bar appearance must match across launch and normal themes.
- Fullscreen or edge-to-edge flags must not change during handoff unless the change is intentional and delayed.
- If `LaunchTheme` uses a drawable, start by pointing `NormalTheme` at the same drawable. If that causes a layout mismatch, keep at least the same solid background color.

Example shape for pre-Android-12 theme alignment:

```xml
<!-- android/app/src/main/res/values/styles.xml -->
<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
</style>

<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
</style>
```

If the drawable approach creates a visible position jump, keep the background color identical in both themes and make the first Flutter frame match that color exactly.

Android 12+ rules:

- Configure splash resources in `values-v31`.
- Use `windowSplashScreenBackground`.
- Use `windowSplashScreenAnimatedIcon`.
- Accept the system constraint: solid background plus centered icon/logo.
- Remove or ignore legacy splash APIs from old Flutter guidance.
- Size the Android 12+ icon asset for the platform mask. A practical default is a `1152x1152` source with transparent padding around the visible mark.

Example shape for Android 12+:

```xml
<!-- android/app/src/main/res/values-v31/styles.xml -->
<style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowSplashScreenBackground">@color/launch_background</item>
    <item name="android:windowSplashScreenAnimatedIcon">@drawable/android12splash</item>
    <item name="android:windowSplashScreenBrandingImage">@null</item>
    <item name="android:windowBackground">@color/launch_background</item>
</style>
```

Optional Android 12+ flicker fix in `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
```

Delete legacy manifest metadata when targeting modern Flutter and Android 12+:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="io.flutter.embedding.android.SplashScreenDrawable"
    android:resource="@drawable/launch_background" />
```

If that block still exists, remove it. Leaving it in place can create a real double splash on Android 12+.

Avoid these Android mistakes:

- White `NormalTheme` with a dark splash
- Changing status bar icon brightness during handoff
- Leaving old `SplashScreenDrawable` or `provideSplashScreen()` era config in place on modern Flutter
- Treating Android 12+ like pre-12 full-screen splash rendering

## Practice 5: Configure iOS LaunchScreen Exactly

On iOS, small config mistakes can produce black gaps or black fallbacks.

Files to inspect:

- `ios/Runner/Info.plist`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`

Rules:

- Set `UILaunchStoryboardName` to `LaunchScreen`
- Do not include `.storyboard` in the value
- Keep the storyboard background aligned with the first Flutter frame
- Keep launch assets modest in size
- Avoid oversized bitmap assets in the launch storyboard
- Prefer a solid color, a small centered mark, or a small repeatable asset over a full-resolution launch bitmap

Correct `Info.plist` entry:

```xml
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

Launch storyboard guidance:

- Use simple layout
- Use static assets only
- Avoid large, full-screen bitmaps if a color plus centered mark works
- If you need a gradient or texture, prefer a tiny repeatable slice over a huge PNG
- Match dark/light variants if the app supports them at launch

If iOS shows black after the splash disappears, suspect:

- async work before `runApp()`
- a stuck Future in startup
- DI ordering bugs
- Firebase or messaging calls before first frame
- startup navigation firing too early

## Practice 6: Defer Startup Navigation Until After The First Frame

Deep links and startup routing are common reasons the handoff breaks.

Do this:

- Parse launch intent or link data as early as needed
- Delay actual navigation until after the first frame
- Use `addPostFrameCallback` from a mounted widget

Example:

```dart
class StartupCoordinator extends StatefulWidget {
  const StartupCoordinator({super.key});

  @override
  State<StartupCoordinator> createState() => _StartupCoordinatorState();
}

class _StartupCoordinatorState extends State<StartupCoordinator> {
  @override
  void initState() {
    super.initState();
    _routeAfterFirstFrame();
  }

  Future<void> _routeAfterFirstFrame() async {
    final initialRoute = await _resolveInitialRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(initialRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedStartupView();
  }
}
```

Do not do this:

- Push routes before `runApp()`
- Push routes from `main()` using a global navigator before the first tree exists
- Block the first frame while waiting for a deep-link network round trip
- Combine this with `flutter_native_splash.preserve()` and manual `deferFirstFrame()` in the same launch flow

## Practice 7: Make The First Flutter Route Cheap To Render

A visually correct handoff can still feel bad if the first route janks.

Rules for the first route:

- Prefer a static background and a single logo/wordmark
- Avoid expensive blurs, shaders, shadows, and large image decodes
- Avoid immediate hero transitions
- Avoid kicking off heavy list layouts or complex tab scaffolds on the first frame
- Keep the first animation subtle or delay it until the app is stable

Practical target:

- The first route should be able to paint quickly even on a cold physical device in profile or release mode.

If you need rich motion:

- show the static branded frame first
- then start animation after startup state is ready

If the splash art shifts vertically during handoff, align system UI mode before `runApp()`:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const App());
}
```

Only do this if the native launch surface is also edge-to-edge. The goal is to keep the native and Flutter canvases aligned, not to change layout policy mid-launch.

## Practice 8: Verify In Profile/Release With A Short Checklist

Do not judge launch quality in debug mode.

Useful command:

```bash
flutter run --profile --trace-startup
```

Test matrix:

- Android 12+ physical device
- One older Android device or emulator for pre-12 resources
- iPhone physical device
- Cold launch after force quit
- Relaunch after process eviction
- Dark mode and light mode if launch assets vary

Verify these specific outcomes:

- No white or black flash between native splash and first Flutter frame
- No visible status bar or navigation bar reset during handoff
- No double splash on Android 12+
- No permanent splash hold if bootstrap throws
- No early-route navigation errors
- No obvious jank in the first visible Flutter frames
- No release-only regression caused by stale installs or resource stripping

Quick review checklist before merging:

- `lib/main.dart` reaches `runApp()` quickly
- Only one splash hold mechanism is used
- Splash release happens on all code paths
- Android `LaunchTheme` and `NormalTheme` backgrounds match
- Android 12+ resources exist in `values-v31`
- iOS `UILaunchStoryboardName` is `LaunchScreen`
- First Flutter route matches launch visuals closely

Measurement notes:

- Use Flutter timeline data or DevTools startup tracing for time-to-first-frame work. Native lifecycle callbacks like Android `onResume` or iOS `viewWillAppear` fire too early to represent first Flutter paint.
- If splash behavior changes after `applicationId`, `namespace`, or package-name work, fully uninstall and reinstall before diagnosing.
- If debug works and release fails, inspect release resource packaging and shrinker configuration before changing Dart startup code.

## Troubleshooting

| Symptom | Likely Cause | First Check |
| --- | --- | --- |
| White flash on Android | `NormalTheme` background mismatch | `android/app/src/main/res/values/styles.xml` |
| Black fallback on first iOS launch | `UILaunchStoryboardName` includes `.storyboard` | `ios/Runner/Info.plist` |
| Splash stays up forever | `remove()` or `allowFirstFrame()` skipped on an error path | `lib/main.dart` and startup coordinator |
| Splash art jumps vertically | Native and Flutter system UI modes differ | Android themes and `SystemChrome` setup |
| Double splash on Android 12+ | Legacy splash metadata still present | `android/app/src/main/AndroidManifest.xml` |
| Black screen after iOS splash | oversized storyboard asset or stalled startup Future | `LaunchScreen.storyboard` and `main()` bootstrap |
| Deep link opens to blank screen | navigation fired before first frame | startup route handling |

## Appendix: Add-to-App Guardrail

This document is for standard Flutter app launch, but one add-to-app rule is worth keeping:

- If a native app presents Flutter screens repeatedly, do not create a cold `FlutterEngine` every time.
- Pre-warm a `FlutterEngineGroup` during app idle time and reuse cached engines.
- Typical integration points are `ios/Runner/AppDelegate.swift` and `android/app/src/main/kotlin/.../Application.kt`.

This reduces time to first Flutter frame for embedded surfaces. It does not change the guidance for normal full-app cold launch.

## Default Team Standard

Unless there is a proven reason to do more, the team standard should be:

1. Native splash configured correctly on Android and iOS.
2. `main()` does almost nothing before `runApp()`.
3. First Flutter route visually matches the native splash.
4. Non-critical startup work begins after the first frame.
5. Use splash deferral only for short, critical startup state, with guaranteed cleanup.

This standard solves most launch-transition defects without adding fragile startup control code.
