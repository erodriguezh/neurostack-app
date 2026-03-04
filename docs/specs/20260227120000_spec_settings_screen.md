# Spec: Settings Screen

## Purpose

Settings screen providing support/contact links, subscription management, and an upgrade CTA. Accessible as the 4th bottom navigation tab.

---

## Screen States

| State | Condition | User Experience |
|-------|-----------|-----------------|
| Free / Trial / Expired | `!subscriptionStatus.isPremium` | Upgrade banner visible, Cancel Subscription hidden |
| Premium | `subscriptionStatus.isPremium` | Upgrade banner hidden, Cancel Subscription visible |

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
- Trailing: chevron-right 16px `white20` (or external-link for external actions)
- Divider between tiles: 1px `white5`, mx-5

### 4. Tile Definitions

| # | Label | Icon | Trailing | Action | Visibility |
|---|-------|------|----------|--------|------------|
| 1 | Contact Us | `LucideIcons.mail` | Chevron | Navigate to `/settings/contact` | Always |
| 2 | Cancel Subscription | `LucideIcons.creditCard` | External-link | Opens platform subscription mgmt | Premium only |

> **Note:** Send Feedback, Rate the App, and Feature Request tiles were originally specified but removed during post-implementation cleanup (fn-74). They can be re-added when Wiredash integration and App Store rating are implemented.

**Cancel Subscription visibility:** Inverse of upgrade banner — only shown when `subscriptionStatus.isPremium`.

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
  - Cancel Subscription tile visibility
- `RevenueCatService.entitlementSnapshot` for current entitlement state
- `CachedUserStore` or `User` aggregate for user data

### Source references
- Subscription status enum: `lib/features/user/domain/enums/subscription_status.dart`
- `isPremium` getter: returns `true` for `premiumMonthly`, `premiumAnnual`, `grace`
- SubscriptionStatusResolver: registered in `lib/config/locator_config.dart` (line ~121)
- RevenueCatService: registered in `lib/config/locator_config.dart` (line ~65)

---

## Dependencies

- `url_launcher` package — needed for Cancel Subscription (opens `https://apps.apple.com/account/subscriptions` on iOS)
- `lucide_icons_flutter` — already in `pubspec.yaml`

---

## UI Specification

See: [`docs/best_practices/design/screen-prompts/11-settings-screen.md`](../best_practices/design/screen-prompts/11-settings-screen.md)
Screenshot (if present): [`docs/design_screenshots/11-settings.png`](../design_screenshots/11-settings.png)

---

## Out of Scope

- Restore Purchases tile (not included)
- Wiredash integration (Send Feedback / Feature Request tiles removed; re-add when integration is ready)
- App Store rating integration (Rate the App tile removed; re-add when integration is ready)
- Sign out / account deletion
- App version display
