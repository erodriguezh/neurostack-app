# Ubiquitous Language

## App startup lifecycle

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Native launch surface** | The OS-rendered screen visible from app tap until Flutter draws its first frame | Splash screen (unqualified), launch screen (ambiguous) |
| **Flutter splash** | The first Flutter-rendered startup screen while initialization completes | Splash screen (unqualified) |
| **First frame** | The moment Flutter first renders to screen and replaces the native launch surface | First paint, initial render |
| **Pre-runApp work** | Async initialization that blocks `runApp()` from being called | Startup work (too vague) |
| **Phased bootstrap** | Startup strategy where startup-critical dependencies are prepared first and deferred dependencies are prepared after async resolution | Split registration, two-phase init |
| **Cold start** | A full app launch from a terminated state where startup surfaces are visible | Fresh launch, first launch |

## App state machine

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **InitializingApp** | The app state from `runApp()` until initialization completes | Loading, booting |
| **AppInitialized** | The app state after successful initialization, where normal routing drives navigation | Ready, loaded |
| **AppInitializationError** | The app state when initialization fails and the user is shown recovery/retry UI | Crash, failure |
| **OfflineNoUserState** | The app state when no cached user exists and the device is offline at startup | Offline error |

## Dependency initialization

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Startup-critical module** | A dependency that must be available before first-frame-critical flow | Core module (too vague) |
| **Deferred module** | A dependency that can be initialized after async resolution without blocking first frame | Late module, lazy module (conflicts with DI lazy semantics) |

## Theming policy

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Dark-first route** | A route policy that always renders with dark theme regardless of system setting | Dark mode route |
