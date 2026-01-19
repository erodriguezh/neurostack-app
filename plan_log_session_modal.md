# Implementation Plan: Log Session Modal

**Spec:** `docs/specs/20260113180000_spec_log_session_modal.md`
**Pattern references:** `backdate_session_sheet.dart`, `protocol_detail_sheet.dart`, `HomeViewModel`, `LogSessionUseCase`

---

## Phase 1: Domain Layer Additions

### 1.1 Add `Session.DateTooOld` failure + domain validation [DONE]
- **Files:**
  - `lib/features/session/domain/failures/session_failures.dart` - failure constant
  - `lib/features/session/domain/entities/session_draft.dart` - INV-S4 validation
  - `lib/features/session/domain/entities/session.dart` - INV-S4 validation
  - `docs/specs/20260113151500_spec_session.md` - updated spec
- **Changes:**
  1. Added `dateTooOld` failure constant
  2. Added `maxBackdateDays = 7` constant to Session and SessionDraft
  3. Added INV-S4 validation: `completedAt.isBefore(currentTime - 7 days)` check
  4. Added tests: `withTooOldTimestamp`, `withExactlySevenDaysAgo`
  5. Updated session spec with INV-S4 rule
- **Spec ref:** INV-LSM2 → now enforced as INV-S4 at domain level

### 1.2 Create `CheckEligibilityUseCase` [DONE]
- **File:** `lib/features/session/domain/use_cases/check_eligibility_use_case.dart` (new)
- **Pattern:** Follow `lib/features/session/domain/use_cases/log_session_use_case.dart`
- **Purpose:** Gate modal open with `User.TooManyActiveProtocols` check
- **Dependencies:** `UserRepository`
- **Returns:** `Either<DomainFailure, Unit>`
- **Changes:**
  1. Created `CheckEligibilityParams` (userId, protocolId, currentTime)
  2. Implemented `execute()` - loads user, delegates to `User.canLogSession()`
  3. Added 5 unit tests covering all failure cases + success
- **Tests:** `test/domain/session/use_cases/check_eligibility_use_case_test.dart`

### 1.3 Create `PendingSession` entity [DONE]
- **File:** `lib/features/session/domain/entities/pending_session.dart` (new)
- **Pattern:** Follow `lib/features/session/domain/entities/session_draft.dart`
- **Fields:**
  - `localId` (client-generated UUID)
  - `userId` (for multi-account safety)
  - `draft` (`SessionDraft`)
  - `createdAt`
  - `retryCount`
- **Changes:**
  1. Created `PendingSession` entity with `create()` factory and `reconstitute()` for persistence
  2. Added `incrementRetry()` method for sync retry logic
  3. Added `SessionDraftFactory` and `PendingSessionFactory` for testing
  4. Added `TestConstants.pendingSession` for test data
  5. Added 12 unit tests covering create, reconstitute, incrementRetry, equality
- **Tests:** `test/domain/session/pending_session_test.dart`

---

## Phase 2: Data Layer - Offline-First Persistence

### 2.1 Create `PendingSessionDto` [DONE]
- **File:** `lib/features/session/data/dtos/pending_session_dto.dart` (new)
- **Pattern:** Follow `lib/features/session/data/dtos/session_insert_dto.dart`
- **Purpose:** JSON serialization for SharedPreferences storage
- **Changes:**
  1. Created `PendingSessionDto` with freezed/json_serializable + `@JsonSerializable(includeIfNull: false)`
  2. Added flattened SessionDraft fields (protocolId, completedAt, durationSeconds, notes)
  3. Added `toDomain()` using `SessionDraft.reconstitute()` and `PendingSession.reconstitute()`
  4. Added `fromDomain()` factory for serialization
  5. Added `SessionDraft.reconstitute()` factory to domain for persistence loading
  6. Added `PendingSessionDtoFactory` for test data generation
  7. Added 25 unit tests covering round-trip serialization + timestamp validation bypass
- **Review improvements:**
  - Runtime StateError check in `PendingSession.reconstitute` for negative retryCount (not assert)
  - Notes normalization in `SessionDraft.reconstitute` (trim + empty-to-null) for domain shape consistency
  - UTC timestamp storage in DTO (`toUtc().toIso8601String()`) for portability; converts to local on load
- **Tests:** `test/features/session/data/dtos/pending_session_dto_test.dart`

### 2.2 Create `SessionLocalDataSource` [DONE]
- **File:** `lib/features/session/data/data_sources/session_local_data_source.dart` (new)
- **Pattern:** Follow `lib/features/auth/data/cached_user_store.dart`, `lib/progress/data/cached_week_progress_store.dart`
- **Dependencies:** `SharedPreferences`
- **Methods:**
  - `savePendingSession(PendingSession)` - append to pending queue, upsert by localId
  - `getPendingSessions(userId)` → `List<PendingSession>` - with corrupt entry skipping
  - `removePendingSession(userId, localId)` - for post-sync cleanup
  - `upsertSyncedSessions(userId, List<Session>)` - merge with existing cache by ID
  - `listSessions(userId, {from?, to?})` → combined synced + pending, sorted descending
  - `clearPendingSessions(userId)` / `clearSyncedSessions(userId)` - cache management
  - `getSyncedSessions(userId)` → `List<Session>` - synced cache only
- **Storage keys:**
  - `pending_sessions_$userId`
  - `synced_sessions_$userId`
- **Changes:**
  1. Created `SessionLocalDataSource` with SharedPreferences persistence
  2. Implemented per-entry corrupt data handling (skip invalid, don't clear whole cache)
  3. Combined listing with date filtering and descending sort
  4. User-scoped storage keys for multi-account safety
  5. Added 32 unit tests covering all operations
- **Review improvements:**
  - Fail-fast in fromJson: `SessionDto` uses `_requiredStringFromJson` that throws `FormatException` on null/empty/non-String for `id` and `protocolId` fields — corrupt entries caught at parse time
  - UTC storage: `SessionDto.fromDomain()` uses `.toUtc().toIso8601String()` for timezone portability (matches `PendingSessionDto` pattern)
  - Simplified validation: Removed redundant empty id/protocolId checks from `toDomain()` since validation now happens at fromJson
  - Pending ID prefix: `pendingIdPrefix = 'pending:'` constant; `listSessions()` prefixes pending session IDs to prevent collision with server UUIDs
  - Self-healing at both levels: Corrupt entries filtered at `_loadSyncedDtos`/`_loadPendingDtos` (fromJson) and `getSyncedSessions`/`getPendingSessions` (toDomain) — ensures invalid data is removed regardless of failure point
- **Tests:** `test/features/session/data/data_sources/session_local_data_source_test.dart`

### 2.3 Create `SessionSyncService` [DONE]
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
- **Changes:**
  1. Created `SessionSyncService` with connectivity-aware background sync
  2. Implemented `init()` to attach connectivity listener via `ConnectivityService.statusStream`
  3. Implemented `sync()` - checks online + auth, pushes pending, removes on success
  4. Implemented `dispose()` to cancel connectivity subscription
  5. Added `_onConnectivityChanged()` callback - triggers sync when coming online
  6. Error handling: sync() never throws (called via unawaited), logs errors and keeps failed sessions in queue
  7. Duplicate submission prevention: removes pending immediately after successful remote create
  8. Added 17 unit tests covering sync flow, offline handling, error recovery, connectivity changes
- **Review improvements:**
  - Fixed duplicate submission risk: pending removed immediately after remote success before any state updates
  - Made sync() never throw: wrapped in try-catch since it's invoked via `unawaited()`
  - UTC consistency: Fixed `SessionInsertDto.fromDomain()` to use `.toUtc().toIso8601String()` for timestamp portability
- **Tests:** `test/features/session/data/services/session_sync_service_test.dart`

---

## Phase 3: Presentation Layer - Modal

### 3.1 Create `LogSessionState` sealed class [DONE]
- **File:** `lib/features/session/presentation/view_models/log_session_state.dart` (new)
- **Pattern:** Follow `lib/progress/progress_state.dart`
- **States:**
  - `LogSessionInitial`
  - `LogSessionReady`
  - `LogSessionSubmitting`
  - `LogSessionSuccess(Session session)`
  - `LogSessionError(DomainFailure failure)`
  - `LogSessionIneligible(DomainFailure failure)`
- **Changes:**
  1. Created sealed class with 6 state subclasses
  2. Added doc comments describing each state's purpose
  3. LogSessionSuccess holds Session for callback
  4. LogSessionError/LogSessionIneligible hold DomainFailure for UI messaging

### 3.2 Create `LogSessionViewModel` [DONE]
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
- **Changes:**
  1. Created `LogSessionViewModel` with form state ValueNotifiers
  2. Implemented `init()` with eligibility check via `CheckEligibilityUseCase`
  3. Implemented `submit()` with validation, pending session creation, and sync trigger
  4. Validation runs before submitting state change to prevent UI flicker
  5. Added 18 unit tests covering eligibility, validation, and submit flow

### 3.3 Create `LogSessionView` widget [DONE]
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
- **Changes:**
  1. Created `LogSessionView` with all form fields and state handling
  2. Added `AnimatedPadding` for keyboard inset handling
  3. Inline error banner for non-duration validation errors
  4. Character counter with proper visibility/color thresholds
  5. Accessibility announcements for saving/success/error states

### 3.4 Create `showLogSessionModal()` entry function [DONE]
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
- **Changes:**
  1. Created `showLogSessionModal()` entry function
  2. Constructs ViewModel with proper lifecycle (dispose on modal close)
  3. Uses `_StatefulLogSessionModal` wrapper for ViewModel lifecycle management
  4. Backdrop blur via `BackdropFilter` with 80% dim overlay

---

## Phase 4: Home Screen Integration

### 4.1 Add `LogSessionRequest` to state [DONE]
- **File:** `lib/home/home_state.dart`
- **Changes:**
  1. Added `LogSessionRequest` class with `protocolId` and `initialDate` fields
  2. Added doc comment explaining modal trigger flow
  3. Added `LogSessionRequest? logSessionRequest` to `HomeViewState`
  4. Updated `copyWith` with sentinel pattern (matches existing `banner`/`errorMessage` pattern)

### 4.2 Update `HomeViewModel.onLogSession()` [DONE]
- **File:** `lib/home/home_view_model.dart`
- **Current:** `lib/home/home_view_model.dart:116` — `onLogSession()` method
- **Changes:**
  1. Kept existing `user.canLogSession()` eligibility check
  2. Kept existing `TooManyActiveProtocols` → show deactivation modal
  3. Added else branch: when eligible, sets `logSessionRequest` in state with protocolId and current time
  4. Added `acknowledgeLogSessionRequest()` method at line 182 to clear request (follows pattern of other acknowledge methods)

### 4.3 Update `HomeView` to show modal [DONE]
- **Files:**
  - `lib/home/home_state.dart` — updated `LogSessionRequest` to hold `Protocol` instead of `protocolId`
  - `lib/home/home_view_model.dart` — updated `onLogSession()` to async, fetches Protocol and passes to request
  - `lib/home/home_view.dart` — simplified `_showLogSessionModal()`, added error handling
- **Changes:**
  1. Refactored `LogSessionRequest` to hold full `Protocol` object instead of just `protocolId` — avoids lookup in HomeView
  2. Updated `onLogSession()` to fetch Protocol via repository before setting request; shows toast on error
  3. Simplified `_showLogSessionModal()` to use `request.protocol` directly
  4. Added error toast if user ID cannot be resolved
  5. Added `_maybeShowDialogs()` trigger for `logSessionRequest`
  6. Call `showLogSessionModal()` with protocol from request
  7. In `onSessionLogged`: call `_viewModel.refresh()`
  8. Clear request via `acknowledgeLogSessionRequest()`

### 4.4 Update Home to read combined sessions [DONE]
- **File:** `lib/home/home_view_model.dart`
- **Current:** `lib/home/home_view_model.dart:230` — `_loadCards()` fetches from remote
- **Change:**
  - Inject `SessionLocalDataSource`
  - On load: if online, fetch remote + upsert to local
  - Read `loggedToday` from local combined sessions
- **Changes:**
  1. Added `SessionLocalDataSource` dependency to `HomeViewModel` constructor
  2. Updated `_loadCards()` to fetch remote sessions when online and upsert to local cache
  3. Read sessions from `SessionLocalDataSource.listSessions()` (combined synced + pending)
  4. Remote sync is best-effort — Home screen renders even if server unavailable
  5. Registered `SessionLocalDataSource` in `locator_config.dart` DI container
- **Refactoring (post-review):**
  1. Added `startOfDay`/`endOfDay` extensions to `DateTimeWeekExtension` with UTC preservation
  2. Updated `weekStart`/`weekEnd` to preserve UTC and use consistent precision
  3. DST-safe `endOfDay`: uses calendar-based next day (DateTime constructor) instead of 24h addition
  4. Replaced `debugPrint` with `Logger` in HomeViewModel for consistent logging infrastructure
  5. Added 4 unit tests for UTC preservation in date extensions

---

## Phase 5: Progress Screen Integration

### 5.1 Replace backdate sheet with modal [DONE]
- **File:** `lib/progress/progress_view.dart`
- **Current:** `lib/progress/progress_view.dart:268` — `_showLogSessionModal()` method
- **Changes:**
  1. Replaced `_showBackdateSheet()` with `_showLogSessionModal()`
  2. Resolves Protocol from `CachedProtocolStore` with repository fallback
  3. Resolves userId from AuthService (handles Online/Offline states)
  4. Shows error toast when user/protocol cannot be resolved
  5. Calls `showLogSessionModal()` with resolved protocol and cell's date
  6. In `onSessionLogged`: calls `_viewModel.refresh()` to update grid
- **Commits:**
  - `28dd690` feat(progress): replace backdate sheet with LogSessionModal
  - `a5fae9f` fix(progress): address review feedback for LogSessionModal integration

### 5.2 Add `onSessionLogged()` to ViewModel [DONE]
- **File:** `lib/progress/progress_view_model.dart`
- **Change:** Add method to update grid cell state
```dart
Future<void> onSessionLogged(Session session)
```
- **Changes:**
  1. Added `onSessionLogged(Session)` method that efficiently updates grid cell state
  2. Finds cell matching session's `completedAt` date using `_cellIndex()`
  3. Updates cell to `CellState.completed` and emits new state
  4. Persists update to `CachedWeekProgressStore`
  5. Updated `ProgressView` to use `onSessionLogged` instead of `refresh()`
  6. Added 5 unit tests covering: cell update, cache persistence, out-of-week handling, empty state handling, uninitialized state handling
- **Commits:**
  - `d71c396` feat(progress): add onSessionLogged method to ProgressViewModel

### 5.3 Update Progress to read combined sessions [DONE]
- **File:** `lib/progress/progress_view_model.dart`
- **Current:** `lib/progress/progress_view_model.dart:96` — `_loadWeek()` fetches from remote
- **Change:**
  - Inject `SessionLocalDataSource`
  - On load: if online, fetch remote + upsert to local
  - Read week sessions from local combined
- **Changes:**
  1. Added `SessionLocalDataSource` dependency to `ProgressViewModel` constructor
  2. Updated `_loadWeek()` to fetch remote sessions when online and upsert to local cache
  3. Read sessions from `SessionLocalDataSource.listSessions()` (combined synced + pending)
  4. Remote sync is best-effort — progress screen renders even if server unavailable
  5. Fixed offline mode bug: now shows active protocols even when no sessions exist for the week
  6. Added 4 unit tests for combined session behavior
- **Refactoring (post-review):**
  1. Extracted `_resolveProtocolNames()` method to DRY up duplicated protocol name resolution loop
- **Commits:**
  - `7dc112a` feat(progress): read combined sessions from SessionLocalDataSource
  - `91b5bca` fix(progress): address review feedback for combined sessions
  - `eb97da7` refactor(progress): extract _resolveProtocolNames method

### 5.4 Deprecate `backdateSession()` method [DONE]
- **File:** `lib/progress/progress_view_model.dart`
- **Current:** `lib/progress/progress_view_model.dart:57` — direct use case call
- **Change:** Remove or mark deprecated once modal is wired
- **Changes:**
  1. Removed `backdateSession()` public method (~66 lines) — no longer needed with LogSessionModal
  2. Removed `_logSessionUseCase` field and initialization (use case now only in LogSessionViewModel)
  3. Removed `_revertBackdate()` private helper (optimistic UI rollback, replaced by modal's pending session approach)
  4. Removed `_notifyOffline()` private helper (offline toast, modal handles offline-first differently)
  5. Removed unused `LogSessionUseCase` import
- **Commits:**
  - `9e9988d` refactor(progress): remove deprecated backdateSession method

---

## Phase 6: Sync Trigger Wiring

### 6.1 Extend `AppLifecycleService` [DONE]
- **File:** `lib/core/utils/app_lifecycle_service.dart`
- **Current:** Only has `restartApp()` method
- **Change:** Add lifecycle notifier
```dart
final ValueNotifier<AppLifecycleState?> lifecycle = ValueNotifier(null);
void setLifecycleState(AppLifecycleState state) => lifecycle.value = state;
```
- **Changes:**
  1. Added `lifecycle` ValueNotifier<AppLifecycleState?> initialized to null
  2. Added `setLifecycleState()` method to update the notifier
  3. Added 3 unit tests: initial state null, setLifecycleState updates value, multiple state changes
- **Commits:**
  - `cc11fd2` feat(lifecycle): add lifecycle notifier to AppLifecycleService

### 6.2 Add lifecycle observer widget [DONE]
- **File:** `lib/main.dart`
- **Change:** Add widget with `WidgetsBindingObserver` that forwards to `AppLifecycleService`
- **Changes:**
  1. Created `_AppLifecycleObserver` StatefulWidget wrapping the entire app
  2. Added `WidgetsBindingObserver` mixin to forward lifecycle state changes
  3. Guarded against DI not ready with try-catch for `ModuleNotFoundException`
  4. Forwards `didChangeAppLifecycleState` to `AppLifecycleService.setLifecycleState()`
- **Note:** Was implemented during Phase 6.1 as part of the same commit

### 6.3 Startup sync trigger [DONE]
- **File:** `lib/startup/startup_view_model.dart`
- **Current:** `lib/startup/startup_view_model.dart:33` — `initializeApp()` method
- **Change:** After auth init, call `locator<SessionSyncService>().sync()`
- **Changes:**
  1. Added `SessionSyncService` dependency lookup via locator
  2. Added `syncService.init()` after auth init to attach connectivity listeners
  3. Added `unawaited(syncService.sync())` to trigger immediate background sync of pending sessions
  4. Added `SessionSyncService.dispose()` in `_disposeServices()` to clean up listeners on retry
- **Commits:**
  - `f7bc2eb` feat(startup): add startup sync trigger for pending sessions

### 6.4 Connectivity + lifecycle listeners in sync service [DONE]
- **File:** `lib/features/session/data/services/session_sync_service.dart`
- **Change:** In `init()`, attach listeners:
  - `ConnectivityService.status` → on `online`, call `sync()`
  - `AppLifecycleService.lifecycle` → on `resumed`, call `sync()`
- **Note:** Already implemented as part of Phase 2.3 (Create SessionSyncService)
- **Implementation:**
  1. `_handleConnectivityChange()` method triggers `sync()` when `NetworkStatus.online`
  2. `_handleLifecycleChange()` method triggers `sync()` when `AppLifecycleState.resumed`
  3. Both listeners attached in `init()` and removed in `dispose()`
  4. Tests cover all lifecycle states (resumed, paused, inactive, detached) and connectivity transitions

---

## Phase 7: Dependency Injection

### 7.1 Register new modules [DONE]
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
- **Note:** All modules were registered incrementally during earlier phases:
  - `SessionLocalDataSource` registered in Phase 4.4
  - `SessionSyncService` registered in Phase 2.3 (with `appLifecycle` added in Phase 6.4)
  - `CheckEligibilityUseCase` registered in Phase 1.2

### 7.2 Update existing ViewModels [DONE]
- **Home:** Inject `SessionLocalDataSource` (done in Phase 4.4), uses `ProtocolRepository` for Protocol lookup
- **Progress:** Inject `SessionLocalDataSource` (done in Phase 5.3)
- **Note:** `CachedProtocolStore` injection in HomeViewModel was not needed — `ProtocolRepository` provides Protocol lookup

---

## Phase 8: Testing

### 8.1 Domain tests [DONE]
- **File:** `test/domain/session/use_cases/check_eligibility_use_case_test.dart`
- **Cases:**
  - User not found → failure
  - Onboarding not completed → failure
  - Protocol not in stack → failure
  - Too many active protocols → `User.TooManyActiveProtocols`
  - Eligible → `Right(unit)`
- **Note:** Tests were implemented during Phase 1.2 (5 tests, all passing)

### 8.2 Data layer tests [DONE]
- **File:** `test/features/session/data/data_sources/session_local_data_source_test.dart`
- **Cases:**
  - Save/load pending sessions round-trip
  - Corrupt JSON clears cache
  - `listSessions` merges synced + pending
  - Filter by date range
- **Note:** 32 tests implemented during Phase 2.2, all passing

- **File:** `test/features/session/data/services/session_sync_service_test.dart`
- **Cases:**
  - Offline → sync no-ops
  - No auth user → no-ops
  - Remote success → pending removed
  - Remote failure → pending retained
- **Note:** 17 tests implemented during Phase 2.3, all passing

### 8.3 ViewModel tests [DONE]
- **File:** `test/features/session/presentation/view_models/log_session_view_model_test.dart` (new)
- **Cases:**
  - `init` → eligible → `LogSessionReady` state
  - `init` → passes correct params to `CheckEligibilityUseCase`
  - `init` → too many protocols → `LogSessionIneligible` state
  - `init` → other failure → `LogSessionError` state
  - Date clamping: future date → clamps to today
  - Date clamping: too old date → clamps to oldest allowed (7 days ago)
  - `submit` → duration 0 → error with haptic + toast
  - `submit` → negative duration → error with haptic + toast
  - `submit` → valid data → saves pending session with correct content
  - `submit` → valid data → triggers sync
  - `submit` → valid data → emits `LogSessionSuccess` with session
  - `submit` with duration → includes duration in session
  - `submit` with notes → includes notes in session
  - Form state: `selectedDate`, `durationMinutes`, `notes` notifiers update correctly
  - Submit guards: no-op when initial/ineligible/submitting/already-success
  - Error handling: local save failure → error with toast
- **Note:** 24 tests implemented, all passing

### 8.4 Widget tests [DONE]
- **File:** `test/features/session/presentation/views/log_session_view_test.dart` (new)
- **Cases:**
  - Notes counter hidden < 100
  - Notes counter visible >= 100
  - Notes counter red >= 130
  - Submit button loading state
  - Duration field error display
- **Changes:**
  1. Created widget test file with 9 tests covering all acceptance criteria
  2. Added test helpers for building widget under test with mock dependencies
  3. Fixed bug in `log_session_view.dart`: error code check was `'Session.InvalidDuration'` instead of `'Session.DurationMustBePositive'`
  4. Tests verify character counter visibility, color thresholds, and border styling
- **Commits:** f545ac7, e89e53a

### 8.5 Test factories [DONE]
- **Files:**
  - `test/factories/pending_session_factory.dart` (new)
  - `test/factories/session_draft_factory.dart` (new)
  - `test/factories/dtos/pending_session_dto_factory.dart` (new)
- **Pattern:** Follow `test/factories/session_factory.dart`
- **Changes:**
  1. Created `PendingSessionFactory` with `create()`, `withRetryCount()`, `createBatch()` methods
  2. Created `SessionDraftFactory` with `create()`, `valid()` methods
  3. Created `PendingSessionDtoFactory` with valid/invalid variations and JSON helpers
  4. All factories exported via barrel files (`factories.dart`, `dtos/dtos.dart`)
- **Note:** Factories were created incrementally during Phases 1.3 and 2.1 as part of test-driven development

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