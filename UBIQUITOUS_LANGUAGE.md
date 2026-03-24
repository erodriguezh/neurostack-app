# Ubiquitous Language

## App startup lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Native launch surface** | The OS-rendered screen visible from app tap until Flutter draws its first frame | Splash screen (unqualified), launch screen (ambiguous) |
| **Flutter splash** | The first Flutter-rendered startup screen while initialization completes | Splash screen (unqualified) |
| **First frame** | The moment Flutter first renders to screen and replaces the native launch surface | First paint, initial render |
| **Cold start** | A full app launch from a terminated state where startup surfaces are visible | Fresh launch, first launch |
| **Bootstrap** (new) | The async initialization sequence that runs behind the Flutter splash, from `initDataSource()` through service init to final state resolution | Startup work, init, setup |
| **Minimum splash duration** (new) | The 500ms floor enforced via `Future.wait` so the entrance animation completes before any state transition | Splash delay, artificial delay |
| **Frame-anchored timing** (new) | Starting a timer from a post-frame callback so the measured interval begins after the splash is actually visible on screen | Post-frame timing |

## App state machine

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **InitializingApp** | The app state from `runApp()` until bootstrap completes or fails | Loading, booting |
| **AppInitialized** | The app state after successful bootstrap, where normal routing drives navigation | Ready, loaded |
| **AppInitializationError** | The app state when bootstrap fails and the user is shown recovery/retry UI | Crash, failure |
| **OfflineNoUserState** | The app state when no cached user exists and the device is offline at startup | Offline error |
| **BootstrapResult** (new) | The typed outcome of `_bootstrap()` — either `initialized` or `offlineNoUser` — used to preserve branching through `Future.wait` | Return value, status |

## Dependency initialization

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Startup-critical module** | A dependency that must be available before first-frame-critical flow | Core module (too vague) |
| **Deferred module** | A dependency that can be initialized after async resolution without blocking first frame | Late module, lazy module (conflicts with DI lazy semantics) |
| **Phased bootstrap** (updated) | Startup strategy where `initDataSource()` and `SharedPreferences.getInstance()` run first, then `buildModules()` registers all DI modules, then services init sequentially | Split registration, two-phase init |
| **Idempotent init guard** (new) | A completer-based wrapper around `Supabase.initialize()` that makes it safe to call multiple times: no-op after success, resets on failure for genuine retry | Double-init guard, singleton guard |
| **Test seam** (new) | An injectable constructor parameter (e.g., `dataSourceInitializer`, `sharedPreferencesLoader`) that defaults to the real implementation but can be replaced in tests | Mock point, hook |

## Router lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Deferred router** (new) | The pattern where `BestRouterConfig` is created lazily on first `AppInitialized` render, not during `initState()` | Lazy router |
| **Router invalidation** (new) | Clearing the cached `_routerConfig` when the app returns to `InitializingApp` state, ensuring a fresh `RouterService` instance is used after `locator.reset()` | Router reset, router refresh |
| **App shell** (new) | A non-router `MaterialApp` used for splash, error, and offline screens, sharing localization delegates, theme, and `Translate.init()` with the router variant | Basic MaterialApp, wrapper |
| **Router app** (new) | The `MaterialApp.router` variant used only in `AppInitialized` state, wrapping `InternalNotificationListener` and `_AuthStatusShell` | Full app, main app |

## Retry lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Retry** (new) | The path triggered by user tap on error/offline screen: flips to `InitializingApp` before disposal, then the view schedules re-bootstrap from a post-frame callback | Restart, re-init |
| **Flip-before-disposal** (new) | The safety invariant where `appStateNotifier.value = InitializingApp` is set before `_disposeServices()` and `locator.reset()`, preventing widgets from reading disposed services | State-first reset |
| **View-driven re-bootstrap** (new) | The pattern where `retryInitialization()` only cleans up, and the view's `ValueListenableBuilder` schedules `initializeApp()` via post-frame callback when it sees `InitializingApp` | ViewModel-driven retry |

## Theming policy

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Dark-first route** | A route policy that always renders with dark theme regardless of system setting | Dark mode route |

## Relationships

- A **Cold start** shows the **Native launch surface**, then the **Flutter splash**, then the app
- The **Bootstrap** runs concurrently behind the **Flutter splash** during **InitializingApp**
- The **Minimum splash duration** and **Bootstrap** are raced via `Future.wait` — whichever is slower determines when the state transition happens
- **BootstrapResult** determines the terminal state: `initialized` → **AppInitialized**, `offlineNoUser` → **OfflineNoUserState**, exception → **AppInitializationError**
- The **Deferred router** depends on **AppInitialized** — it is never created during **InitializingApp**
- **Router invalidation** is triggered by **Retry**, which returns the app to **InitializingApp**
- The **App shell** renders during **InitializingApp**, **OfflineNoUserState**, and **AppInitializationError**; the **Router app** renders only during **AppInitialized**
- The **Idempotent init guard** makes the **Bootstrap** safe across **Retry** cycles

## Example dialogue

> **Dev:** "When the user taps retry on the error screen, what happens to the **Deferred router**?"
> **Domain expert:** "The **Retry** flips to **InitializingApp** first — that's the **Flip-before-disposal** invariant. The view sees **InitializingApp**, triggers **Router invalidation** to clear the stale `BestRouterConfig`, then schedules **View-driven re-bootstrap** from a post-frame callback."
> **Dev:** "So the 500ms timer starts after the **Flutter splash** repaints?"
> **Domain expert:** "Exactly. That's the **Frame-anchored timing** — the **Minimum splash duration** begins after the splash frame paints, not when `retryInitialization()` is called. On both **Cold start** and **Retry**, the entrance animation gets its full 500ms."
> **Dev:** "What if `initDataSource()` already succeeded on the first attempt?"
> **Domain expert:** "The **Idempotent init guard** handles that — second call is a no-op after success. If the first attempt failed, the guard resets so **Retry** genuinely re-attempts Supabase initialization."

## Flagged ambiguities

- **"splash screen"** was used throughout the conversation to mean both the **Native launch surface** (OS-rendered) and the **Flutter splash** (Dart widget). These are distinct: the native surface covers engine startup, the Flutter splash covers **Bootstrap**. Always qualify which one.
- **"restart"** was used interchangeably with **Retry**. In this codebase, `restartApp()` in `AppLifecycleService` delegates to `retryInitialization()` in `StartupViewModel`. Use **Retry** for the user-facing concept and `restartApp()`/`retryInitialization()` for the code path.
- **"delay"** was used to describe the **Minimum splash duration**, but it is not an artificial delay — it is a floor that only adds wait time when **Bootstrap** is faster than 500ms. Prefer "minimum duration" over "delay."
- **"pre-runApp work"** (from the previous glossary) is now obsolete — after the refactor, there is no async work before `runApp()`. The term is replaced by **Bootstrap**, which runs after `runApp()` inside `initializeApp()`.
