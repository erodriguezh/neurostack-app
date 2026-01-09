# Spec: Progress Screen

**Route**: `/week`
**Pattern**: Follows `library_screen` — standalone route with embedded bottom nav

---

## Purpose

Visual representation of protocol adherence over the current week. Users see their consistency patterns at a glance.

---

## Key Decisions (from interview)

| Topic | Decision |
|-------|----------|
| Week boundaries | User's local timezone (Mon-Sun) |
| Day rollover | Auto-refresh on focus |
| Today without session | Shows as **Future-like** until EOD |
| Deactivated protocols | Show with historical data if sessions exist this week |
| Multiple sessions/day | Binary — any session = completed |
| Caching | Cache until mutation; refetch on focus |
| Legend | **Dropped** — grid is self-explanatory |
| Empty week message | **Dropped** — empty grid speaks for itself |
| Protocol cap | Soft cap at 7 (warning shown when adding 7th, not on this screen) |

---

## Data Requirements

### Sources
- **Stack**: User aggregate owns stack, `ProtocolRepository` resolves IDs to entities
- **Sessions**: Existing `SessionRepository.getSessionsInRange(start, end)`
- **Week dates**: DateTime extension methods (`weekStart`, `weekEnd`)

### Caching Strategy
- Cache session data locally
- Invalidate on: session logged, protocol added/removed
- Always refetch on screen focus

---

## State Model

```dart
// lib/progress/progress_state.dart
sealed class ProgressState {
  const ProgressState();
}

class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

class ProgressLoaded extends ProgressState {
  final List<ProtocolRow> rows;
  final DateTimeRange weekRange;
  final int todayIndex; // 0-6, -1 if not in current week
  final bool isOffline;
  const ProgressLoaded({
    required this.rows,
    required this.weekRange,
    required this.todayIndex,
    required this.isOffline,
  });
}

class ProgressError extends ProgressState {
  final DomainFailure failure;
  const ProgressError(this.failure);
}
```

### Grid Data Model

```dart
class ProtocolRow {
  final String protocolId;
  final String protocolName;
  final List<DayCell> cells; // Always 7 cells (Mon-Sun)
}

class DayCell {
  final DateTime date;
  final CellState state;
}

enum CellState { completed, notDone, future }
```

### Cell State Logic

```dart
CellState getCellState(DateTime day, String protocolId, List<Session> sessions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dayStart = DateTime(day.year, day.month, day.day);

  // Today and future days are "future" (pending)
  if (!dayStart.isBefore(today)) return CellState.future;

  // Past day — check for session
  final hasSession = sessions.any((s) =>
    s.protocolId == protocolId && _isSameDay(s.completedAt, day));
  return hasSession ? CellState.completed : CellState.notDone;
}
```

---

## UI Specification

### Layout Structure

```
┌─────────────────────────────────────┐
│ This Week                           │  ← Header
│ Dec 2 – Dec 8, 2025                 │  ← Locale-aware format
├─────────────────────────────────────┤
│                                     │
│   [Offline banner if applicable]    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │     M   T   W   T   F   S   S   │ │  ← Day headers (abbreviated always)
│ │                  ↑              │ │  ← Current day highlighted
│ │ HIIT  ✓   ✓   ○   ·   ·   ·   · │ │
│ │ Sauna ✓   ○   ✓   ·   ·   ·   · │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│   🏠 Stack   📚 Library   📅 Week   │  ← Bottom nav (Progress active)
└─────────────────────────────────────┘
```

### Header
- Title: "This Week" — Newsreader italic, 32px, `white90`, letter-spacing: -0.025em
- Date range: Locale-aware format (e.g., "Dec 2 – Dec 8, 2025") — Inter, 14px, font-weight: 300, `white40`

### Week Grid Card
- Container: `bg-white/[0.02]`, `rounded-[24px]`, padding 24px
- Border: 1px solid `white/10`

#### Day Headers
- 7 columns, equal width
- Days: "M T W T F S S" — Inter mono, 11px, font-weight: 500, `white40`, text-center
- Current day: `brandSky` color (header only, not full column)

#### Protocol Rows
- Protocol name: Inter, 14px, font-weight: 400, `white70`, truncate based on available space
- Long-press on name: Show tooltip with full protocol name
- Alphabetical order
- Vertical spacing: 20px between rows

#### Cell Styling
- Size: Min 36×36px, can grow on larger screens
- Border radius: 12px (rounded-xl)
- Gap between cells: 8px

| State | Background | Border | Icon |
|-------|------------|--------|------|
| Completed | `brandSky/20` | `brandSky/30` | Checkmark, `brandSky`, 16px |
| Not Done | `white/[0.02]` | `white/5` | None or subtle X, `white/20` |
| Future | transparent | dashed `white/10` | None |

#### Cell Animation
- On state change: Subtle scale + fade animation
- Initial load: Simple fade-in (not staggered)

### Empty States

| Condition | Display |
|-----------|---------|
| No protocols in stack | Card shows: Icon (Layers, 32px, `white/20`) + "Add protocols to track" centered |
| Has protocols, all days future | Show grid normally (7 future cells per protocol) |

### Bottom Navigation
- Same as Library/Home screens
- Progress/Week tab is active

---

## Interactions

### Cell Taps
- **Completed cells**: No interaction (display only)
- **Not Done (past) cells**: Open backdate sheet
- **Future cells**: No interaction

### Backdate Flow

1. User taps missed (Not Done) cell
2. Opens simplified modal bottom sheet:
   - Copy: "Log [Protocol Name] session for [Day], [Date]?"
   - Single confirm button
   - No additional fields (duration, notes, etc.)
3. On confirm:
   - Optimistic update: Cell immediately shows completed
   - API call in background
   - On success: Sheet closes, grid reflects change, haptic feedback
   - On failure: Revert cell state, show toast, close sheet
4. **Offline**: Backdate interaction disabled (cells not tappable)

### Pull-to-Refresh
- Supported (like Library screen)
- Uses `RefreshIndicator`

### Navigation
- Bottom nav switches between Stack/Library/Progress
- No deep linking required

---

## Offline Behavior

- **Partial support**:
  - Read cached data ✓
  - Display grid ✓
  - Backdate disabled ✗
- Show offline banner when offline (same pattern as Library)
- Cells are not tappable when offline

---

## Loading & Error States

### Loading
- Centered spinner (`brandSky`)
- No skeleton grid

### Error
- Show toast with error message
- Display stale/cached data if available
- Pull-to-refresh to retry

---

## Scroll Behavior
- Always reset to top on screen visit
- No PageStorageKey (unlike Library)

---

## DateTime Extensions Required

```dart
extension DateTimeWeekExtension on DateTime {
  /// Returns Monday 00:00:00 of the week containing this date
  DateTime get weekStart {
    final daysFromMonday = weekday - 1; // Monday = 1
    return DateTime(year, month, day - daysFromMonday);
  }

  /// Returns Sunday 23:59:59 of the week containing this date
  DateTime get weekEnd {
    final daysToSunday = 7 - weekday;
    return DateTime(year, month, day + daysToSunday, 23, 59, 59);
  }

  /// Check if same calendar day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
```

---

## Testing Requirements

### Priority
1. **Cell state logic** — Ensure correct Completed/NotDone/Future states
2. **Week boundary calculations** — DateTime extension correctness

### Approach
- **ViewModel unit tests**: State transitions, grid computation, week calculations
- **Widget tests**: UI rendering, cell states, empty states

### Key Test Cases

```dart
// Cell state logic
test('past day with session returns completed')
test('past day without session returns notDone')
test('today returns future')
test('future day returns future')

// Week boundaries
test('weekStart returns Monday for any day')
test('weekEnd returns Sunday for any day')
test('handles month boundaries correctly')
test('handles year boundaries correctly')

// Edge cases
test('deactivated protocol with sessions shows in grid')
test('multiple sessions same day shows single checkmark')
test('timezone change recalculates week boundaries')
```

---

## File Structure

```
lib/progress/
├── progress_view.dart
├── progress_view_model.dart
├── progress_state.dart
└── widgets/
    ├── progress_grid.dart
    ├── progress_day_cell.dart
    └── backdate_session_sheet.dart

lib/core/utils/
└── date_time_extensions.dart  # (check if existing utils can be extended)

test/progress/
├── progress_view_model_test.dart
├── progress_state_test.dart
└── widgets/
    ├── progress_grid_test.dart
    └── progress_day_cell_test.dart

test/core/utils/
└── date_time_extensions_test.dart
```

---

## Acceptance Criteria

- [ ] Screen displays at `/week` route
- [ ] Header shows "This Week" with locale-aware date range
- [ ] Grid shows all active protocols (plus deactivated with sessions this week)
- [ ] Protocols ordered alphabetically
- [ ] Current day header highlighted with `brandSky`
- [ ] Cells correctly show Completed/NotDone/Future states
- [ ] Today without session shows as Future (pending)
- [ ] Tapping missed cell opens backdate confirmation sheet
- [ ] Backdate shows full context: protocol name + date
- [ ] Successful backdate: cell updates, sheet closes, haptic
- [ ] Failed backdate: toast, cell reverts, sheet closes
- [ ] Pull-to-refresh works
- [ ] Auto-refresh on screen focus
- [ ] Offline mode shows banner, disables backdate
- [ ] Long-press protocol name shows full name tooltip
- [ ] Empty state when no protocols in stack
- [ ] Loading shows centered spinner
- [ ] Error shows toast with cached data
- [ ] Bottom nav present with Progress tab active

---

## Next Steps

Suggested: `/flow:plan spec_progress_screen.md` to create implementation plan
