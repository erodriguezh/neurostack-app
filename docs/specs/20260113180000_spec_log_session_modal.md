# Spec: Log Session Modal

**Pattern**: Shared modal widget with own ViewModel, offline-first persistence, sync service orchestration

---

## Purpose

The Log Session Modal allows users to record completed protocol sessions from both the Home screen (protocol card button) and Progress screen (grid cell tap). It implements offline-first persistence with background sync.

---

## Entry Points

| Screen | Trigger | Pre-fill Data |
|--------|---------|---------------|
| Home | Protocol card "Log" button | Protocol + today's date |
| Progress | Grid cell tap | Protocol + cell's date |

---

## Modal Presentation

**Type:** `showModalBottomSheet` (not a GoRouter route)

**Visual Spec:** (from `docs/best_practices/design/screen-prompts/05-log-session-modal.md`)
- Slides up from bottom, covers ~85% of screen
- Background: `#050505`, rounded-t-[32px]
- Overlay: `#030303` at 80% opacity with backdrop blur
- Drag indicator: white/20 pill, 40px x 4px
- Animation: 400ms ease-out slide + fade

---

## Input Parameters

```dart
// lib/features/session/presentation/log_session_modal.dart
Future<void> showLogSessionModal(
  BuildContext context, {
  required Protocol protocol,
  DateTime? initialDate,  // Defaults to today if null
  required void Function(Session session) onSessionLogged,
});
```

**Parameters:**
- `protocol` — Protocol entity (provides id and name for display)
- `initialDate` — Pre-filled date, defaults to `DateTime.now()` if null
- `onSessionLogged` — Callback invoked after successful local persistence

---

## ViewModel

### LogSessionViewModel

```dart
// lib/features/session/presentation/view_models/log_session_view_model.dart
class LogSessionViewModel {
  final ValueNotifier<LogSessionState> state;

  final Protocol protocol;
  final DateTime initialDate;

  // Form state (not in sealed state, managed separately)
  DateTime selectedDate;
  int? durationMinutes;
  String notes;

  Future<void> init();  // Eligibility check
  Future<void> submit();
  void dispose();
}
```

### State

```dart
// lib/features/session/presentation/view_models/log_session_state.dart
sealed class LogSessionState {}

class LogSessionInitial extends LogSessionState {}

class LogSessionReady extends LogSessionState {}

class LogSessionSubmitting extends LogSessionState {}

class LogSessionSuccess extends LogSessionState {
  final Session session;
}

class LogSessionError extends LogSessionState {
  final DomainFailure failure;
}

class LogSessionIneligible extends LogSessionState {
  final DomainFailure failure;  // User.TooManyActiveProtocols
}
```

---

## Business Rules & Invariants

| ID | Rule | Enforcement | Failure Code |
|----|------|-------------|--------------|
| **INV-LSM1** | Date cannot be in the future | `selectedDate.isAfter(now)` check in `submit()` | `Session.TimestampInFuture` |
| **INV-LSM2** | Date cannot be more than 7 days ago | `now.difference(selectedDate).inDays > 7` check | `Session.DateTooOld` |
| **INV-LSM3** | Duration must be positive if provided | Delegates to `SessionDuration.create()` | `Session.DurationMustBePositive` |
| **INV-LSM4** | Notes max 140 characters | Enforced by TextField maxLength | N/A (UI constraint) |
| **INV-LSM5** | User must be eligible to log for protocol | `LogSessionUseCase` checks `User.TooManyActiveProtocols` | `User.TooManyActiveProtocols` |

### New Domain Failure

```dart
// lib/features/session/domain/failures/session_failures.dart
static const dateTooOld = DomainFailure(
  code: 'Session.DateTooOld',
  message: 'Cannot log sessions more than 7 days in the past',
);
```

---

## Form Fields

### Date Field
- Label: "WHEN"
- Default: `initialDate` parameter (or today)
- Picker: Native date picker
- Constraints: No future dates, max 7 days back
- Display format: "Today, Jan 13, 2026" or "Mon, Jan 6, 2026"

### Duration Field
- Label: "DURATION"
- Badge: "(optional)"
- Input: Numeric keyboard, integer minutes
- Suffix: "min"
- Placeholder: "0"
- Validation: Must be > 0 if provided

### Notes Field
- Label: "NOTES"
- Badge: "(optional)"
- Input: Multiline text, max 140 characters
- Placeholder: "How did it go?"
- Character counter:
  - Hidden when < 100 characters
  - Visible at 100+ characters: "105/140"
  - Red color at 130+ characters

---

## Validation

**Timing:** On submit only (not real-time)

**Flow:**
```
1. User taps "Log Session" button
   ↓
2. Light haptic feedback (HapticFeedback.lightImpact)
   ↓
3. Announce "Saving session" (accessibility)
   ↓
4. Validate date range (INV-LSM1, INV-LSM2)
   ↓
5. Validate duration if provided (INV-LSM3)
   ↓
6. Create SessionDraft
   ↓
7. Persist locally via SessionLocalDataSource
   ↓
8. Trigger sync via SessionSyncService
   ↓
9. Announce "Session logged successfully" (accessibility)
   ↓
10. Invoke onSessionLogged callback
   ↓
11. Dismiss modal + show success toast
```

---

## Eligibility Check

**On modal open (`init()`):**

```dart
Future<void> init() async {
  // Check if user can log for this protocol
  final eligibility = await _checkEligibilityUseCase.execute(
    protocolId: protocol.id,
  );

  eligibility.fold(
    (failure) {
      if (failure.code == 'User.TooManyActiveProtocols') {
        state.value = LogSessionIneligible(failure: failure);
      } else {
        state.value = LogSessionError(failure: failure);
      }
    },
    (_) => state.value = LogSessionReady(),
  );
}
```

**Ineligible State UI:**
- Hide form fields
- Show upgrade prompt (reuse paywall components)
- "Upgrade to log sessions for this protocol"

---

## Offline-First Persistence

### Local Storage

```dart
// lib/features/session/data/data_sources/session_local_data_source.dart
class SessionLocalDataSource {
  // Uses SharedPreferences with user-scoped keys

  // Pending queue operations
  Future<void> savePendingSession(PendingSession pending);
  Future<List<PendingSession>> getPendingSessions(String userId);
  Future<void> removePendingSession(String userId, String localId);
  Future<void> clearPendingSessions(String userId);

  // Synced cache operations
  Future<void> upsertSyncedSessions(String userId, List<Session> sessions);
  Future<List<Session>> getSyncedSessions(String userId);
  Future<void> clearSyncedSessions(String userId);

  // Combined listing
  Future<List<Session>> listSessions(String userId, {DateTime? from, DateTime? to});

  // Pending ID prefix for collision safety
  static const pendingIdPrefix = 'pending:';
}
```

**Implementation Details:**
- Storage keys: `pending_sessions_$userId`, `synced_sessions_$userId`
- Self-healing: corrupt entries are automatically removed on read
- Fail-fast: `SessionDto` uses `_requiredStringFromJson` that throws on null/empty/non-String
- Pending sessions in `listSessions()` use prefixed IDs (`pending:localId`) to avoid collision with server UUIDs

### PendingSession Entity

```dart
// lib/features/session/domain/entities/pending_session.dart
class PendingSession {
  final String localId;       // UUID generated locally
  final String userId;        // For multi-account safety
  final SessionDraft draft;
  final DateTime createdAt;   // When saved locally
  final int retryCount;       // For sync retry logic
}
```

**Implementation Notes:**
- `PendingSession.create()` generates `localId` and initializes `retryCount: 0`
- `PendingSession.reconstitute()` validates `retryCount >= 0` (throws StateError for corrupted data)
- `SessionDraft.reconstitute()` normalizes notes (trim + empty-to-null) for consistency

### PendingSessionDto

```dart
// lib/features/session/data/dtos/pending_session_dto.dart
@freezed
class PendingSessionDto {
  // Flattens SessionDraft fields for simpler JSON storage
  // Fields: localId, userId, protocolId, completedAt, durationSeconds?, notes?, createdAt, retryCount

  PendingSession toDomain();  // Uses reconstitute factories
  factory PendingSessionDto.fromDomain(PendingSession);
}
```

**Storage Format:**
- JSON serialized to SharedPreferences
- Timestamps stored as UTC ISO 8601 strings (with "Z" suffix) for timezone portability
- Null optional fields omitted (`@JsonSerializable(includeIfNull: false)`)

### Sync Service

```dart
// lib/features/session/data/services/session_sync_service.dart
class SessionSyncService {
  Future<void> sync();  // Push all pending to server

  // Called from:
  // - StartupViewModel.init()
  // - AppLifecycleService (on foreground)
  // - ConnectivityService (on reconnect)
  // - LogSessionViewModel.submit() (after local save)
}
```

### Sync Behavior
- Silent retry on failure (session stays in queue)
- No user notification for sync errors
- No visual distinction between synced and pending sessions in UI

---

## Screen Integration

### Home Screen

```dart
// In HomeViewModel or ProtocolCard widget
void _onLogSessionTap(Protocol protocol) {
  showLogSessionModal(
    context,
    protocol: protocol,
    initialDate: DateTime.now(),
    onSessionLogged: (session) {
      // Refresh home screen data
      _loadProtocolSessions();
    },
  );
}
```

### Progress Screen

```dart
// In ProgressViewModel or ProgressGrid widget
void _onCellTap(Protocol protocol, DateTime date) {
  showLogSessionModal(
    context,
    protocol: protocol,
    initialDate: date,
    onSessionLogged: (session) {
      // Refresh progress grid
      _loadWeekSessions();
    },
  );
}
```

### Data Reading

Both screens must read from `SessionLocalDataSource.getAllSessions()` which combines:
- Synced sessions (from remote, cached locally)
- Pending sessions (not yet synced)

---

## Accessibility

| Event | Announcement |
|-------|--------------|
| Submit started | "Saving session" |
| Submit success | "Session logged successfully" |
| Submit error | Error message from DomainFailure |
| Modal open (ineligible) | "Upgrade required to log sessions for this protocol" |

**Implementation:** Use `SemanticsService.announce()` or `Semantics` widget with `liveRegion: true`.

---

## Haptic Feedback

- Light haptic (`HapticFeedback.lightImpact()`) on submit button tap
- Uses existing `HapticFeedbackListener` pattern from `lib/core/utils/internal_notification/`

---

## Dismiss Behavior

- Drag down gesture dismisses without confirmation
- X button dismisses without confirmation
- Form data is not preserved (no draft saving)
- Tapping overlay dismisses modal

---

## Duplicate Sessions

- Duplicates are allowed (same protocol + same date)
- No warning or confirmation for duplicates
- User can log multiple sessions per protocol per day

---

## Dependencies

```dart
// lib/config/locator_config.dart additions

Module<SessionLocalDataSource>(
  builder: () => SessionLocalDataSource(
    locator<SharedPreferences>(),
  ),
)

Module<SessionSyncService>(
  builder: () => SessionSyncService(
    locator<SessionLocalDataSource>(),
    locator<SessionRemoteDataSource>(),
    locator<ConnectivityService>(),
  ),
)

Module<CheckEligibilityUseCase>(
  builder: () => CheckEligibilityUseCase(
    locator<UserRepository>(),
  ),
)
```

---

## Key Files Reference

| Purpose | Path |
|---------|------|
| Modal entry point | `lib/features/session/presentation/log_session_modal.dart` |
| ViewModel | `lib/features/session/presentation/view_models/log_session_view_model.dart` |
| State | `lib/features/session/presentation/view_models/log_session_state.dart` |
| Modal view | `lib/features/session/presentation/views/log_session_view.dart` |
| Form widgets | `lib/features/session/presentation/widgets/` |
| Local data source | `lib/features/session/data/data_sources/session_local_data_source.dart` |
| Sync service | `lib/features/session/data/services/session_sync_service.dart` |
| Pending session | `lib/features/session/domain/entities/pending_session.dart` |
| Eligibility use case | `lib/features/session/domain/use_cases/check_eligibility_use_case.dart` |

---

## Testing

### Test Factories

```dart
// test/factories/pending_session_factory.dart
PendingSessionFactory.create({...})
PendingSessionFactory.valid()
```

### Key Test Cases

```dart
// ViewModel tests
test('init_userEligible_transitionsToReady')
test('init_tooManyProtocols_transitionsToIneligible')
test('submit_validForm_persistsLocallyAndSyncs')
test('submit_futureDate_returnsTimestampInFuture')
test('submit_dateTooOld_returnsDateTooOld')
test('submit_invalidDuration_returnsDurationMustBePositive')
test('submit_offline_persistsLocallyOnly')

// Sync service tests
test('sync_pendingSessions_pushesToRemote')
test('sync_serverError_retainsPendingSessions')
test('sync_success_removesPendingSessions')

// Widget tests
test('notesCounter_under100_hidden')
test('notesCounter_at100_visible')
test('notesCounter_at130_red')
test('submitButton_tapped_triggersHaptic')
```

---

## Acceptance Criteria

- [ ] Modal opens from Home screen protocol card button
- [ ] Modal opens from Progress screen grid cell tap
- [ ] Date pre-filled based on entry point
- [ ] Date picker restricts to past 7 days only
- [ ] Duration field accepts positive integers only
- [ ] Notes counter appears at 100+ chars, red at 130+
- [ ] Eligibility check on open shows upgrade prompt if ineligible
- [ ] Submit triggers light haptic feedback
- [ ] Submit persists to local storage immediately
- [ ] Sync triggered after local save
- [ ] Sync triggered on app launch
- [ ] Sync triggered on connectivity restored
- [ ] Failed syncs retry silently
- [ ] Success dismisses modal and shows toast
- [ ] Callback invoked on success for screen refresh
- [ ] Accessibility announcements for saving/success/error states
- [ ] Home and Progress screens read combined local data
- [ ] No visual distinction between synced and pending sessions