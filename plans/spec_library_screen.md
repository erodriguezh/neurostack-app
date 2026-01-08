# Spec: Library Screen

## Overview

The Library screen displays all available protocols, allowing users to browse, view details, and activate protocols to their stack. It uses a hybrid navigation approach where each tab (Stack, Library, Progress) is a separate route with a shared bottom navigation component.

## Protocol Activation Flow

```
          USER TAPS PROTOCOL CARD
                    |
                    v
         +---------------------+
         | Show detail sheet   |
         | (bottom sheet)      |
         +---------------------+
                    |
    +---------------+---------------+
    |               |               |
    v               v               v
[In Stack]     [Available]      [Locked]
    |               |               |
    v               v               v
Actions:       "Tap to add"    "Upgrade to add"
- Log session  badge tap:      button opens
- View stats   activates       paywall
- Remove       protocol
                    |
                    v
         +---------------------+
         | activateProtocol    |
         +---------------------+
                    |
      +-------------+-------------+
      |                           |
      v                           v
Right(user)               Left(ProtocolLimitReached)
Save -> Refresh                   |
Badge animation                   v
(pop effect)              Paywall Modal
```

## Badge States

| Condition | Icon | Badge Style | Card Tap | Badge Tap |
|-----------|------|-------------|----------|-----------|
| `stack.contains(id)` | Check | bg-brand-sky, white icon, glow | Detail sheet | Detail sheet |
| Can activate | Plus | bg-white/30, white icon | Detail sheet | Activate immediately |
| At limit, not in stack | Lock | bg-white/20, white icon | Detail sheet w/ upgrade CTA | Detail sheet w/ upgrade CTA |

## Invariants

- **INV-U1/M5**: Lock when `free && stack.count >= 2`
- **INV-U2**: No locks during trial - all protocols show as available
- **INV-B2**: Locked tap -> Show detail sheet with "Upgrade to add" CTA -> Paywall
- Premium users see all protocols as available (never locked)

## Navigation Architecture

### Hybrid Tab Navigation
- Each tab is a separate route: `/` (Stack), `/library`, `/progress` (future)
- Bottom nav component shared across screens
- Tab switching navigates between routes
- Back gesture/button exits app (top-level tabs)
- Deep link support for `/library`
- Scroll position preserved per tab within session

### Progress Tab Behavior
- Currently shows toast "Coming soon" on tap
- No route added yet - defer until progress feature is built

## UI Specification

### Wireframe

```
+-----------------------------------------+
| Protocol Library                        |
+-----------------------------------------+
|                                         |
| EXERCISE                                | <- Category header (simple text)
|                                         |
| +-------------------------------------+ |
| | [EXERCISE]                     [v]  | | <- In stack (brand-sky border)
| | Norwegian 4x4 HIIT                  | |
| | Multiple RCTs                       | |
| | In your stack                       | |
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| | [EXERCISE]                     [+]  | | <- Available
| | Zone 2 Cardio                       | |
| | Single RCT                          | |
| | Tap to add                          | |
| +-------------------------------------+ |
|                                         |
| HEAT THERAPY                            |
|                                         |
| +-------------------------------------+ |
| | [HEAT THERAPY]                 [v]  | |
| | Sauna Heat Exposure                 | |
| | Multiple RCTs                       | |
| | In your stack                       | |
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| | [HEAT THERAPY]                 [L]  | | <- Locked (dashed border)
| | Infrared Sauna                      | |
| | Observational                       | |
| | Upgrade to unlock                   | |
| +-------------------------------------+ |
|                                         |
+-----------------------------------------+
|   [*] Stack   [*] Library   [*] Progress |
+-----------------------------------------+
```

### Layout Structure

1. **Header** (px-6, pt-6):
   - Title: "Protocol Library"
   - Font: Newsreader italic, 32px
   - Color: text-white/90
   - Letter-spacing: -0.025em

2. **Protocol List** (px-6, mt-6, space-y-4, pb-28):
   - Grouped by category with simple text headers
   - Within each category: active protocols first, then available, locked at bottom
   - Pull-to-refresh enabled

3. **Category Headers**:
   - Simple left-aligned text
   - Font: Inter, 12px, uppercase
   - Color: text-white/50
   - Margin: mt-6 mb-2 (except first)

4. **Bottom Navigation**:
   - Same component as Stack screen (HomeBottomNav)
   - Library tab active (brand-sky color)
   - Icons: LucideIcons.layers (Stack), LucideIcons.bookOpen (Library), LucideIcons.chartLine (Progress)

### Protocol Card Variants

**A) In Stack (already active)**:
- Container: bg-white/[0.02], rounded-[24px], p-6
- Border: 1px solid brand-sky/30
- Badge: 24px circle, bg-brand-sky, check icon (white, 14px), glow effect
- Status: "In your stack" - text-brand-sky

**B) Available (can add)**:
- Container: bg-white/[0.02], rounded-[24px], p-6
- Border: 1px solid white/10
- Spotlight effect on touch (extract to shared widget in core/ui/widgets)
- Badge: 24px circle, bg-white/30, plus icon (white, 14px)
- Status: "Tap to add" - text-white/40
- Hover/touch: border-white/20

**C) Locked (free tier limit)**:
- Container: bg-white/[0.01], rounded-[24px], p-6
- Border: 1px dashed white/10
- Badge: 24px circle, bg-white/20, lock icon (white, 14px)
- All text at reduced opacity (name: white/50, others: white/30)
- Status: "Upgrade to unlock" - text-amber-400/80

### Card Contents
- Category pill: Match HomeProtocolCard styling (mono, uppercase, 10px)
- Name: Inter, 18px, font-weight: 500, text-white/90
- Evidence: Inter, 12px
- Icon: Use Lucide icons mapped via Category enum extension

### Evidence Level Colors (4 tiers)
- Multiple RCTs: text-emerald-400 (evidenceStrong)
- Single RCT: text-emerald-400 (evidenceStrong)
- Observational: text-brand-sky (evidenceModerate)
- Expert Consensus: text-white/50 (evidenceWeak)

## Detail Bottom Sheet

Triggered by tapping any protocol card. Shows protocol information and contextual actions.

### Sheet Content

1. **Protocol Info Section**:
   - Category icon + name
   - Protocol name (large)
   - Evidence level badge
   - Target/prescription details
   - Research citations (expandable)

2. **Stats Section** (for protocols in stack):
   - Total sessions logged
   - Current streak
   - Last session date
   - Data fetched on demand from SessionRepository

3. **Actions Section** (varies by state):

   **In Stack:**
   - "Log Session" (primary button)
   - "View History" -> shows simple stats inline
   - "Remove from Stack" (secondary style, triggers confirm dialog)

   **Available:**
   - "Add to Stack" (primary button)

   **Locked:**
   - "Upgrade to Add" (primary button -> paywall)
   - Brief explanation of free tier limit

### Remove Confirmation Dialog
- Title: "Remove {Protocol Name}?"
- Body: "This won't delete your session history."
- Buttons: Cancel / Remove
- On confirm: optimistic UI update, badge changes from check to plus/lock

## State Management

### LibraryViewState
```dart
class LibraryViewState {
  final LibraryStatus status; // loading, loaded, error, empty
  final List<LibraryProtocolCardModel> cards;
  final User? user;
  final bool isOffline;
  final String? errorMessage;
  final bool isRefreshing;
}

class LibraryProtocolCardModel {
  final String protocolId;
  final String name;
  final Category category;
  final EvidenceLevel evidenceLevel;
  final String targetDescription;
  final LibraryCardStatus status; // inStack, available, locked
}
```

### ViewModel Dependencies
- UserRepository: check stack contents, subscription status
- ProtocolRepository: list all active protocols
- SessionRepository: fetch stats on demand (lazy, for detail sheet only)
- RouterService: navigation
- NotifyService: toasts
- ConnectivityService: offline detection

## Data Fetching

### Initial Load
1. Fetch user (for stack and subscription status)
2. Fetch all active protocols from repository
3. Compute card status for each protocol
4. Sort: by category, then within category (inStack -> available -> locked)

### Caching
- Cache protocols for session duration
- Refresh on pull-to-refresh
- Show cached data when offline (disable mutations)

### Error Handling
- Network error on activation: silent retry once, then show error toast
- Load failure: show error state with pull-to-refresh prompt

## Offline Behavior
- Show cached protocol list if available
- Show offline banner
- Disable add/remove actions
- Allow viewing protocol details (read-only)

## Animation Specifications

### Badge Activation Animation (Pop Effect)
When user activates a protocol:
1. Badge scales up to 1.2x over 100ms
2. Background transitions from white/30 to brand-sky
3. Icon morphs from plus to check
4. Badge settles to 1.0x over 150ms
5. Glow effect fades in

### Card State Transition
- Border color animates over 200ms
- Background opacity animates over 200ms
- Status text fades in/out over 150ms

## Implementation Notes

### Files to Create/Modify

**New Files:**
- `lib/library/library_state.dart` - State classes
- `lib/library/widgets/library_protocol_card.dart` - Protocol card component
- `lib/library/widgets/library_category_header.dart` - Category headers
- `lib/library/widgets/protocol_detail_sheet.dart` - Bottom sheet
- `lib/core/ui/widgets/spotlight_card.dart` - Shared spotlight effect widget
- `lib/progress/progress_view.dart` - Stub screen (toast on nav tap)
- `lib/progress/progress_view_model.dart` - Minimal VM

**Modify:**
- `lib/library/library_view.dart` - Replace stub with full implementation
- `lib/library/library_view_model.dart` - Add all business logic
- `lib/features/protocol/domain/enums/category.dart` - Add Lucide icon getter
- `lib/home/widgets/home_bottom_nav.dart` - Update Progress icon to Lucide
- `lib/home/home_view_model.dart` - Update onSelectBottomTab to navigate
- `lib/config/route_config.dart` - Verify /library route exists

### Category Icon Mapping (extend enum)
```dart
enum Category {
  exercise('Exercise', LucideIcons.dumbbell),
  heatTherapy('Heat Therapy', LucideIcons.flame),
  coldExposure('Cold Exposure', LucideIcons.snowflake),
  nutrition('Nutrition', LucideIcons.utensils),
  supplements('Supplements', LucideIcons.pill),
  mind('Mind', LucideIcons.brain),
  sleep('Sleep', LucideIcons.moon);

  const Category(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}
```

### Shared Spotlight Widget
Extract from HomeProtocolCard to `lib/core/ui/widgets/spotlight_card.dart`:
- Radial gradient following touch/cursor
- Configurable border radius, colors
- Reuse in both HomeProtocolCard and LibraryProtocolCard

## Acceptance Criteria

### Core Functionality
- [ ] User can view all available protocols grouped by category
- [ ] Protocols sorted: by category, then inStack -> available -> locked
- [ ] User can tap card to see protocol details in bottom sheet
- [ ] User can tap badge to activate available protocol
- [ ] Badge shows pop animation on activation
- [ ] User stays on Library after activation (card updates in place)
- [ ] User can remove protocol from stack via detail sheet
- [ ] Remove shows confirmation dialog with protocol name
- [ ] Removal updates card visually (optimistic)
- [ ] Free user sees locked protocols at 2+ in stack
- [ ] Trial user sees all protocols as available
- [ ] Premium user sees all protocols as available

### Navigation
- [ ] Bottom nav shows Library as active
- [ ] Tapping Stack nav goes to / route
- [ ] Tapping Progress shows "Coming soon" toast
- [ ] Back gesture exits app
- [ ] Scroll position preserved when returning to Library

### Paywall Flow
- [ ] Locked card tap shows detail sheet with upgrade CTA
- [ ] "Upgrade to Add" button opens paywall
- [ ] Dismissing paywall returns to library

### Detail Sheet
- [ ] Shows protocol info (name, category, evidence, target)
- [ ] Shows session stats for in-stack protocols (fetched on demand)
- [ ] Actions vary based on protocol status
- [ ] Remove action shows confirmation dialog

### Loading & Error States
- [ ] Loading spinner on initial load
- [ ] Pull-to-refresh works
- [ ] Error state shows message with refresh prompt
- [ ] Offline shows cached data with banner
- [ ] Network error on activation retries once silently

### UI Polish
- [ ] Spotlight effect on available cards (shared widget)
- [ ] All evidence colors match spec (4 tiers)
- [ ] Locked cards have dashed border and muted colors
- [ ] Category headers are simple text, correctly styled

## UI Design

Strictly for styling reference, ignore any flow specifications, the ones above are the source of truth.

Background: #030303 with grid texture.

Layout:

1. Header (px-6, pt-6):
    - Title: "Protocol Library" - Newsreader italic, 32px, text-white/90, letter-spacing: -0.025em

2. Protocol list (px-6, mt-6, space-y-4, pb-28 for nav clearance):

   Each protocol card — three visual variants:

   A) In Stack (already active):
    - Container: bg-white/[0.02], rounded-[24px], p-6
    - Border: 1px solid brand-sky/30 (accent border indicating active)
    - Badge (top-right, absolute):
        - Circle: 24px, bg-brand-sky, checkmark icon (white, 14px)
        - Glow: 0 0 10px rgba(56,189,248,0.3)

   Contents:
    - Category: Mono pill (same styling)
    - Name: "Norwegian 4×4 HIIT" - Inter, 18px, font-weight: 500, text-white/90
    - Evidence: "Multiple RCTs" - Inter, 12px, font-weight: 400, text-emerald-400, mt-1
    - Status: "In your stack" - Inter, 12px, text-brand-sky, mt-3

   B) Available (can add):
    - Container: bg-white/[0.02], rounded-[24px], p-6
    - Border: 1px solid white/10
    - Spotlight effect on touch
    - Badge: Plus icon in white/30 circle, 24px

   Contents similar, status line: "Tap to add" - text-white/40

   Hover/touch: border-white/20, spotlight active

   C) Locked (free tier limit):
    - Container: bg-white/[0.01] (slightly more muted), rounded-[24px], p-6
    - Border: 1px dashed white/10
    - Badge: Lock icon in white/20 circle, 24px
    - All text at reduced opacity (name: white/50, others: white/30)
    - Status: "Upgrade to unlock" - text-amber-400/80
    - Tap → Paywall

   Evidence strength color coding:
    - "Multiple RCTs": text-emerald-400
    - "Single RCT": text-brand-sky
    - "Mechanistic": text-white/50

3. Bottom navigation (same as Stack screen, Library tab active with Brand Sky)
