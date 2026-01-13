# NeuroStack MVP Screen functional specifications

## Quick Reference

**Budget**: 49 hours | **Screens**: 8 | **Architecture**: MVVM + ValueNotifier + fpdart Either

### Time Allocation

| Screen | Hours | Priority |
|--------|-------|----------|
| Onboarding (2 screens) | 3h | P0 |
| Stack Screen | 6h | P0 |
| Library Screen | 8h | P0 |
| Log Session Modal | 6h | P0 |
| Progress Screen | 6h | P1 |
| Paywall Modal | 4h | P1 |
| Trial Expired Modal | 2h | P1 |
| Deactivation Modal | 3h | P1 |
| **Total** | **38h** | +11h buffer |

---

## App Launch Flow

```
                         APP LAUNCH
                              │
                              ▼
                   ┌─────────────────────┐
                   │ onboardingCompleted?│
                   └─────────────────────┘
                      │ NO          │ YES
                      ▼             ▼
              ┌───────────┐  ┌─────────────────────┐
              │ Onboarding│  │ getEffectiveStatus()│
              │   Flow    │  └─────────────────────┘
              └───────────┘         │
                    │               ▼
                    │        ┌─────────────┐
                    │        │ status ==   │
                    │        │   trial &&  │
                    │        │  expired?   │
                    │        └─────────────┘
                    │         │ YES    │ NO
                    │         ▼        │
                    │   ┌───────────┐  │
                    │   │ Trial     │  │
                    │   │ Expired   │  │
                    │   │ Modal     │  │
                    │   └───────────┘  │
                    │         │        │
                    ▼         ▼        ▼
                    └────► Stack Screen ◄┘
```

---

## 1. Splash Screen

**Route**: `/` | **Budget**: included in navigation setup

### States

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Initial launch | Logo + CircularProgressIndicator |

### Navigation Logic

```dart
final user = await userRepository.getCurrentUser();
user.fold(
  (_) => go('/onboarding/1'),
  (user) => user == null || !user.onboardingCompleted
    ? go('/onboarding/1')
    : go('/home'),
);
```

---

## 2. Onboarding Screen 1

**Route**: `/onboarding/1` | **Budget**: 1.5h

### Wireframe

```
┌─────────────────────────────────────┐
│                                     │
│           [NeuroStack Logo]         │
│                                     │
│   "Track Science-Backed Protocols"  │
│                                     │
│   ┌───────────────────────────────┐ │
│   │   🎁 7-Day Premium Trial      │ │
│   │   • Unlimited protocols       │ │
│   │   • No credit card required   │ │
│   └───────────────────────────────┘ │
│                                     │
│         [Continue →]                │
│              ● ○                    │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Default | Always | Static content |

### Navigation

- **Continue** → `/onboarding/2`

### Invariants
- **INV-M3**: "No credit card required" visible

---

## 3. Onboarding Screen 2

**Route**: `/onboarding/2` | **Budget**: 1.5h

### Wireframe

```
┌─────────────────────────────────────┐
│                                     │
│              ⚠️                     │
│                                     │
│      "Important Disclaimer"         │
│                                     │
│   NeuroStack provides protocol      │
│   tracking based on published       │
│   research. This is not medical     │
│   advice. Consult your healthcare   │
│   provider before starting any      │
│   new protocol.                     │
│                                     │
│   ☐ I understand and agree          │
│                                     │
│       [Get Started]                 │
│       (disabled until checked)      │
│              ○ ●                    │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Default | Checkbox unchecked | Button disabled |
| Ready | Checkbox checked | Button enabled |
| Loading | Processing | Button spinner |
| Error | Save failed | Toast + retry |

### Domain Action

```dart
// On "Get Started":
final user = User.createWithTrial(id: generateUUID()); // INV-U3
final completed = user.completeOnboarding();           // INV-U4
await userRepository.save(completed.getOrThrow());
go('/home');
```

### Invariants
- **INV-U3**: `createWithTrial()` sets `trialStartDate`
- **INV-U4**: `completeOnboarding()` gates main app
- **INV-B4**: Legal disclaimer shown

---

## 4. Stack Screen (Home)

**Route**: `/home` | **Budget**: 6h

### Wireframe

```
┌─────────────────────────────────────┐
│ [Trial: 5 days left]            [X] │ ← Conditional banner
├─────────────────────────────────────┤
│                                     │
│   Your Stack               [+ Add]  │
│   2/2 active (free only)            │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏃 Norwegian 4x4 HIIT           │ │
│ │ 4x4 min at 90-95% HR, 3x/wk     │ │
│ │                    [Log Session]│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔥 Sauna Heat Exposure          │ │
│ │ 20 min at 108°F, 3-4x/wk        │ │
│ │                    [Log Session]│ │
│ └─────────────────────────────────┘ │
│                                     │
│   [Empty: "Add your first protocol"]│
│                                     │
├─────────────────────────────────────┤
│   🏠 Stack   📚 Library   📅 Week  │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Fetching data | Skeleton cards |
| Empty | `stack.isEmpty` | Empty illustration + CTA |
| Populated | `stack.isNotEmpty` | Protocol cards |
| Error | Fetch failed | Error + retry |

### Subscription UI Mapping

| Status | Banner | Counter |
|--------|--------|---------|
| `trial` | "Trial: X days left" | Hidden |
| `free` | Hidden | "X/2 active" |
| `premiumMonthly/Annual` | Hidden | Hidden |
| `expired` | "Subscription expired" | "X/2 active" |
| `grace` | "Payment issue" | Hidden |

### Navigation

| Action | Destination | Condition |
|--------|-------------|-----------|
| Tap "+ Add" | `/library` | Always |
| Tap "Log Session" | Log Session Modal | `canLogSession.isRight()` |
| Tap "Log Session" | Deactivation Modal | `canLogSession == Left(tooManyActiveProtocols)` |
| Tap trial banner | Paywall Modal | Always |

### Invariants
- **INV-U5**: Log button checks `canLogSession()`
- **INV-M4**: Banner shows `trialPeriod.daysRemaining()`

---

## 5. Library Screen

**Route**: `/library` | **Budget**: 8h

### Wireframe

```
┌─────────────────────────────────────┐
│ Protocol Library                    │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏃 Norwegian 4x4 HIIT     [✓]   │ │ ← In stack
│ │ Multiple RCTs • Exercise        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔥 Sauna Heat Exposure    [✓]   │ │
│ │ Multiple RCTs • Heat Therapy    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🌅 Morning Sunlight       [🔒]  │ │ ← Locked (at limit)
│ │ Single RCT • Mind               │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💊 Omega-3 Daily          [+]   │ │ ← Available (trial/premium)
│ │ Multiple RCTs • Supplements     │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│   🏠 Stack   📚 Library   📅 Week  │
└─────────────────────────────────────┘
```

### Protocol Activation Flow

```
          USER TAPS PROTOCOL ROW
                    │
                    ▼
         ┌─────────────────────┐
         │ Protocol in stack?  │
         └─────────────────────┘
           │ YES        │ NO
           ▼            ▼
    ┌───────────┐  ┌─────────────────┐
    │ Tap [✓]   │  │ activateProtocol│
    │ → Detail  │  └─────────────────┘
    │   Sheet   │       │
    └───────────┘       ├── Right(user) → Save → Refresh
                        │
                        └── Left(ProtocolLimitReached)
                                    │
                                    ▼
                             Paywall Modal
```

### Badge States

| Condition | Icon | Tap Action |
|-----------|------|------------|
| `stack.contains(id)` | ✓ (green) | Show detail sheet |
| Can activate | + (blue) | Activate immediately |
| At limit, not in stack | 🔒 (gray) | Show Paywall |

### Invariants
- **INV-U1/M5**: Lock when `free && stack.count >= 2`
- **INV-U2**: No locks during trial
- **INV-B2**: Locked tap → Paywall

---

## 6. Progress Screen (Week View)

**Route**: `/week` | **Budget**: 6h

### Wireframe

```
┌─────────────────────────────────────┐
│ This Week                           │
│ Dec 2 - Dec 8, 2025                 │
├─────────────────────────────────────┤
│                                     │
│        Mon Tue Wed Thu Fri Sat Sun  │
│ HIIT   ✓   ✓   ○   ○   ✓   ·   ·   │
│ Sauna  ✓   ○   ✓   ○   ○   ·   ·   │
│                                     │
│   ✓ Completed  ○ Not done  · Future │
│                                     │
├─────────────────────────────────────┤
│   🏠 Stack   📚 Library   📅 Week  │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Loading | Fetching | Skeleton grid |
| Empty Stack | `stack.isEmpty` | "Add protocols to track" |
| Empty Week | No sessions | "No sessions this week" |
| Populated | Has data | Grid with markers |

### Cell Logic

```dart
DayCellState getCellState(DateTime day, String protocolId, List<Session> sessions) {
  if (day.isAfter(DateTime.now())) return DayCellState.future;
  final hasSession = sessions.any((s) => 
    s.protocolId == protocolId && isSameDay(s.completedAt, day));
  return hasSession ? DayCellState.completed : DayCellState.notDone;
}
```

---

## 7. Log Session Modal

**Type**: Bottom sheet | **Budget**: 6h

### Wireframe

```
┌─────────────────────────────────────┐
│ ─────────────────────────────────── │
│                                     │
│   Log Session                       │
│   Norwegian 4x4 HIIT                │
│                                     │
│   When                              │
│   [Today, Dec 8, 2025          ▼]  │
│                                     │
│   Duration (optional)               │
│   [__ min                       ]  │
│                                     │
│   Notes (optional)                  │
│   [                             ]  │
│   0/50 characters                   │
│                                     │
│       [Log Session]                 │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Ready | Sheet opened | Form with today selected |
| Saving | Submit tapped | Button spinner, inputs disabled |
| Success | Save completed | Dismiss + toast |
| Error | Validation failed | Inline error |

### Validations

| Field | Rule | Invariant | Error |
|-------|------|-----------|-------|
| Date | `<= now` | INV-S2 | Picker disables future |
| Duration | If set, `> 0` | INV-S3 | "Must be greater than zero" |
| Notes | Max 50 chars | — | Counter only |

### Domain Action

```dart
Future<void> logSession() async {
  SessionDuration? duration;
  if (durationMinutes != null && durationMinutes! > 0) {
    duration = SessionDuration.create(Duration(minutes: durationMinutes!))
        .getOrElse(() => null);
  }
  
  final result = Session.create(
    id: generateUUID(),
    protocolId: protocolId,
    completedAt: selectedDate,
    duration: duration,
    notes: notes,
    currentTime: DateTime.now(),
  );
  
  result.fold(
    (failure) => showError(failure),
    (session) async {
      await sessionRepository.save(session);
      dismiss(success: true);
    },
  );
}
```

---

## 8. Paywall Modal

**Type**: Modal overlay | **Budget**: 4h

### Triggers
1. Free user taps locked protocol
2. Day 8+ user opens app (trial expired)
3. User taps "Upgrade" / trial banner / "2/2 active"

### Wireframe

```
┌─────────────────────────────────────┐
│                              [X]    │
│                                     │
│      Unlock All Protocols           │
│                                     │
│   ✓ Unlimited protocol activation   │
│   ✓ All 5 protocols available       │
│   ✓ All future protocols included   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Monthly              $7.99/mo   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Annual    SAVE 37%   $59.99/yr  │ │ ← Highlighted
│ └─────────────────────────────────┘ │
│                                     │
│   [Subscribe]                       │
│                                     │
│   [Continue with Free]              │
│                                     │
└─────────────────────────────────────┘
```

### States

| State | Condition | UI |
|-------|-----------|-----|
| Default | Modal shown | Annual pre-selected |
| Purchasing | Tapped Subscribe | Button spinner |
| Success | Purchase done | Dismiss + refresh |
| Error | Purchase failed | Toast + retry |

### Domain Action

```dart
// On successful StoreKit purchase:
final result = user.upgradeToPremium(
  isAnnual ? SubscriptionStatus.premiumAnnual : SubscriptionStatus.premiumMonthly,
);
result.fold(
  (f) => showError(f),
  (u) => userRepository.save(u),
);
```

### Invariants
- **INV-M7**: 37% discount displayed
- **INV-B3**: Both monthly/annual shown
- **INV-B5**: "Continue with Free" always available

---

## 9. Trial Expired Modal

**Type**: Blocking modal | **Budget**: 2h

### Trigger
App launch when `status == trial && trialPeriod.isExpired(now)`

### Wireframe

```
┌─────────────────────────────────────┐
│                                     │
│      Your Premium Trial             │
│         Has Ended                   │
│                                     │
│   [stack.count > 2 messaging]       │
│                                     │
│   [Keep All → Subscribe]            │
│                                     │
│   [Use Free Tier → Choose 2]        │
│                                     │
└─────────────────────────────────────┘
```

### Navigation

| Action | Condition | Destination |
|--------|-----------|-------------|
| "Subscribe" | Always | Paywall Modal |
| "Use Free" | `stack.count <= 2` | Dismiss → Stack |
| "Use Free" | `stack.count > 2` | Deactivation Modal |

### Invariants
- **INV-M4**: Auto-triggered Day 8+

---

## 10. Deactivation Modal

**Type**: Blocking modal | **Budget**: 3h

### Trigger
Trial expired + `stack.count > 2`

### Wireframe

```
┌─────────────────────────────────────┐
│                                     │
│   Choose 2 Protocols to Keep        │
│                                     │
│   ┌───────────────────────────────┐ │
│   │ [✓] 🏃 Norwegian 4x4 HIIT     │ │
│   │     12 sessions logged        │ │
│   └───────────────────────────────┘ │
│   ┌───────────────────────────────┐ │
│   │ [✓] 🔥 Sauna Heat Exposure    │ │
│   │     8 sessions logged         │ │
│   └───────────────────────────────┘ │
│   ┌───────────────────────────────┐ │
│   │ [ ] 🌅 Morning Sunlight       │ │
│   │     3 sessions logged         │ │
│   └───────────────────────────────┘ │
│                                     │
│   2/2 selected                      │
│                                     │
│   [Confirm Selection]               │
│   (disabled until exactly 2)        │
│                                     │
└─────────────────────────────────────┘
```

### Pre-selection Algorithm

```dart
List<String> getPreSelected(List<String> protocolIds, Map<String, int> sessionCounts) {
  return [...protocolIds]
    ..sort((a, b) => (sessionCounts[b] ?? 0).compareTo(sessionCounts[a] ?? 0))
    ..take(2).toList();
}
```

### Domain Action

```dart
Future<void> confirmDeactivation(List<String> keepIds) async {
  final removeIds = user.stack.protocolIds.where((id) => !keepIds.contains(id));
  var current = user;
  for (final id in removeIds) {
    current = current.deactivateProtocol(id).getOrElse(() => current);
  }
  current = current.updateSubscriptionStatus(SubscriptionStatus.free);
  await userRepository.save(current);
}
```

### Invariants
- **INV-U1**: Result has exactly 2 protocols
- **INV-U5**: Enforces limit before allowing main app

---

## Appendix A: Error Mapping

| Failure | User Message | UI Treatment |
|---------|--------------|--------------|
| `ProtocolLimitReached` | — | Paywall Modal |
| `ProtocolAlreadyActive` | "Already in your stack" | Toast |
| `ProtocolNotActive` | "Not in your stack" | Toast |
| `OnboardingNotCompleted` | — | Force Onboarding |
| `TooManyActiveProtocols` | — | Deactivation Modal |
| `ProtocolNotInStack` | "Add this protocol first" | Toast |
| `TimestampInFuture` | "Date cannot be in the future" | Inline error |
| `DurationMustBePositive` | "Duration must be greater than 0" | Inline error |
| Repository failure | "Something went wrong. Try again." | Toast + retry |

---

## Appendix B: Component Inventory

| Component | Props | Used In |
|-----------|-------|---------|
| `ProtocolCard` | protocol, onLogTap | Stack |
| `ProtocolRow` | protocol, badge, onTap | Library |
| `TrialBanner` | daysRemaining, onTap, onDismiss | Stack |
| `StackBadge` | count, limit | Stack |
| `WeekGrid` | sessions, protocols, weekStart | Progress |
| `DayCell` | state (completed/notDone/future) | WeekGrid |
| `PaywallPriceOption` | plan, price, isSelected, onTap | Paywall |

---

## Appendix C: File Structure

```
lib/features/
├── onboarding/
│   ├── onboarding_view_model.dart
│   ├── onboarding_page1.dart
│   └── onboarding_page2.dart
├── stack/
│   ├── stack_view_model.dart
│   ├── stack_screen.dart
│   └── widgets/
│       ├── protocol_card.dart
│       └── trial_banner.dart
├── library/
│   ├── library_view_model.dart
│   ├── library_screen.dart
│   └── widgets/
│       └── protocol_row.dart
├── progress/
│   ├── progress_view_model.dart
│   ├── progress_screen.dart
│   └── widgets/
│       ├── week_grid.dart
│       └── day_cell.dart
└── shared/
    ├── log_session_sheet.dart
    ├── paywall_modal.dart
    ├── trial_expired_modal.dart
    └── deactivation_modal.dart
```

---

## Not Covered (Deferred)

- Offline behavior
- Animation timing/haptics
- Pull-to-refresh
- Loading skeleton designs
- Protocol detail sheet (inline expansion)
- Category filters in Library