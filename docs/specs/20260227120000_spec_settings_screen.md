# Spec: Settings Screen

## Purpose

Settings screen providing support/contact links, subscription management, and an upgrade CTA. Accessible as the 4th bottom navigation tab.

---

## Screen States

| State | Condition | Upgrade Banner | Manage Subscription |
|-------|-----------|----------------|---------------------|
| Free / Expired | `!canAccessPremium` | Visible | Hidden |
| Trial | `canAccessPremium && !isPremium` | Visible | Visible |
| Premium / Grace | `isPremium` | Hidden | Visible |

Restore Purchases is always visible on native platforms and hidden on web (`kIsWeb`).

This screen has no loading, error, or empty states — all content is static/local.

---

## Navigation

- **Entry point:** 4th bottom tab ("Settings", `LucideIcons.settings`, Brand Sky active)
- **Route:** `/settings` (already registered, `requiresAuth: true`)
- **Previous entry point removed:** Gear icon on Progress screen header is removed
- **Bottom nav tabs (4 total):** Stack, Library, Progress, Settings

### Source references
- Bottom tab enum: `lib/core/models/home_bottom_tab.dart`
- Bottom nav widget: `lib/home/widgets/home_bottom_nav.dart`
- Tab coordinator: `lib/home/home_bottom_tab_coordinator.dart`
- Route config: `lib/config/route_config.dart` (line ~35, already has `/settings`)
- Progress gear icon to remove: `lib/progress/progress_view.dart` (lines 219-229)

---

## Required Content

### 1. Screen Header

- Title: **"Settings"** (Newsreader italic, 32px, `white90`, letterSpacing: -0.025em)
- No back button (tab screen, not pushed)
- Padding: `px-6, pt-6`

### 2. Upgrade Banner (Conditional)

**Visibility:** Hidden when `subscriptionStatus.isPremium` (`premiumMonthly`, `premiumAnnual`, `grace`)

| Element | Detail |
|---------|--------|
| Container | `bg-white/[0.02]`, rounded-24, p-6, border 1px `brandSky/30` |
| Icon | Crown/gem, 32px, stroke `brandSky`, glow `rgba(56,189,248,0.25)` |
| Headline | "Unlock All Protocols" — Inter, 17px, w500, `white90` |
| Subtitle | "Unlimited protocols, all future updates" — Inter, 13px, w300, `white50` |
| Trailing | Chevron-right, 18px, `white30` |
| Tap | Navigate to `/paywall` via `routerService.goTo(Path(name: '/paywall'))` |
| Touch target | Full card, minimum 72px height |

### 3. Support & Resources Section

**Section header:**
- "SUPPORT & RESOURCES" — Inter mono, 11px, w500, uppercase, tracking 0.15em, `white40`, mb-4
- Padding: `px-6, mt-10`

**Tile container:**
- `bg-white/[0.02]`, rounded-24, overflow hidden, border 1px `white10`

**Tile pattern (each):**
- Padding: `px-5, py-4`
- Layout: row, center-aligned, gap-4
- Touch target: full width, min 56px height
- Hover/press: `bg-white/[0.03]`, transition 200ms
- Icon (left): 20px, stroke-width 1.5, `white40`
- Label: Inter, 15px, w400, `white80`, flex-1
- Trailing (optional): chevron-right 16px `white20` for navigation, external-link for external actions. Omitted for in-app actions
- Divider between tiles: 1px `white5`, mx-5

### 4. Tile Definitions

| # | Label | Icon | Trailing | Action | Visibility |
|---|-------|------|----------|--------|------------|
| 1 | Contact Us | `LucideIcons.mail` | Chevron | Navigate to `/settings/contact` | Always |
| 2 | Send Feedback | `LucideIcons.messageSquare` | Chevron | Opens mailto link via `url_launcher` (see §Send Feedback below) | Always |
| 3 | Rate the App | `LucideIcons.star` | Chevron | Navigate to `/settings/rate-app` via `RouterService` | Always |
| 4 | Feature Request | `LucideIcons.lightbulb` | Chevron | Opens UserOrient board | Always |
| 5 | Restore Purchases | `LucideIcons.rotateCcw` | None (in-app action) | Calls `RevenueCatService.restorePurchases()` with toast feedback | Always (native only, hidden on web) |
| 6 | Manage Subscription | `LucideIcons.creditCard` | External-link | Opens platform subscription mgmt | `canAccessPremium` only (trial + premium) |

> **Note:** The settings section defines 6 tiles total. Contact Us, Send Feedback, Rate the App, and Feature Request are always shown. Restore Purchases is always visible on native platforms (hidden on web) per Apple App Store requirement. Manage Subscription is shown when `canAccessPremium` (includes trial and premium users). Feature Request is functional via UserOrient. Rate the App navigates to `/settings/rate-app` (in-app review integration). Send Feedback opens a pre-filled mailto link via `url_launcher`.

### Send Feedback (mailto)

Tapping "Send Feedback" opens the device's default email client with a pre-filled message.

| Field | Value |
|-------|-------|
| To | `feedback@getneurostack.app` |
| Subject | `NeuroStack Feedback` |
| Body | App version (`PackageInfo.version`+`buildNumber`), platform (`defaultTargetPlatform.name`), subscription tier (`SubscriptionStatus.name`) |

**Example body:**
```
App Version: 1.0.0+1
Platform: iOS
Subscription: premiumAnnual
```

**Behavior:**
- Composes a `mailto:` URI with `Uri.encodeComponent` query parameters (`subject`, `body`)
- Launches via `launchUrl` with `LaunchMode.externalApplication` (native) / `LaunchMode.platformDefault` (web)
- No in-app fallback if no email client is configured — fire-and-forget, consistent with `openSubscriptionManagement()` pattern
- App version provided by `package_info_plus` via `PackageInfo.fromPlatform()`

**Data sources:**
- App version: `PackageInfo` from `package_info_plus` (registered as singleton in locator)
- Platform: `defaultTargetPlatform` (Flutter foundation)
- Subscription tier: resolved via `SubscriptionStatusResolver.resolveEffectiveStatus()` — same pattern as `openFeatureRequestBoard()`

**Manage Subscription visibility:** Shown when `canAccessPremium` (includes `trial`, `premiumMonthly`, `premiumAnnual`, `grace`).

**Restore Purchases:** Always visible on native platforms (iOS/Android/macOS), hidden on web. Shows toast feedback: success ("Purchases restored successfully"), no purchases found ("No previous purchases found"), or failure ("Unable to restore purchases. Please try again.").

### 5. Contact Us Page (Placeholder)

- **Route:** `/settings/contact` (`requiresAuth: true`)
- **Content:** Empty scaffold with "Contact Us" title header and back navigation
- **Pattern:** `AppGridBackground` > `Scaffold` > `SafeArea` > header with back chevron + title
- **No bottom nav** (pushed route, not a tab)

---

## Animations

| Element | Animation |
|---------|-----------|
| Content fade-in | 400ms ease-out, translateY(8→0) |
| Stagger | Banner first, tile container 100ms later |
| Tile press | `scale(0.99)` on active, 150ms |

---

## Data Requirements

- `SubscriptionStatus` from `SubscriptionStatusResolver.resolveEffectiveStatus()` to determine:
  - Upgrade banner visibility
  - Manage Subscription tile visibility (`canAccessPremium`)
- `RevenueCatService.entitlementSnapshot` for current entitlement state
- `CachedUserStore` or `User` aggregate for user data

### Source references
- Subscription status enum: `lib/features/user/domain/enums/subscription_status.dart`
- `isPremium` getter: returns `true` for `premiumMonthly`, `premiumAnnual`, `grace`
- SubscriptionStatusResolver: registered in `lib/config/locator_config.dart` (line ~121)
- RevenueCatService: registered in `lib/config/locator_config.dart` (line ~65)

---

## Dependencies

- `url_launcher` package — Manage Subscription + Send Feedback mailto (already in `pubspec.yaml`)
- `package_info_plus` — runtime app version for Send Feedback email body
- `lucide_icons_flutter` — already in `pubspec.yaml`
- `userorient_flutter: ^2.1.0` — Feature Request board integration
- `in_app_review` — Rate the App tile navigates to Rate App screen (see [Rate App spec](./202603162012_spec_rate_app_integration.md))

---

## UI Specification

See: [`docs/best_practices/design/screen-prompts/11-settings-screen.md`](../best_practices/design/screen-prompts/11-settings-screen.md)
Screenshot (if present): [`docs/design_screenshots/11-settings.png`](../design_screenshots/11-settings.png)

---

## Out of Scope

- ~~Restore Purchases tile (not included)~~ -- Added in fn-81-paywall-apple-compliance
- ~~Wiredash integration~~ -- replaced by mailto via `url_launcher` (decision 2026-03-20)
- In-app fallback for missing email client (fire-and-forget for now)
- Sign out / account deletion
- App version display in Settings UI (version is only included in feedback email body)
