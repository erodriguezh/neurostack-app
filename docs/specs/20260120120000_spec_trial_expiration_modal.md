# Spec: Trial Expiration Modal

**Created:** 2026-01-20
**Status:** Draft
**References:**
- UI Design: `docs/best_practices/design/screen-prompts/07-trial-expiration-modal.md`
- Functional Spec: `docs/best_practices/design/screen-functional-specifications.md` (Section 9)
- Figma: `docs/design_screenshots/trial-expiration-modal.png`

---

## Overview

A blocking modal that appears when a user's 7-day premium trial has expired. Forces the user to either subscribe to premium or accept the free tier (with 2 protocol limit).

---

## Trigger Conditions

| Condition | Source |
|-----------|--------|
| `user.subscriptionStatus == SubscriptionStatus.expired` | `lib/home/home_view_model.dart:408-419` |
| Called during `_loadHome()` after user fetch | `lib/home/home_view_model.dart:282` |
| Once per app session (`_hasShownExpiredModal` flag) | `lib/home/home_view_model.dart:67` |

---

## User Flows

### Flow 1: User Subscribes (Keep Everything)
```
Trial Expired Modal → Tap "Keep Everything" → /paywall route → Subscribe → Premium status → Dismiss
                                                            → Dismiss paywall → Back to Trial Expired Modal
```

### Flow 2: User Accepts Free Tier (≤2 protocols)
```
Trial Expired Modal → Tap "Continue with Free" → Update status to `free` → Persist → Dismiss → Home
```

### Flow 3: User Accepts Free Tier (>2 protocols)
```
Trial Expired Modal → Tap "Continue with Free" → Deactivation Modal (placeholder) → Pick 2 → Update status → Dismiss → Home
```

---

## Invariants

| ID | Rule | Enforcement |
|----|------|-------------|
| **INV-M4** | Trial expired modal auto-triggers Day 8+ | `_maybeTriggerExpiredModal()` checks `subscriptionStatus == expired` |
| **INV-U1** | Free tier limited to 2 protocols | Status transition to `free` enforces limit |
| **INV-B5** | "Continue with Free" always available | Modal always shows both options |

---

## UI Specification

### Layout (from `07-trial-expiration-modal.md`)

- **Background:** Full screen, `#030303`, no close button, blocking
- **Top glow:** Subtle radial glow (amber/10) at top
- **Padding:** `px-6`, centered vertically

### Components

#### 1. Hourglass Icon
- Size: 72px
- Stroke: Amber-400, stroke-width 1.5
- Glow: `0 0 25px rgba(251,191,36,0.2)`

#### 2. Message (text-center, mt-8)
- **Headline:** "Your Premium Trial Has Ended"
  - Font: Newsreader italic, 28px (`context.textStyles.h2`)
  - Color: `white/90`
  - Letter-spacing: `-0.025em`
- **Subtext (conditional, if >2 protocols, mt-4):**
  - "You currently have X active protocols. The free tier allows 2."
  - Font: Inter, 15px, font-weight 300
  - Color: `white/50`
  - Max-width: 280px

#### 3. Decision Cards (mt-12, space-y-4)

**Upgrade Option (featured):**
- Container: `bg-white/[0.02]`, `rounded-[24px]`, `p-6`
- Border: `1px solid brand-sky/30` with subtle glow
- Use `SpotlightCard` for hover effect
- Contents:
  - Icon: Crown, 28px, Brand Sky with glow
  - Title: "Keep Everything" - Inter 18px, font-weight 500, `white/90`
  - Subtitle: "Subscribe to Premium" - Inter 14px, font-weight 300, `brand-sky`
  - Arrow indicator: `→` in `white/30`
- Tap → Navigate to `/paywall`

**Downgrade Option:**
- Container: `bg-white/[0.02]`, `rounded-[24px]`, `p-6`
- Border: `1px solid white/10`
- Contents:
  - Icon: Layers with minus, 28px, `white/40`
  - Title: "Continue with Free" - Inter 18px, font-weight 500, `white/70`
  - Subtitle: "Limited to 2 protocols" - Inter 14px, font-weight 300, `white/40`
- Tap → If ≤2 protocols: transition to free, dismiss. If >2: show deactivation modal.

### Blocking Behavior
- `barrierDismissible: false`
- `isDismissible: false` (no drag)
- No X button
- No tap-outside dismiss

---

## State Management

### HomeViewState (existing)
```dart
// lib/home/home_state.dart
bool showTrialExpiredModal  // Triggers modal display
```

### HomeViewModel Methods (existing)
```dart
// lib/home/home_view_model.dart
_maybeTriggerExpiredModal()      // Line 408 - Sets showTrialExpiredModal
acknowledgeTrialExpiredModal()   // Line 205 - Clears flag
goToPaywall()                    // Line 221 - Navigates to /paywall
handleUseFreeTier()              // Line 195 - Handles free tier transition
```

---

## Domain Actions

### Free Tier Transition (≤2 protocols)
```dart
// Pattern from lib/features/library/presentation/library_view_model.dart:172-185
final updatedUser = user.updateSubscriptionStatus(SubscriptionStatus.free);
await _userRepository.save(updatedUser);
await _cachedUserStore?.saveUser(updatedUser);
```

### Free Tier Transition (>2 protocols)
```dart
// Deferred to Deactivation Modal (placeholder exists)
// lib/home/home_view.dart:378-399
```

---

## Existing Implementation (to replace)

**Current:** Basic `AlertDialog` at `lib/home/home_view.dart:319-353`
- Uses generic AlertDialog styling
- No custom typography/spacing
- No visual icon/illustration
- Basic TextButton actions

**Target:** Custom styled modal widget matching Figma design

---

## Dependencies

| Component | Location | Purpose |
|-----------|----------|---------|
| `SpotlightCard` | `lib/core/ui/widgets/spotlight_card.dart` | Hover glow effect on featured card |
| `GridPattern` | `lib/core/ui/widgets/app_grid_background.dart` | Optional grid texture on cards |
| `CustomTextStyles.h2` | `lib/core/ui/constants/text_styles.dart` | Newsreader 28px italic headline |
| `KitColors` | `lib/core/ui/app_theme.dart` | Brand colors (brandSky, white/XX) |

---

## Test Cases

### Unit Tests (ViewModel)
- `handleUseFreeTier()` with ≤2 protocols → status changes to `free`
- `handleUseFreeTier()` with >2 protocols → triggers deactivation modal
- `goToPaywall()` → navigates to `/paywall`

### Widget Tests
- Modal renders with correct headline text
- Conditional subtext shows when `activeProtocolCount > 2`
- "Keep Everything" card tap → calls `goToPaywall()`
- "Continue with Free" card tap → calls `handleUseFreeTier()`
- Modal is not dismissible (no tap outside, no drag)

---

## Out of Scope

- Paywall implementation (route stub exists)
- Deactivation Modal implementation (placeholder exists)
- Actual subscription purchase flow
