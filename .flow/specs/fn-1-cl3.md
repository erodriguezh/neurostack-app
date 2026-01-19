# Implementation Plan: Log Session Modal

**Spec:** `docs/specs/20260113180000_spec_log_session_modal.md`
**Pattern references:** `backdate_session_sheet.dart`, `protocol_detail_sheet.dart`, `HomeViewModel`, `LogSessionUseCase`

---

## Phase 1: Domain Layer Additions

### 1.1 Add `Session.DateTooOld` failure
- **File:** `lib/features/session/domain/failures/session_failures.dart`
- **Change:** Add new failure constant
```dart
static const dateTooOld = DomainFailure(
  code: 'Session.DateTooOld',
  message: 'Cannot log sessions more than 7 days in the past',
);
```
- **Spec ref:** INV-LSM2 in `docs/specs/20260113180000_spec_log_session_modal.md`

### 1.2 Create `CheckEligibilityUseCase`
- **File:** `lib/features/session/domain/use_cases/check_eligibility_use_case.dart` (new)
- **Pattern:** Follow `lib/features/session/domain/use_cases/log_session_use_case.dart`
- **Purpose:** Gate modal open with `User.TooManyActiveProtocols` check
- **Dependencies:** `UserRepository`
- **Returns:** `Either<DomainFailure, Unit>`

### 1.3 Create `PendingSession` entity
- **File:** `lib/features/session/domain/entities/pending_session.dart` (new)
- **Pattern:** Follow `lib/features/session/domain/entities/session_draft.dart`
- **Fields:**
  - `localId` (client-generated UUID)
  - `userId` (for multi-account safety)
  - `draft` (`SessionDraft`)
  - `createdAt`
  - `retryCount`

---

## Phase 2: Data Layer - Offline-First Persistence

### 2.1 Create `PendingSessionDto`
- **File:** `lib/features/session/data/dtos/pending_session_dto.dart` (new)
- **Pattern:** Follow `lib/features/session/data/dtos/session_insert_dto.dart`
- **Purpose:** JSON serialization for SharedPreferences storage

### 2.2 Create `SessionLocalDataSource`
- **File:** `lib/features/session/data/data_sources/session_local_data_source.dart` (new)
- **Pattern:** Follow `lib/features/auth/data/cached_user_store.dart`, `lib/progress/data/cached_week_progress_store.dart`
- **Dependencies:** `SharedPreferences`
- **Methods:**
  - `savePendingSession(PendingSession)`
  - `getPendingSessions(userId)` → `List<PendingSession>`
  - `removePendingSession(userId, localId)`
  - `upsertSyncedSessions(userId, List<Session>)`
  - `listSessions(userId, {from?, to?})` → combined synced + pending
- **Storage keys:**
  - `pending_sessions_$userId`
  - `synced_sessions_$userId`

### 2.3 Create `SessionSyncService`
- **File:** `lib/features/session/data/services/session_sync_service.dart` (new)
- **Pattern:** Service pattern similar to `lib/features/auth/data/auth_service.dart`
- **Dependencies:**
  - `SessionLocalDataSource`
  - `SessionRemoteDataSource` (existing: `lib/features/session/data/data_sources/session_remote_data_source.dart`)
  - `ConnectivityService` (existing: `lib/core/utils/connectivity/connectivity_service.dart`)
  - `DataSourceAbstraction` (for auth user)
- **Methods:**
  - `init()` — attach connectivity listener
  - `sync()` — push pending sessions to remote
  - `dispose()` — detach listeners
- **Sync algorithm:**
  1. Check online + authenticated
  2. Load pending sessions for current user
  3. For each: call `SessionRemoteDataSource.createSession()`
  4. On success: remove from pending queue
  5. On failure: silent retry (keep in queue)

---

## Phase 3: Presentation Layer - Modal

### 3.1 Create `LogSessionState` sealed class
- **File:** `lib/features/session/presentation/view_models/log_session_state.dart` (new)
- **Pattern:** Follow `lib/progress/progress_state.dart`
- **States:**
  - `LogSessionInitial`
  - `LogSessionReady`
  - `LogSessionSubmitting`
  - `LogSessionSuccess(Session session)`
  - `LogSessionError(DomainFailure failure)`
  - `LogSessionIneligible(DomainFailure failure)`

### 3.2 Create `LogSessionViewModel`
- **File:** `lib/features/session/presentation/view_models/log_session_view_model.dart` (new)
- **Pattern:** Follow `lib/home/home_view_model.dart`, `lib/progress/progress_view_model.dart`
- **Dependencies:**
  - `Protocol protocol`
  - `DateTime initialDate`
  - `String userId`
  - `CheckEligibilityUseCase`
  - `SessionLocalDataSource`
  - `SessionSyncService`
  - `NotifyService` (existing: `lib/core/utils/internal_notification/notify_service.dart`)
- **Form state (separate ValueNotifier):**
  - `selectedDate`
  - `durationMinutes` (nullable int)
  - `notes` (String)
- **Methods:**
  - `init()` — run eligibility check
  - `submit()` — validate, save pending, trigger sync
  - `dispose()`
- **Validation (on submit):**
  - INV-LSM1: `selectedDate <= now`
  - INV-LSM2: `selectedDate >= now - 7 days`
  - INV-LSM3: duration > 0 if provided
- **Submit flow:**
  1. Light haptic (`HapticFeedback.lightImpact`)
  2. Announce "Saving session"
  3. Validate form
  4. Create `SessionDraft`
  5. Create `PendingSession` with client UUID
  6. Save to `SessionLocalDataSource`
  7. Trigger `SessionSyncService.sync()`
  8. Create `Session.reconstitute()` for callback
  9. Set `LogSessionSuccess`
  10. Toast + haptic success

### 3.3 Create `LogSessionView` widget
- **File:** `lib/features/session/presentation/views/log_session_view.dart` (new)
- **Pattern:** Follow `lib/progress/widgets/backdate_session_sheet.dart`, `lib/library/widgets/protocol_detail_sheet.dart`
- **UI spec:** `docs/best_practices/design/screen-prompts/05-log-session-modal.md`
- **Components:**
  - Drag indicator (white/20 pill, 40x4px)
  - Header row: title + close button
  - Protocol context label (brand sky)
  - Date field → native picker, constrained [now-7d, now]
  - Duration field → numeric keyboard, "min" suffix, error styling
  - Notes field → multiline, max 140 chars
    - Counter hidden < 100
    - Counter visible >= 100
    - Counter red >= 130
  - Submit CTA → use `AppPrimaryCta` (existing: `lib/core/ui/widgets/app_primary_cta.dart`)
- **State handling:**
  - `LogSessionIneligible` → show upgrade prompt
  - `LogSessionSubmitting` → button loading state
  - `LogSessionSuccess` → call `onSessionLogged`, pop modal
  - `LogSessionError` → show error, announce message
- **Accessibility:**
  - `SemanticsService.announce()` for saving/success/error

### 3.4 Create `showLogSessionModal()` entry function
- **File:** `lib/features/session/presentation/log_session_modal.dart` (new)
- **Signature:**
```dart
Future<void> showLogSessionModal(
  BuildContext context, {
  required Protocol protocol,
  DateTime? initialDate,
  required void Function(Session session) onSessionLogged,
});
```
- **Implementation:**
  - Construct `LogSessionViewModel` via locator
  - Call `showModalBottomSheet` with:
    - `isScrollControlled: true`
    - `backgroundColor: Colors.transparent`
    - Height factor ~0.85
    - Backdrop blur + 80% dim overlay

---

## Phase 4: Home Screen Integration

### 4.1 Add `LogSessionRequest` to state
- **File:** `lib/home/home_state.dart`
- **Change:** Add request model + state field
```dart
class LogSessionRequest {
  const LogSessionRequest({required this.protocolId, required this.initialDate});
  final String protocolId;
  final DateTime initialDate;
}
```
- Add `LogSessionRequest? logSessionRequest` to `HomeViewState`
- Update `copyWith` with sentinel pattern

### 4.2 Update `HomeViewModel.onLogSession()`
- **File:** `lib/home/home_view_model.dart`
- **Current:** `lib/home/home_view_model.dart:166` — stub that only checks eligibility
- **Change:**
  1. Run `user.canLogSession()` (existing logic)
  2. If `TooManyActiveProtocols` → show deactivation modal (existing)
  3. If eligible → set `logSessionRequest` in state
- **Add:** `acknowledgeLogSessionRequest()` method to clear request

### 4.3 Update `HomeView` to show modal
- **File:** `lib/home/home_view.dart`
- **Current:** `lib/home/home_view.dart:77` — `_maybeShowDialogs()` method
- **Change:** Extend to detect `logSessionRequest`
  1. Resolve `Protocol` from `CachedProtocolStore` or repository
  2. Call `showLogSessionModal()`
  3. In `onSessionLogged`: call `_viewModel.refresh()`
  4. Clear request via `acknowledgeLogSessionRequest()`

### 4.4 Update Home to read combined sessions
- **File:** `lib/home/home_view_model.dart`
- **Current:** `lib/home/home_view_model.dart:230` — `_loadCards()` fetches from remote
- **Change:**
  - Inject `SessionLocalDataSource`
  - On load: if online, fetch remote + upsert to local
  - Read `loggedToday` from local combined sessions

---

## Phase 5: Progress Screen Integration

### 5.1 Replace backdate sheet with modal
- **File:** `lib/progress/progress_view.dart`
- **Current:** `lib/progress/progress_view.dart:134` — `_showBackdateSheet()` method
- **Change:**
  1. Resolve `Protocol` from cached store
  2. Call `showLogSessionModal()` with cell's date
  3. In `onSessionLogged`: call `_viewModel.onSessionLogged(session)`

### 5.2 Add `onSessionLogged()` to ViewModel
- **File:** `lib/progress/progress_view_model.dart`
- **Change:** Add method to update grid cell state
```dart
Future<void> onSessionLogged(Session session)
```
- Implementation:
  - Update cell to `CellState.completed`
  - Persist to `CachedWeekProgressStore`

### 5.3 Update Progress to read combined sessions
- **File:** `lib/progress/progress_view_model.dart`
- **Current:** `lib/progress/progress_view_model.dart:96` — `_loadWeek()` fetches from remote
- **Change:**
  - Inject `SessionLocalDataSource`
  - On load: if online, fetch remote + upsert to local
  - Read week sessions from local combined

### 5.4 Deprecate `backdateSession()` method
- **File:** `lib/progress/progress_view_model.dart`
- **Current:** `lib/progress/progress_view_model.dart:57` — direct use case call
- **Change:** Remove or mark deprecated once modal is wired

---

## Phase 6: Sync Trigger Wiring

### 6.1 Extend `AppLifecycleService`
- **File:** `lib/core/utils/app_lifecycle_service.dart`
- **Current:** Only has `restartApp()` method
- **Change:** Add lifecycle notifier
```dart
final ValueNotifier<AppLifecycleState?> lifecycle = ValueNotifier(null);
void setLifecycleState(AppLifecycleState state) => lifecycle.value = state;
```

### 6.2 Add lifecycle observer widget
- **File:** `lib/main.dart`
- **Change:** Add widget with `WidgetsBindingObserver` that forwards to `AppLifecycleService`

### 6.3 Startup sync trigger
- **File:** `lib/startup/startup_view_model.dart`
- **Current:** `lib/startup/startup_view_model.dart:33` — `initializeApp()` method
- **Change:** After auth init, call `locator<SessionSyncService>().sync()`

### 6.4 Connectivity + lifecycle listeners in sync service
- **File:** `lib/features/session/data/services/session_sync_service.dart`
- **Change:** In `init()`, attach listeners:
  - `ConnectivityService.status` → on `online`, call `sync()`
  - `AppLifecycleService.lifecycle` → on `resumed`, call `sync()`

---

## Phase 7: Dependency Injection

### 7.1 Register new modules
- **File:** `lib/config/locator_config.dart`
- **Add:**
```dart
Module<SessionLocalDataSource>(
  builder: () => SessionLocalDataSource(locator<SharedPreferences>()),
),
Module<SessionSyncService>(
  builder: () => SessionSyncService(
    local: locator<SessionLocalDataSource>(),
    remote: locator<SessionRemoteDataSource>(),
    connectivity: locator<ConnectivityService>(),
    dataSource: locator<DataSourceAbstraction>(),
  ),
),
Module<CheckEligibilityUseCase>(
  builder: () => CheckEligibilityUseCase(
    userRepository: locator<UserRepository>(),
  ),
),
```

### 7.2 Update existing ViewModels
- **Home:** Inject `SessionLocalDataSource`, `CachedProtocolStore`
- **Progress:** Inject `SessionLocalDataSource`

---

## Phase 8: Testing

### 8.1 Domain tests
- **File:** `test/domain/session/use_cases/check_eligibility_use_case_test.dart` (new)
- **Cases:**
  - User not found → failure
  - Onboarding not completed → failure
  - Protocol not in stack → failure
  - Too many active protocols → `User.TooManyActiveProtocols`
  - Eligible → `Right(unit)`

### 8.2 Data layer tests
- **File:** `test/features/session/data/session_local_data_source_test.dart` (new)
- **Cases:**
  - Save/load pending sessions round-trip
  - Corrupt JSON clears cache
  - `listSessions` merges synced + pending
  - Filter by date range

- **File:** `test/features/session/data/session_sync_service_test.dart` (new)
- **Cases:**
  - Offline → sync no-ops
  - No auth user → no-ops
  - Remote success → pending removed
  - Remote failure → pending retained

### 8.3 ViewModel tests
- **File:** `test/features/session/presentation/log_session_view_model_test.dart` (new)
- **Cases:**
  - `init` → eligible → `Ready`
  - `init` → too many protocols → `Ineligible`
  - `submit` → future date → error
  - `submit` → date too old → error
  - `submit` → duration 0 → error
  - `submit` → success → saves pending, triggers sync

### 8.4 Widget tests
- **File:** `test/features/session/presentation/log_session_view_test.dart` (new)
- **Cases:**
  - Notes counter hidden < 100
  - Notes counter visible >= 100
  - Notes counter red >= 130
  - Submit button loading state
  - Duration field error display

### 8.5 Test factories
- **File:** `test/factories/pending_session_factory.dart` (new)
- **Pattern:** Follow `test/factories/session_factory.dart`

---

## File Summary

### New Files (14)
| File | Purpose |
|------|---------|
| `lib/features/session/domain/entities/pending_session.dart` | Offline queue entity |
| `lib/features/session/domain/use_cases/check_eligibility_use_case.dart` | Modal open gate |
| `lib/features/session/data/dtos/pending_session_dto.dart` | JSON serialization |
| `lib/features/session/data/data_sources/session_local_data_source.dart` | Local persistence |
| `lib/features/session/data/services/session_sync_service.dart` | Background sync |
| `lib/features/session/presentation/view_models/log_session_state.dart` | Modal state |
| `lib/features/session/presentation/view_models/log_session_view_model.dart` | Modal logic |
| `lib/features/session/presentation/views/log_session_view.dart` | Modal UI |
| `lib/features/session/presentation/log_session_modal.dart` | Entry function |
| `test/domain/session/use_cases/check_eligibility_use_case_test.dart` | Use case tests |
| `test/features/session/data/session_local_data_source_test.dart` | Data source tests |
| `test/features/session/data/session_sync_service_test.dart` | Sync service tests |
| `test/features/session/presentation/log_session_view_model_test.dart` | ViewModel tests |
| `test/factories/pending_session_factory.dart` | Test factory |

### Modified Files (10)
| File | Changes |
|------|---------|
| `lib/features/session/domain/failures/session_failures.dart` | Add `dateTooOld` |
| `lib/home/home_state.dart` | Add `LogSessionRequest` |
| `lib/home/home_view_model.dart` | Update `onLogSession()`, inject deps |
| `lib/home/home_view.dart` | Show modal on request |
| `lib/progress/progress_view.dart` | Replace backdate sheet |
| `lib/progress/progress_view_model.dart` | Add `onSessionLogged()`, inject deps |
| `lib/core/utils/app_lifecycle_service.dart` | Add lifecycle notifier |
| `lib/startup/startup_view_model.dart` | Add sync trigger |
| `lib/config/locator_config.dart` | Register new modules |
| `lib/main.dart` | Add lifecycle observer widget |

---

## Implementation Order (Recommended)

1. **Domain additions** (failures, use case, entity) — no dependencies
2. **Data layer** (DTOs, local data source) — needs domain
3. **Sync service** — needs data layer
4. **Presentation** (state, ViewModel, View, modal) — needs all above
5. **DI registration** — needs all modules defined
6. **Home integration** — needs modal
7. **Progress integration** — needs modal
8. **Sync triggers** (lifecycle, startup) — needs sync service
9. **Tests** — can be written in parallel with implementation