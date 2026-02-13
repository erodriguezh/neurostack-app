import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../../core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import '../../../../core/utils/internal_notification/notify_service.dart';
import '../../../../core/utils/internal_notification/toast/toast_event.dart';
import '../../../protocol/domain/entities/protocol.dart';
import '../../data/data_sources/session_local_data_source.dart';
import '../../data/services/session_sync_service.dart';
import '../../domain/entities/pending_session.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_draft.dart';
import '../../domain/use_cases/check_eligibility_use_case.dart';
import '../../domain/value_objects/session_duration.dart';
import '../../../user/domain/failures/user_failures.dart';
import 'log_session_state.dart';

/// ViewModel for the Log Session Modal.
///
/// Manages form state, validation, and submission for logging sessions.
/// Supports offline-first architecture by saving to local storage first
/// and triggering background sync.
///
/// Pattern: Follows [HomeViewModel] and [ProgressViewModel].
class LogSessionViewModel {
  LogSessionViewModel({
    required Protocol protocol,
    required DateTime initialDate,
    required String userId,
    required CheckEligibilityUseCase checkEligibilityUseCase,
    required SessionLocalDataSource sessionLocalDataSource,
    required SessionSyncService sessionSyncService,
    required NotifyService notifyService,
    Uuid? uuid,
  }) : _protocol = protocol,
       _userId = userId,
       _checkEligibilityUseCase = checkEligibilityUseCase,
       _sessionLocalDataSource = sessionLocalDataSource,
       _sessionSyncService = sessionSyncService,
       _notifyService = notifyService,
       _uuid = uuid ?? const Uuid() {
    // Initialize form with provided date, clamped to valid range
    _selectedDate = ValueNotifier(_clampDate(initialDate));
  }

  final Protocol _protocol;
  final String _userId;
  final CheckEligibilityUseCase _checkEligibilityUseCase;
  final SessionLocalDataSource _sessionLocalDataSource;
  final SessionSyncService _sessionSyncService;
  final NotifyService _notifyService;
  final Uuid _uuid;

  /// Current modal state (eligibility, submission status).
  final ValueNotifier<LogSessionState> state = ValueNotifier(
    const LogSessionInitial(),
  );

  // ---------------------------------------------------------------------------
  // Form State (separate ValueNotifiers for fine-grained rebuilds)
  // ---------------------------------------------------------------------------

  /// Selected date for the session.
  late final ValueNotifier<DateTime> _selectedDate;

  /// Duration in minutes (nullable - field is optional).
  final ValueNotifier<int?> _durationMinutes = ValueNotifier(null);

  /// Notes text (empty string by default).
  final ValueNotifier<String> _notes = ValueNotifier('');

  /// Public accessors for form state (read-only from UI perspective).
  ValueNotifier<DateTime> get selectedDate => _selectedDate;
  ValueNotifier<int?> get durationMinutes => _durationMinutes;
  ValueNotifier<String> get notes => _notes;

  /// The protocol being logged against.
  Protocol get protocol => _protocol;

  /// The current user ID.
  String get userId => _userId;

  bool _isDisposed = false;

  // ---------------------------------------------------------------------------
  // Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Initializes the view model and runs eligibility check.
  ///
  /// Must be called once after construction. Sets state to:
  /// - [LogSessionReady] if user is eligible
  /// - [LogSessionIneligible] if user cannot log sessions
  Future<void> init() async {
    if (_isDisposed) return;

    final result = await _checkEligibilityUseCase.execute(
      CheckEligibilityParams(
        userId: _userId,
        protocolId: _protocol.id,
      ),
    );

    if (_isDisposed) return;

    result.fold(
      (failure) {
        // BUG D fix: Only TooManyActiveProtocols -> LogSessionIneligible
        // Other failures should be LogSessionError
        if (failure.code == UserFailures.tooManyActiveProtocols.code) {
          state.value = LogSessionIneligible(failure);
        } else {
          state.value = LogSessionError(failure);
        }
      },
      (_) => state.value = const LogSessionReady(),
    );
  }

  /// Disposes resources held by the view model.
  void dispose() {
    _isDisposed = true;
    state.dispose();
    _selectedDate.dispose();
    _durationMinutes.dispose();
    _notes.dispose();
  }

  // ---------------------------------------------------------------------------
  // Form Updates
  // ---------------------------------------------------------------------------

  /// Updates the selected date, clamping to valid range [now-7d, now].
  void updateSelectedDate(DateTime date) {
    if (_isDisposed) return;
    _selectedDate.value = _clampDate(date);
  }

  /// Updates the duration in minutes (null to clear).
  void updateDurationMinutes(int? minutes) {
    if (_isDisposed) return;
    _durationMinutes.value = minutes;
  }

  /// Updates the notes text.
  void updateNotes(String text) {
    if (_isDisposed) return;
    _notes.value = text;
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  /// Submits the session form.
  ///
  /// Flow:
  /// 1. Light haptic feedback
  /// 2. Validate form (INV-LSM1, INV-LSM2, INV-LSM3)
  /// 3. Transition to submitting state (view handles accessibility announce)
  /// 4. Create [PendingSession] with client UUID
  /// 5. Save to [SessionLocalDataSource]
  /// 6. Trigger [SessionSyncService.sync()]
  /// 7. Create [Session.reconstitute()] for callback
  /// 8. Set [LogSessionSuccess]
  /// 9. Toast + haptic success
  Future<void> submit() async {
    if (_isDisposed) return;

    final currentState = state.value;
    // Block submit if state is LogSessionInitial (pre-init submit prevention)
    if (currentState is LogSessionInitial) return;
    if (currentState is LogSessionSubmitting) return;
    if (currentState is LogSessionIneligible) return;
    // Block submit after success to prevent duplicate saves if modal doesn't close immediately
    if (currentState is LogSessionSuccess) return;

    // 1. Light haptic feedback
    _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.lightImpact);

    final now = DateTime.now();
    final selectedDateValue = _selectedDate.value;
    final durationMinutesValue = _durationMinutes.value;
    final notesValue = _notes.value;

    // 2. Validate duration if provided (before entering submitting state)
    SessionDuration? duration;
    if (durationMinutesValue != null) {
      final durationResult = SessionDuration.create(
        Duration(minutes: durationMinutesValue),
      );
      final extracted = durationResult.fold(
        (failure) {
          // INV-LSM3: duration > 0 if provided
          if (_isDisposed) return null;
          state.value = LogSessionError(failure);
          _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.error);
          _notifyService.setToastEvent(ToastEventError(message: failure.message));
          return null;
        },
        (d) => d,
      );
      if (extracted == null) return;
      duration = extracted;
    }

    // 3. Create SessionDraft with validation (INV-LSM1, INV-LSM2)
    // Validate before entering submitting state
    final normalizedNow = _normalizeNowForValidation(now);
    final normalizedCompletedAt = _normalizeCompletedAt(selectedDateValue, now);
    final draftResult = SessionDraft.create(
      protocolId: _protocol.id,
      completedAt: normalizedCompletedAt,
      currentTime: normalizedNow,
      duration: duration,
      notes: notesValue.isNotEmpty ? notesValue : null,
    );

    final draft = draftResult.fold(
      (failure) {
        if (_isDisposed) return null;
        state.value = LogSessionError(failure);
        _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.error);
        _notifyService.setToastEvent(ToastEventError(message: failure.message));
        return null;
      },
      (d) => d,
    );
    if (draft == null) return;

    // 4. Transition to submitting state (view handles accessibility announce)
    // Only enter this state after validation passes
    state.value = const LogSessionSubmitting();

    // 5. Create PendingSession with client UUID (validation already passed)
    final localId = _uuid.v4();
    final pending = PendingSession.create(
      localId: localId,
      userId: _userId,
      draft: draft,
      createdAt: now,
    );

    // 6. Save to local data source
    try {
      await _sessionLocalDataSource.savePendingSession(pending);
    } catch (e) {
      if (_isDisposed) return;
      state.value = const LogSessionError(
        DomainFailure(
          code: 'Session.LocalSaveFailed',
          message: 'Unable to save session locally',
        ),
      );
      _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.error);
      _notifyService.setToastEvent(
        ToastEventError(message: 'Unable to save session'),
      );
      return;
    }

    // 7. Trigger background sync (fire and forget)
    // The sync service guards against concurrent syncs and offline state
    unawaited(_sessionSyncService.sync());

    // 8. Create Session for callback (reconstitute with pending: prefix)
    final session = Session.reconstitute(
      id: '${SessionLocalDataSource.pendingIdPrefix}$localId',
      protocolId: draft.protocolId,
      completedAt: draft.completedAt,
      duration: draft.duration,
      notes: draft.notes,
    );

    // 9. Set success state and notify
    if (_isDisposed) return;
    state.value = LogSessionSuccess(session);
    _notifyService.setHapticFeedbackEvent(HapticFeedbackEvent.success);
    _notifyService.setToastEvent(
      ToastEventSuccess(message: 'Session logged'),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Clamps a date to the valid range [now - 7 days, now].
  DateTime _clampDate(DateTime date) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final oldestAllowed = startOfToday.subtract(
      const Duration(days: SessionDraft.maxBackdateDays),
    );

    if (date.isBefore(oldestAllowed)) {
      return oldestAllowed;
    }
    if (date.isAfter(startOfToday)) {
      return startOfToday;
    }
    return date;
  }

  /// BUG A fix: Normalizes "now" for validation.
  ///
  /// If current time is past midday, returns midday of today.
  /// Otherwise, returns the actual current time.
  ///
  /// This fixes morning "today" logging failures where selecting "today"
  /// at 9am would fail because midday (12:00) > 9am.
  DateTime _normalizeNowForValidation(DateTime now) {
    final midday = DateTime(now.year, now.month, now.day, 12);
    if (now.isAfter(midday) || now.isAtSameMomentAs(midday)) {
      return midday;
    }
    return now;
  }

  /// BUG B fix: Normalizes completedAt for storage.
  ///
  /// Uses midday (12:00) of the selected day to avoid timezone edge cases,
  /// but caps to the actual current time if midday would be in the future.
  ///
  /// This fixes "7 days ago" boundary being time-sensitive: selecting a date
  /// exactly 7 days ago at 9am should work, even though midday 7 days ago
  /// might be beyond the exact 168-hour window.
  DateTime _normalizeCompletedAt(DateTime selectedDay, DateTime now) {
    final midday = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 12);
    if (midday.isAfter(now)) {
      return now;
    }
    return midday;
  }
}
