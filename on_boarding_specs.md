# Onboarding Specs

> **Last Updated:** 2026-01-02
> **Status:** Ready for Implementation

---

## Table of Contents

1. [Overview](#1-overview)
2. [User Flow Logic](#2-user-flow-logic)
3. [Architecture Decisions](#3-architecture-decisions)
4. [Screen Specifications](#4-screen-specifications)
5. [Shared Components](#5-shared-components)
6. [Animation Specifications](#6-animation-specifications)
7. [Design System Integration](#7-design-system-integration)
8. [Dependencies](#8-dependencies)
9. [File Structure](#9-file-structure)
10. [Implementation Checklist](#10-implementation-checklist)

---

## 1. Overview

### 1.1 Purpose

The onboarding flow is the first experience for new users and the primary funnel for premium subscriptions. It uses an emotional journey framework to connect with users before presenting the trial offer.

### 1.2 Framework

**PAS (Problem → Agitation → Solution) into AIDA (Attention → Interest → Desire → Action)**

| Screen | PAS Stage | AIDA Stage | Emotional Goal |
|--------|-----------|------------|----------------|
| 1 | Problem | Attention | Call out the pain - "you know what to do but aren't doing it" |
| 2 | Agitation | Interest | Agitate + introduce the transformation gap |
| 3 | Solution | Desire + Action | Present solution + trial offer |
| 4 | Trust | Action | Disclaimer - build trust before commitment |

### 1.3 Key Metrics to Track

- Screen completion rates (1→2, 2→3, 3→4, 4→auth)
- Time spent per screen
- "Sign in instead" click rate
- Trial start conversion rate

---

## 2. User Flow Logic

### 2.1 Entry Points

```
App Launch Decision Tree:
├── First launch ever? (has_completed_onboarding == false)
│   └── → /onboarding
├── Not authenticated? (has_completed_onboarding == true)
│   └── → /auth
└── Authenticated?
    └── → requested route (default: /home)
```

### 2.2 Onboarding Flag Storage

- **Storage:** `SharedPreferences`
- **Keys:**
  - `has_completed_onboarding` (`bool`) - set when user completes onboarding
  - `has_ever_launched` (`bool`) - durable marker that survives logout/cache clears
  - `onboarding_migration_version` (`int`) - version-based migration marker
- **Set When:** User taps "Let's go" on Screen 4 (before navigation to auth)
- **Location:** Modify `StartupViewModel.initializeApp()` at lines 67-69

#### Migration for Existing Users

Existing users who had the app before onboarding was added should skip onboarding:

- **Detection:** Check `has_ever_launched` OR legacy app-owned keys (`cached_user`, `auth_email`)
- **Behavior:** If durable marker or legacy data exists, auto-mark onboarding as completed
- **Version-based:** Migration runs once per `onboarding_migration_version` bump
- **Deployment:** Release a pre-onboarding version to seed `has_ever_launched` for logged-out users
- **New installs:** Users without markers/legacy data see full onboarding flow

### 2.3 Navigation Flow

```
Screen 1 → "That's me" → Screen 2
Screen 2 → "Too familiar" → Screen 3
Screen 3 → "Start my free trial" → Screen 4
Screen 3 → "Sign in instead" → Screen 4 (same flow, no functional difference)
Screen 4 → "Let's go" (with checkbox) → Set flag → auth init → route based on state:
  - Authenticated: / (home, via AuthService post-auth navigation)
  - Unauthenticated: /auth
  - Offline: show offline state
```

### 2.4 Sign Out Behavior

- Sign out always returns to Screen 1 (full emotional journey)
- The `has_completed_onboarding` flag remains true (prevents re-showing on sign-in)

### 2.5 Back Navigation

- Standard back navigation between screens (Screen 2 → Screen 1, etc.)
- Android back button/gesture works normally
- No exit confirmation dialogs

### 2.6 State Persistence

- **On app kill mid-flow:** Always restart from Screen 1
- **Rationale:** The emotional arc matters more than user convenience

---

## 3. Architecture Decisions

### 3.1 State Management

| Decision | Choice | Rationale |
|----------|--------|-----------|
| ViewModel per screen | No | Using `EnumPageView` pattern |
| Overall state | `OnboardingViewModel` | Follows codebase MVVM pattern, handles navigation and completion |
| Page navigation | `EnumPageView<OnboardingStep>` | Reusable pattern for multi-screen flows |

### 3.2 OnboardingStep Enum

**Location:** `onboarding_view_model.dart` (colocated with ViewModel)

```dart
enum OnboardingStep {
  hook,      // Screen 1
  agitate,   // Screen 2
  offer,     // Screen 3
  disclaimer // Screen 4
}
```

### 3.3 Routing

| Aspect | Decision |
|--------|----------|
| Route path | `/onboarding` (single route) |
| Sub-routes | None - single entry point |
| Route file | Add to `lib/config/route_config.dart` |
| requiresAuth | `false` |

### 3.4 Scaffold Pattern

Use global `OnboardingScaffold` widget (similar to `AuthBackground`):
- Shared background (grid texture)
- Shared bottom section (progress dots)
- Per-screen glow configuration

---

## 4. Screen Specifications

### 4.1 Screen 1: Hook ("You've read the studies")

#### Layout

```
[SafeArea]
├── [px-6, vertically centered with slight top bias]
│   ├── Headline: "You've read the studies."
│   │   └── Newsreader italic, 32px, white/90, letter-spacing: -0.025em
│   │
│   ├── [mt-6] Body lines (staggered reveal):
│   │   ├── "You know cold plunges work."
│   │   ├── "You know zone 2 cardio extends lifespan."
│   │   └── "You know what you should be doing."
│   │       └── "should" in italic, white/80
│   │   └── Inter, 18px, font-weight: 300, white/60, line-height: 1.6
│   │
│   └── [mt-12] Kicker: "So why aren't you doing it?"
│       └── Newsreader italic, 24px, brandSky (#38BDF8)
│       └── Glow: 0 0 30px rgba(56,189,248,0.2)
│
└── [fixed, pb-10, px-6] Bottom:
    ├── Progress dots: ● ○ ○ ○
    └── CTA: Ghost button "That's me →"
```

#### Copy (Final - Hardcoded)

```
Headline: "You've read the studies."
Line 1: "You know cold plunges work."
Line 2: "You know zone 2 cardio extends lifespan."
Line 3: "You know what you *should* be doing."
Kicker: "So why aren't you doing it?"
CTA: "That's me"
```

#### Animation Timing

| Element | Delay | Duration | Effect |
|---------|-------|----------|--------|
| Headline | 0ms | 500ms | fadeIn + translateY(10px → 0) |
| Line 1 | 400ms | 500ms | fadeIn + translateY(10px → 0) |
| Line 2 | 700ms | 500ms | fadeIn + translateY(10px → 0) |
| Line 3 | 1000ms | 500ms | fadeIn + translateY(10px → 0) |
| Kicker | 1500ms | 500ms | fadeIn + scale(0.95 → 1) |
| **Total** | ~2000ms | | |

#### Skip Behavior

- Tap anywhere to instantly reveal all text
- CTA becomes active immediately

---

### 4.2 Screen 2: Agitate ("The gap between knowing and doing")

#### Layout

```
[SafeArea]
├── [px-6]
│   ├── [mt-16] Headline:
│   │   ├── "The gap between knowing and doing"
│   │   │   └── Newsreader italic, 26px, white/90, letter-spacing: -0.025em
│   │   └── "is where results go to die."
│   │       └── "go to die" in warning color (#FBBF24) with subtle glow
│   │
│   ├── [mt-10] Body paragraphs:
│   │   ├── "You start strong."
│   │   ├── "Week one, you're locked in." ("locked in" → white/80)
│   │   ├── [mt-4] "Week two, life gets busy."
│   │   ├── [mt-4] "Week three, you forgot which day you're supposed to do what."
│   │   ├── [mt-4] "By month two, that protocol you were excited about?"
│   │   └── "Just another abandoned experiment." (white/40, italic)
│   │   └── Inter, 16px, font-weight: 300, white/60, line-height: 1.8
│   │
│   └── [mt-10] Hook: "Sound familiar?"
│       └── Inter, 18px, font-weight: 500, white/80
│
└── [fixed, pb-10, px-6] Bottom:
    ├── Progress dots: ● ● ○ ○
    └── CTA: Ghost button "Too familiar →"
        └── border-white/20 (slightly more emphasis)
```

#### Copy (Final - Hardcoded)

```
Headline 1: "The gap between knowing and doing"
Headline 2: "is where results go to die."
Para 1: "You start strong."
Para 2: "Week one, you're locked in."
Para 3: "Week two, life gets busy."
Para 4: "Week three, you forgot which day you're supposed to do what."
Para 5: "By month two, that protocol you were excited about?"
Para 6: "Just another abandoned experiment."
Hook: "Sound familiar?"
CTA: "Too familiar"
```

#### Animation

- Body paragraphs fade in with 200ms stagger (creates reading rhythm)
- "Sound familiar?" fades in last with slight delay

---

### 4.3 Screen 3: Offer ("What if you just... did the thing?")

#### Layout

```
[SafeArea]
├── [px-6]
│   ├── [mt-12, text-center] Headline:
│   │   ├── "What if you just..."
│   │   │   └── Newsreader italic, 28px, white/70
│   │   └── "did the thing?"
│   │       └── Newsreader italic, 32px, white/90
│   │       └── Subtle brandSky underline or glow
│   │
│   ├── [mt-4, text-center] Subhead:
│   │   └── "NeuroStack is the simplest way to stick with science-backed protocols."
│   │       └── Inter, 15px, font-weight: 300, white/50, max-width: 300px
│   │
│   ├── [mt-10] Value props card:
│   │   └── Container: bg-white/[0.02], rounded-[24px], p-6
│   │   └── Border: gradient top border (brandSky/20 → white/10 → white/5)
│   │   └── Spotlight effect
│   │   └── Three lines (space-y-4):
│   │       ├── Eye icon "See exactly what to do today"
│   │       ├── Flame icon "Build streaks that feel good to maintain"
│   │       └── Sparkles icon "Actually become the person who does this stuff"
│   │       └── Icons: Lucide, brandSky, 18px
│   │       └── Text: Inter, 15px, font-weight: 400, white/70
│   │
│   └── [mt-8, text-center] Trial offer:
│       └── Container: bg-brandSky/5, rounded-2xl, p-5, border brandSky/20
│       ├── "7 days free" → Inter, 20px, font-weight: 500, brandSky
│       └── "No credit card required" → Inter, 13px, white/50
│
└── [fixed, pb-8, px-6] Bottom:
    ├── Progress dots: ● ● ● ○
    ├── [mt-4] Primary CTA:
    │   └── Full width, h-14, rounded-full
    │   └── bg-brandSky (#38BDF8), text-background (#030303)
    │   └── "Start my free trial →"
    │   └── Glow: 0 0 25px rgba(56,189,248,0.35)
    │   └── Haptic: HapticFeedback.lightImpact()
    └── [mt-3] Secondary link:
        └── "Sign in instead" → Inter, 13px, white/30
        └── Tappable, navigates to Screen 4
```

#### Icons (Lucide)

| Semantic | Lucide Icon |
|----------|-------------|
| Clarity | `eye` |
| Motivation | `flame` |
| Transformation | `sparkles` |

#### Background

- Radial glow at top: `brandSky/10` (only screen with this glow)

#### Animation

- Headline has slight bounce ease on "did the thing"
- Value props stagger in 150ms each
- Trial offer card pulses glow once after props load

---

### 4.4 Screen 4: Disclaimer ("One more thing")

#### Layout

```
[SafeArea]
├── [px-6]
│   ├── [mt-16, text-center] Header:
│   │   ├── "One more thing."
│   │   │   └── Newsreader italic, 28px, white/90, letter-spacing: -0.025em
│   │   └── "We take your health seriously. So should you."
│   │       └── Inter, 15px, font-weight: 300, white/50
│   │
│   ├── [mt-10] Disclaimer card:
│   │   └── Container: bg-white/[0.02], rounded-[24px], p-6
│   │   └── Border: 1px solid white/10
│   │   └── Left accent: 3px solid warning/50
│   │   ├── Icon: Shield or heart-plus, 24px, warning/70
│   │   └── [mt-4] Text:
│   │       "NeuroStack helps you track protocols based on published research—
│   │        but we're not doctors, and this isn't medical advice. Before
│   │        starting any new protocol, check with your healthcare provider."
│   │       └── "we're not doctors" and "this isn't medical advice" → white/70
│   │       └── Inter, 14px, font-weight: 300, line-height: 1.7, white/60
│   │
│   └── [mt-8] Consent checkbox:
│       └── Row with 52px touch target:
│           ├── Checkbox: 24px, rounded-lg, custom styling
│           └── Label: "I understand" → Inter, 15px, white/70
│
└── [fixed, pb-10, px-6] Bottom:
    ├── Progress dots: ● ● ● ●
    └── Primary CTA:
        ├── Disabled: bg-white/5, text-white/30
        ├── Enabled: bg-brandSky, text-background, glow
        └── "Let's go →"
        └── Haptic: HapticFeedback.lightImpact() (when enabled)
```

#### Checkbox Component

Create a reusable custom checkbox widget if Flutter's default is insufficient:
- Location: `lib/features/onboarding/presentation/widgets/onboarding_checkbox.dart`
- Features: rounded corners, brand colors, satisfying scale animation on check

#### Consent Storage

- **Not stored** - UX friction only, no compliance logging needed

#### Animation

- Content fades in together (no stagger - functional, not dramatic)
- Checkbox has satisfying scale + color transition on check
- "Let's go" button transforms with 300ms ease when enabled

#### Success Action

1. Set `has_completed_onboarding = true` in SharedPreferences (also clears force_onboarding flag)
2. Initialize auth: `await authService.init()`
3. Route based on auth state:
   - If authenticated → `/` (home)
   - If not authenticated → `/auth`
4. Navigation is instant (auth init may show brief loading)

---

## 5. Shared Components

### 5.1 OnboardingScaffold

**Location:** `lib/features/onboarding/presentation/widgets/onboarding_scaffold.dart`

```dart
class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final int currentStep; // 0-3
  final bool showTopGlow; // true only for Screen 3

  // Builds:
  // - Background color (#030303)
  // - AppGridBackground (extracted shared widget)
  // - Optional top glow (brandSky/10)
  // - Progress dots (fixed at bottom)
  // - Child content
}
```

### 5.2 Progress Dots

**Location:** `lib/features/onboarding/presentation/widgets/onboarding_progress_dots.dart`

```dart
class OnboardingProgressDots extends StatelessWidget {
  final int total = 4;
  final int current; // 0-indexed

  // Styling:
  // - Dot size: 6px
  // - Gap: 8px (context.spacing.sm)
  // - Filled: white
  // - Empty: white/20
  // - Non-tappable (visual only)
}
```

### 5.3 Ghost Button (Screens 1-2)

```dart
// Styling:
// - Full width, h-14, rounded-full
// - bg-white/5, border border-white/10
// - Text: Inter, 15px, font-weight: 500, white/70
// - Arrow: → with animated translateX on tap
// - Press state: minimal (use default splash)
```

### 5.4 Primary CTA (Screens 3-4)

```dart
// Styling:
// - Full width, h-14, rounded-full
// - Enabled: bg-brandSky, text-background
// - Disabled: bg-white/5, text-white/30
// - Glow when enabled: BoxShadow with brandSky
// - Haptic on tap (HapticFeedback.lightImpact)
```

---

## 6. Animation Specifications

### 6.1 Approach

- **Library:** Flutter built-in implicit widgets (`AnimatedOpacity`, `AnimatedSlide`)
- **Curves:** Use existing `CustomCurves` from design system
- **No external animation dependencies**

### 6.2 Page Transitions

Using `EnumPageView` widget (to be created):
- Direction: Horizontal slide
- Duration: 750ms
- Curve: `CustomCurves.emphasizedDecelerate`

### 6.3 Timing Constants

Use `CustomDurations` from design system:

| Token | Value | Usage |
|-------|-------|-------|
| duration200 | 200ms | Stagger intervals, quick transitions |
| duration300 | 300ms | Button enable/disable |
| duration500 | 500ms | Text fade-ins |
| duration700 | 700ms | Longer staggers |

### 6.4 Glow Effects

Implement with `BoxDecoration.boxShadow`:

```dart
BoxShadow(
  color: kitColors.brandSky.withValues(alpha: 0.3),
  blurRadius: 20,
  spreadRadius: 0,
)
```

---

## 7. Design System Integration

### 7.1 Colors (from `kit_colors.dart`)

| Usage | Token | Value |
|-------|-------|-------|
| Background | `kitColors.background` | #030303 |
| Brand accent | `kitColors.brandSky` | #38BDF8 |
| Warning/Amber | `kitColors.warning` | #FBBF24 |
| Headlines | `kitColors.white90` | white/90 |
| Body text | `kitColors.white60` | white/60 |
| Muted text | `kitColors.white40` | white/40 |
| Disabled | `kitColors.white30` | white/30 |
| Borders | `kitColors.white10` | white/10 |
| Card fills | `kitColors.white02` | white/2 |
| Grid texture | `kitColors.white02` | white/2 |

### 7.2 Typography (from `app_theme.dart`)

| Element | TextTheme Style | Font |
|---------|-----------------|------|
| Headlines (serif) | `headlineLarge` | Newsreader italic, 32px |
| Subheadlines (serif) | `headlineMedium` | Newsreader, 28px |
| Body large | `bodyLarge` | Inter, 16px |
| Body medium | `bodyMedium` | Inter, 14px |
| Labels | `labelLarge` | Inter, 14px |
| Small labels | `labelSmall` | Roboto Mono, 11px |

### 7.3 Spacing (from `spacing.dart`)

| Token | Usage |
|-------|-------|
| `context.spacing.xs` | 4px - fine spacing |
| `context.spacing.sm` | 8px - dot gaps, small gaps |
| `context.spacing.md` | 16px - mt-4 equivalent |
| `context.spacing.lg` | 24px - px-6 equivalent |
| `context.spacing.xl` | 32px - larger sections |
| `context.spacing.xxl` | 48px - hero sections |

### 7.4 Border Radius (from `border_radius.dart`)

| Token | Usage |
|-------|-------|
| `context.borderRadius.full` | Buttons (pill shape) |
| `context.borderRadius.xxl` | Cards (24px) |

---

## 8. Dependencies

### 8.1 Existing (Already Installed)

- `google_fonts` - Newsreader, Inter fonts
- `shared_preferences` - Onboarding flag storage
- `cupertino_icons` - Fallback icons

### 8.2 To Add

```yaml
dependencies:
  lucide_icons_flutter: ^3.1.9   # Value prop icons (eye, flame, sparkles)
```

**Note:** Use Flutter's built-in implicit animations (`AnimatedOpacity`, `AnimatedSlide`) with existing `CustomCurves` and `CustomDurations` instead of external animation packages.

---

## 9. File Structure

```
lib/
├── config/
│   └── route_config.dart              # Add /onboarding route
├── features/
│   └── onboarding/
│       ├── data/
│       │   └── onboarding_store.dart  # SharedPreferences wrapper
│       └── presentation/
│           ├── onboarding_view.dart   # Main view
│           ├── onboarding_view_model.dart  # ViewModel + OnboardingStep enum
│           ├── screens/
│           │   ├── hook_screen.dart       # Screen 1
│           │   ├── agitate_screen.dart    # Screen 2
│           │   ├── offer_screen.dart      # Screen 3
│           │   └── disclaimer_screen.dart # Screen 4
│           └── widgets/
│               ├── onboarding_scaffold.dart
│               ├── onboarding_progress_dots.dart
│               ├── onboarding_ghost_button.dart
│               └── onboarding_checkbox.dart  # Custom checkbox for brand styling
├── core/
│   └── ui/
│       └── widgets/
│           ├── app_grid_background.dart   # Extracted from auth/startup
│           ├── app_primary_cta.dart       # Extracted from auth (shared CTA)
│           └── enum_page_view.dart        # Reusable page navigation
└── startup/
    └── startup_view_model.dart        # Modify to check onboarding flag
```

---

## 10. Implementation Checklist

### Phase 1: Setup

- [ ] Add dependencies to `pubspec.yaml` (lucide_icons_flutter)
- [ ] Run `flutter pub get`
- [ ] Create folder structure under `lib/features/onboarding/`
- [ ] Add `/onboarding` route to `route_config.dart`

### Phase 2: Shared Components

- [ ] Create `OnboardingScaffold` widget
- [ ] Create `OnboardingProgressDots` widget
- [ ] Create `OnboardingGhostButton` widget
- [ ] Use shared `AppPrimaryCta` widget from core (extracted from auth)
- [ ] Create `CustomCheckbox` widget (if Flutter default insufficient)

### Phase 3: Individual Screens

- [ ] Implement `HookScreen` (Screen 1) with animations
- [ ] Implement `AgitateScreen` (Screen 2) with animations
- [ ] Implement `OfferScreen` (Screen 3) with animations
- [ ] Implement `DisclaimerScreen` (Screen 4) with checkbox logic

### Phase 4: Main View & Navigation

- [ ] Create `OnboardingView` with `OnboardingStep` enum
- [ ] Implement `EnumPageView` integration
- [ ] Add skip-animation-on-tap behavior
- [ ] Add back navigation support

### Phase 5: App Integration

- [ ] Create `OnboardingStore` for SharedPreferences flag
- [ ] Modify `StartupViewModel.initializeApp()` to check onboarding flag
- [ ] Test first-launch → onboarding flow
- [ ] Test returning-unauthenticated → auth flow
- [ ] Test sign-out → onboarding flow

### Phase 5b: Seed Release (BEFORE onboarding release)

- [ ] Ship seed release that sets `has_ever_launched` for all existing installs
- [ ] Wait for 95%+ of users to update to seed release
- [ ] Remove seed code from codebase before shipping onboarding release

### Phase 6: Polish

- [ ] Lock orientation to portrait
- [ ] Add haptic feedback to primary CTAs
- [ ] Test animations on device
- [ ] Verify all copy is correct
- [ ] Test edge cases (app kill, back nav, etc.)

---

## Appendix A: Copy Reference

All copy is **final and hardcoded**. If copy needs to change, update this spec first.

### Screen 1

```
"You've read the studies."
"You know cold plunges work."
"You know zone 2 cardio extends lifespan."
"You know what you should be doing."
"So why aren't you doing it?"
[That's me]
```

### Screen 2

```
"The gap between knowing and doing"
"is where results go to die."

"You start strong."
"Week one, you're locked in."
"Week two, life gets busy."
"Week three, you forgot which day you're supposed to do what."
"By month two, that protocol you were excited about?"
"Just another abandoned experiment."

"Sound familiar?"
[Too familiar]
```

### Screen 3

```
"What if you just..."
"did the thing?"

"NeuroStack is the simplest way to stick with science-backed protocols."

- See exactly what to do today
- Build streaks that feel good to maintain
- Actually become the person who does this stuff

"7 days free"
"No credit card required"

[Start my free trial]
[Sign in instead]
```

### Screen 4

```
"One more thing."
"We take your health seriously. So should you."

"NeuroStack helps you track protocols based on published research—but we're not doctors, and this isn't medical advice. Before starting any new protocol, check with your healthcare provider."

[ ] I understand

[Let's go]
```

---

## Appendix B: Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-02 | Always restart onboarding on app kill | Emotional arc > convenience |
| 2026-01-02 | No sub-routes for onboarding screens | Simplicity, single entry point |
| 2026-01-02 | Use SharedPreferences for flag | Already used in codebase |
| 2026-01-02 | Set flag after Screen 4, before auth | Ensures user saw full flow |
| 2026-01-02 | Sign out shows full onboarding | Maintains emotional journey |
| 2026-01-02 | Tap-to-skip animations | Respects user intent |
| 2026-01-02 | Checkbox is UX friction only | No compliance requirement |
| 2026-01-02 | "Sign in instead" for returning users | Clear intent communication |
| 2026-01-02 | Both paths lead to same outcome | Trial logic handled post-auth |
| 2026-01-02 | Portrait lock | Layouts designed for vertical |
| 2026-01-02 | Haptics on primary CTAs only | Minimal, premium feel |
| 2026-01-02 | Lucide icons for value props | Consistency, modern style |
| 2026-01-02 | Use implicit animations | Avoid over-engineering |
| 2026-01-02 | Global scaffold for background | Code reuse, consistency |
| 2026-01-02 | Brand-sky glow only on Screen 3 | Optimistic energy shift |
| 2026-01-02 | Progress dots visual-only | Not tappable, forward momentum |
| 2026-01-02 | Instant navigation to auth | No artificial loading |
| 2026-01-03 | Durable has_ever_launched marker for migration | Survives logout/cache clears; requires pre-onboarding release to seed |

---

## Appendix C: What's NOT In Scope

Per original requirements:
- Subscription/payment process (handled separately after auth)
- A/B testing infrastructure
- Analytics implementation details
- Localization/i18n
