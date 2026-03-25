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

## RevenueCat subscription architecture (new)

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Hosted Paywall** (new) | A paywall UI built and rendered by RevenueCat's SDK via `RevenueCatUI.presentPaywall()`, not custom app code | Custom paywall, local paywall, native paywall |
| **Paywall Component** (new) | A configurable UI element within a Hosted Paywall (Text, Button, Image, Package, Purchase Button, Footer) | Widget (ambiguous with Flutter), element |
| **Offering** (new) | A RevenueCat-managed named set of Packages presented to the user; exactly one is marked "current" | Plan set, product group |
| **Package** (new) | A duration-keyed container within an Offering (`$rc_monthly`, `$rc_annual`) that holds one Product per store | Plan, tier (overloaded) |
| **Entitlement** (new) | A RevenueCat-managed named set of features unlocked by one or more Products across stores | Permission, access level, feature flag |
| **RevenueCat Product** (new) | A purchasable subscription item registered in RevenueCat, linked to a store-specific product identifier | Product (unqualified — ambiguous with App Store Connect Product) |
| **Test Store** (new) | RevenueCat's sandbox app type for development testing without a real store connection | Sandbox (ambiguous with Apple Sandbox), dev store |
| **App Store app** (new) | The RevenueCat app entry connected to a real App Store bundle ID, requiring ASC API key configuration | Production app (too vague), real app |

## Paywall compliance (new)

| Term | Definition | Aliases to avoid |
|------|-----------|-----------------|
| **Restore Purchases** (new) | An Apple-required user action that re-syncs previous store purchases to recover entitlements on a new device or reinstall | Sync purchases (different SDK method), recover |
| **Manage Subscription** (new) | The Settings tile action that opens the platform's subscription management page | Cancel Subscription (old label — action is broader than cancellation) |
| **Auto-Renewal Disclosure** (new) | Required legal text informing users about subscription renewal terms, cancellation window, and billing behavior | Fine print, legal text, boilerplate |
| **Introductory Offer** (new) | Apple's term for a free trial or discounted period on an auto-renewable subscription, configured in App Store Connect | Free trial (when referring to the configuration mechanism), promo |
| **Delayed Close Button** (new) | A paywall dismiss button with an artificial delay before appearing — Apple rejects these during App Review | Timed close, gated dismiss |
| **canAccessPremium** (new) | The inclusive boolean property that is `true` for both premium subscribers AND trial users | isPremium (excludes trial users — see flagged ambiguities) |

## Relationships

- A **Cold start** shows the **Native launch surface**, then the **Flutter splash**, then the app
- The **Bootstrap** runs concurrently behind the **Flutter splash** during **InitializingApp**
- The **Minimum splash duration** and **Bootstrap** are raced via `Future.wait` — whichever is slower determines when the state transition happens
- **BootstrapResult** determines the terminal state: `initialized` → **AppInitialized**, `offlineNoUser` → **OfflineNoUserState**, exception → **AppInitializationError**
- The **Deferred router** depends on **AppInitialized** — it is never created during **InitializingApp**
- **Router invalidation** is triggered by **Retry**, which returns the app to **InitializingApp**
- The **App shell** renders during **InitializingApp**, **OfflineNoUserState**, and **AppInitializationError**; the **Router app** renders only during **AppInitialized**
- The **Idempotent init guard** makes the **Bootstrap** safe across **Retry** cycles
- (new) An **Offering** contains one or more **Packages**; each **Package** holds one **RevenueCat Product** per store
- (new) An **Entitlement** is unlocked by one or more **RevenueCat Products** across **Test Store** and **App Store app**
- (new) A **Hosted Paywall** is paired to exactly one **Offering** and renders its **Packages** as purchasable options
- (new) **Restore Purchases** re-syncs store receipts and refreshes **Entitlements** — accessible from both the **Hosted Paywall** and the Settings **Manage Subscription** area
- (new) An **Introductory Offer** is configured per product in App Store Connect; RevenueCat reads it and the **Hosted Paywall** renders it automatically via template variables
- (new) **canAccessPremium** is `true` when subscription status is `trial`, `premiumMonthly`, `premiumAnnual`, or `grace`; **isPremium** excludes `trial`

## Example dialogue

> **Dev:** "When the user taps retry on the error screen, what happens to the **Deferred router**?"
> **Domain expert:** "The **Retry** flips to **InitializingApp** first — that's the **Flip-before-disposal** invariant. The view sees **InitializingApp**, triggers **Router invalidation** to clear the stale `BestRouterConfig`, then schedules **View-driven re-bootstrap** from a post-frame callback."
> **Dev:** "So the 500ms timer starts after the **Flutter splash** repaints?"
> **Domain expert:** "Exactly. That's the **Frame-anchored timing** — the **Minimum splash duration** begins after the splash frame paints, not when `retryInitialization()` is called. On both **Cold start** and **Retry**, the entrance animation gets its full 500ms."
> **Dev:** "What if `initDataSource()` already succeeded on the first attempt?"
> **Domain expert:** "The **Idempotent init guard** handles that — second call is a no-op after success. If the first attempt failed, the guard resets so **Retry** genuinely re-attempts Supabase initialization."

> (new) **Dev:** "Should trial users see **Manage Subscription** in Settings?"
> **Domain expert:** "Yes — **Manage Subscription** is visible when **canAccessPremium** is true, which includes trial users. A trial user might want to cancel before being charged. Don't gate it on **isPremium** — that excludes trials."
> **Dev:** "And **Restore Purchases** — is that only on the **Hosted Paywall**?"
> **Domain expert:** "Both. Apple requires it accessible from outside the paywall too. We add a Settings tile visible to ALL users — even free users who might have lost their **Entitlement** after a reinstall. The tile calls `RevenueCatService.restorePurchases()`, not `Purchases.syncPurchases()` — restore is user-initiated only."
> **Dev:** "What about the 7-day trial? The **Hosted Paywall** says 'free trial' but the **RevenueCat Products** show `trial_duration: null`."
> **Domain expert:** "That's a configuration gap. For **Test Store**, set trial duration directly in RevenueCat. For the **App Store app**, create an **Introductory Offer** in App Store Connect — RevenueCat reads it from there. The **Hosted Paywall** uses template variables like `{{ product.offer_period_with_unit }}` so it auto-renders the trial terms once configured."

## Flagged ambiguities

- **"splash screen"** was used throughout the conversation to mean both the **Native launch surface** (OS-rendered) and the **Flutter splash** (Dart widget). These are distinct: the native surface covers engine startup, the Flutter splash covers **Bootstrap**. Always qualify which one.
- **"restart"** was used interchangeably with **Retry**. In this codebase, `restartApp()` in `AppLifecycleService` delegates to `retryInitialization()` in `StartupViewModel`. Use **Retry** for the user-facing concept and `restartApp()`/`retryInitialization()` for the code path.
- **"delay"** was used to describe the **Minimum splash duration**, but it is not an artificial delay — it is a floor that only adds wait time when **Bootstrap** is faster than 500ms. Prefer "minimum duration" over "delay."
- **"pre-runApp work"** (from the previous glossary) is now obsolete — after the refactor, there is no async work before `runApp()`. The term is replaced by **Bootstrap**, which runs after `runApp()` inside `initializeApp()`.
- (new) **"Cancel Subscription"** was the UI label in Settings, but the action opens subscription management (not just cancellation). Resolved: renamed to **Manage Subscription**. The old label persists in specs and code (`onCancelSubscriptionTap`) until fn-81 is complete — do not use "Cancel Subscription" in new code.
- (new) **"isPremium"** vs **"canAccessPremium"** — `isPremium` is `false` for trial users; `canAccessPremium` is `true` for trial, premium, and grace. Use **canAccessPremium** when gating features that trial users should access (e.g., **Manage Subscription** tile). Use **isPremium** only when you need to distinguish paid subscribers from trial users.
- (new) **"Product"** is overloaded: **RevenueCat Product** (a purchasable item in RC), App Store Connect product (an IAP in Apple's system), and "the product" (the Neurostack app). Always qualify with the system name.
- (new) **"Trial"** has two meanings: **Premium Trial** (the 7-day access period the user experiences) vs **Introductory Offer** (Apple's configuration mechanism in App Store Connect). Use **Premium Trial** for the user-facing concept and **Introductory Offer** for the store configuration.
