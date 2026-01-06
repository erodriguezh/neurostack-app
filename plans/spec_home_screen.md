# Spec: Home Screen

## Purpose

Primary screen showing user's active protocols with session logging capability. This is where users spend most of their time.

---

## Screen States

| State | Condition | User Experience |
|-------|-----------|-----------------|
| Loading | Initial fetch in progress | Centered spinner |
| Empty | No protocols in stack | Empty state with guidance |
| Populated | Has protocols | Protocol cards displayed |
| Error | Fetch failed | Error message, pull-to-refresh to retry |
| Offline | No network connection | Offline indicator banner |

---

## Required Content

### 1. Subscription Status Banner (Conditional)

Displayed below status bar when relevant. **Dismissible per session only.**

| Status | Display | Tap Action |
|--------|---------|------------|
| `trial` | "X days left in trial" | → Paywall |
| `free` | "2/2 active" (usage indicator) | — (no action) |
| `expired` | "Subscription has lapsed" | → Paywall |
| `grace` | "Payment issue" | → Payment Modal (stub) |
| `premiumMonthly/Annual` | Nothing displayed | — |

- Trial days: `trialPeriod.daysRemaining(now)` **(INV-M4)**
- Dismissal persists for current session only

### 2. Screen Header

- Title: **"Your Stack"** (Newsreader italic, 32px)
- Subtitle intent: User's personal protocol collection

### 3. Add Protocol Button

- Copy: **"+ Add"**
- Always visible regardless of stack state
- Tap → Navigate to Library screen
- **Free tier at limit (2/2):** User can browse Library, but sees upgrade prompt when attempting to add

### 4. Protocol Cards

**Display order:** Insertion order (oldest first)

Each card shows:
- **Category pill:** e.g., "EXERCISE"
- **Status dot:**
  - Green (animated): Session logged today (calendar day, midnight reset)
  - Gray: No session logged today
- **Protocol name:** e.g., "Norwegian 4x4 HIIT"
- **Quick reference:** e.g., "4x4 min at 90-95% HR, 3x/wk"
- **Log Session button**

**Card tap behavior:** No action (placeholder for future detail view)

**Log Session tap behavior:**
- Check `canLogSession()` **(INV-U5)**
- Success → No action yet (button placeholder)
- `TooManyActiveProtocols` → Deactivation Modal

**Protocol Unavailable state:**
- When referenced protocol no longer exists in catalog
- Card displays with "Protocol unavailable" messaging
- Visually distinguishable from normal cards

### 5. Empty State

When `stack.isEmpty`:
- Icon: Layers/stack icon in circular container
- Text: **"Add your first protocol"**
- Link: **"Browse Library"** → Library screen

### 6. Bottom Navigation

Three tabs (pill-shaped container):
- **Stack** (current, highlighted)
- **Library** (no action - not implemented)
- **Progress** (no action - not implemented)

Active tab indicated with dot + brand color

---

## Modal Flows

### Trial Expired Modal

**Trigger:** Every app open while subscription status is `expired`

**Content:**
- Title: "Your Premium Trial Has Ended"
- Messaging: Acknowledges if `stack.count > 2`
- Two CTAs:
  - **"Keep All → Subscribe"** → Paywall
  - **"Use Free Tier"** → Branching logic:
    - If `stack.count <= 2`: Dismiss modal → Home Screen
    - If `stack.count > 2`: → Deactivation Modal

**UI:** Deferred (logic/flow only for now)

### Deactivation Modal

**Trigger:** Free tier user with `stack.count > 2` needs to choose protocols

**Content:**
- Title: "Choose 2 Protocols to Keep"
- List: All protocols with checkboxes
  - Shows: Protocol name, icon, total sessions logged
  - **Pre-selection:** Two most-used protocols (by session count descending)
- Counter: "X/2 selected"
- **Confirm button:** Disabled until exactly 2 selected

**On confirm:**
1. Deactivate all non-selected protocols
2. Switch subscription status to `free`
3. Dismiss modal → Home Screen

**UI:** Deferred (logic/flow only for now)

### Grace Period Modal (Stub)

**Trigger:** Tap grace period banner

**Content:** Placeholder modal explaining payment issue

**UI:** Future implementation

---

## Data Refresh

| Trigger | Behavior |
|---------|----------|
| App launch | Full fetch |
| Pull-to-refresh | Full fetch |
| Realtime | Supabase realtime subscription for updates |

---

## Error Handling

| Error Type | Handling |
|------------|----------|
| Network failure | Error state, pull-to-refresh to retry |
| Server error (5xx) | Error state, pull-to-refresh to retry |
| Auth expired | App handles globally (redirects to sign-in) |
| Data inconsistency | Show affected card as "Protocol unavailable" |

**Retry mechanism:** Pull-to-refresh only (no retry button)

---

## Data Requirements

- User object (subscription status, trial dates)
- User's protocol stack (with insertion order)
- Protocol details for each stack item
- Session history (to determine today's logged status)

---

## UI Specification

Use the UI system from `core/ui` to generate the UI from the prompt below:

```
Create a mobile-first home/stack screen.

Background: #030303 with subtle grid texture (radial mask).

Layout:

**Status banner (conditional, below status bar):**
- For trial status:
  - Container: bg-brand-sky/10, backdrop-blur-sm, px-6, py-3, relative
  - Left: Clock icon (14px, Brand Sky #38BDF8) with subtle ping animation, inside flex container with gap-3
  - Text: "5 days left in trial" - Inter, 13px, font-weight: 400, text-brand-sky
  - Right: Chevron icon (16px, white/40, hover: white/80) indicating tappable → Paywall
  - Top border: absolute thin gradient line (from-transparent via-brand-sky/30 to-transparent), h-[1px]
- Dismissible: X button far right (14px icon, white/40, 24px touch target with hover:bg-white/10 rounded-full)

**Header section (px-6, pt-6, flex justify-between items-end):**
- Title: "Your Stack" - Newsreader italic, 32px, font-weight: 400, text-white/90, tracking-tight (-0.025em)
- Add button (right aligned):
  - "+ Add" - Inter, 13px, font-weight: 500, text-brand-sky, hover: text-brand-sky/80
  - Touch target: 44px height

**Protocol cards (px-6, mt-6, space-y-4):**

Each protocol card:
- Container: bg-white/[0.02], rounded-[24px], p-6
- Border: 1px solid white/10, hover: border-white/20, transition-colors
- Spotlight effect: CSS custom property --mouse-x/--mouse-y, radial gradient (600px circle, white/[0.06] at pointer, transparent 40%), opacity 0 → 1 on hover

Card contents:

- Top row (flex, justify-between, items-start):
  - Category pill:
    - Container: bg-white/5, rounded-full, px-3, py-1, border border-white/5
    - Text: "EXERCISE" - JetBrains Mono, 10px, font-weight: 500, uppercase, tracking-[0.15em], text-white/50, translate-y-[1px]
  - Status dot (mt-1.5, mr-1):
    - Active: 8px, bg-emerald-500, with slow ping animation (3s, cubic-bezier)
    - Inactive: 8px, bg-white/20, no animation

- Protocol name: "Norwegian 4x4 HIIT" - Inter, 18px, font-weight: 500, text-white/90, mt-4, tracking-tight (-0.025em)

- Quick reference: "4x4 min at 90-95% HR, 3x/wk" - Inter, 13px, font-weight: 300, text-white/50, mt-2, leading-relaxed

- Log button (mt-5):
  - Container: bg-white/5, hover: bg-white/[0.08], rounded-full, px-5, py-2.5, flex items-center gap-2
  - Border: 1px solid white/10, hover: border-brand-sky/30
  - Text: "Log Session" - Inter, 13px, font-weight: 500, text-white/70, group-hover: text-white
  - Arrow icon: 14px, stroke-width: 2, text-white/40, group-hover: translate-x-1, group-hover: text-brand-sky
  - Transition: all 300ms
  - Width: w-full on mobile, w-auto on sm+

**Empty state (hidden by default, shown when no protocols):**
- Container: flex flex-col items-center justify-center, mt-24, px-6
- Icon container: w-20 h-20, rounded-full, bg-white/5, border border-white/10, flex items-center justify-center, mb-4
- Icon: Layers/stack, 32px, stroke-width: 1.5, text-white/30
- Text: "Add your first protocol" - Inter, 16px, font-weight: 400, text-white/40
- Link: "Browse Library" - Inter, 14px, font-weight: 500, text-brand-sky, hover: underline, mt-6

**Bottom navigation (absolute, bottom-3, left-3, right-3):**
- Container: h-[64px], rounded-full, bg-[#050505]/80, backdrop-blur-xl
- Border: 1px solid white/10
- Shadow: 0 8px 32px rgba(0,0,0,0.4)
- Layout: flex items-center justify-around

Three tabs (flex-1, flex flex-col items-center justify-center, gap-1, full height):
- Stack (active):
  - Active indicator: w-1 h-1 dot, absolute -top-2, bg-brand-sky, shadow glow (0 0 8px #38BDF8)
  - Icon: 20px, stroke-width: 2, text-brand-sky
  - Label: "Stack" - Inter, 10px, font-weight: 500, text-brand-sky
- Library:
  - Icon: 20px, stroke-width: 2, text-white/40, group-hover: text-white/70
  - Label: "Library" - Inter, 10px, font-weight: 500, text-white/40, group-hover: text-white/70
- Progress:
  - Icon: 20px, stroke-width: 2, text-white/40, group-hover: text-white/70
  - Label: "Progress" - Inter, 10px, font-weight: 500, text-white/40, group-hover: text-white/70

**Touch indicator (home bar):**
- Absolute bottom-1, centered, w-[134px], h-[5px], bg-white, rounded-full, opacity-30

**Content scroll area:**
- flex-1, overflow-y-auto, custom scrollbar hidden
- Padding: pt-[50px] (for status bar), pb-[100px] (for nav clearance)

**Animations:**
- fade-in: translateY(10px) → 0, opacity 0 → 1, 500ms ease-out
- ping-slow: 3s infinite ping for status dots
- Staggered animation-delay on content sections (100ms increments)

**JavaScript:**
- Spotlight effect: mousemove/touchmove listeners update --mouse-x/--mouse-y CSS variables on protocol cards
- Dismiss banner: onclick removes trial-banner element
```
