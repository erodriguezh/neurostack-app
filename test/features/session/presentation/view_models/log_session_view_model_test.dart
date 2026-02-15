import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/utils/internal_notification/haptic_feedback/haptic_feedback_listener.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/failures/session_failures.dart';
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';
import 'package:neurostack/features/session/presentation/view_models/log_session_state.dart';
import 'package:neurostack/features/session/presentation/view_models/log_session_view_model.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/protocol_factory.dart';
import '../../../../mocks/mock_services.dart';

// Fakes for registerFallbackValue
class FakeCheckEligibilityParams extends Fake
    implements CheckEligibilityParams {}

class FakePendingSession extends Fake implements PendingSession {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeCheckEligibilityParams());
    registerFallbackValue(FakePendingSession());
  });

  group('LogSessionViewModel', () {
    LogSessionViewModel? viewModel;
    late MockCheckEligibilityUseCase mockCheckEligibility;
    late MockSessionLocalDataSource mockLocalDataSource;
    late MockSessionSyncService mockSyncService;
    late MockNotifyService mockNotifyService;
    late MockUuid mockUuid;

    setUp(() {
      mockCheckEligibility = MockCheckEligibilityUseCase();
      mockLocalDataSource = MockSessionLocalDataSource();
      mockSyncService = MockSessionSyncService();
      mockNotifyService = MockNotifyService();
      mockUuid = MockUuid();

      // Default mock setup for NotifyService (void methods use thenAnswer)
      when(
        () => mockNotifyService.setHapticFeedbackEvent(any()),
      ).thenAnswer((_) {});
      when(() => mockNotifyService.setToastEvent(any())).thenAnswer((_) {});
    });

    LogSessionViewModel createViewModel({
      DateTime? initialDate,
      String? userId,
    }) {
      return LogSessionViewModel(
        protocol: ProtocolFactory.reconstitute(),
        initialDate: initialDate ?? DateTime.now(),
        userId: userId ?? TestConstants.user.id,
        checkEligibilityUseCase: mockCheckEligibility,
        sessionLocalDataSource: mockLocalDataSource,
        sessionSyncService: mockSyncService,
        notifyService: mockNotifyService,
        uuid: mockUuid,
      );
    }

    tearDown(() {
      viewModel?.dispose();
    });

    group('init', () {
      test('init_whenEligible_setsLogSessionReadyState', () async {
        // Arrange
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
        viewModel = createViewModel();

        // Act
        await viewModel!.init();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionReady>());
      });

      test('init_passesCorrectParamsToCheckEligibility', () async {
        // Arrange
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
        viewModel = createViewModel();

        // Act
        await viewModel!.init();

        // Assert - capture and verify params
        final captured =
            verify(
                  () => mockCheckEligibility.execute(captureAny()),
                ).captured.single
                as CheckEligibilityParams;

        expect(captured.userId, TestConstants.user.id);
        expect(captured.protocolId, viewModel!.protocol.id);
      });

      test('init_whenTooManyProtocols_setsLogSessionIneligibleState', () async {
        // Arrange
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => left(UserFailures.tooManyActiveProtocols));
        viewModel = createViewModel();

        // Act
        await viewModel!.init();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionIneligible>());
        final state = viewModel!.state.value as LogSessionIneligible;
        expect(state.failure, UserFailures.tooManyActiveProtocols);
      });

      test('init_whenOtherFailure_setsLogSessionErrorState', () async {
        // Arrange
        const otherFailure = DomainFailure(
          code: 'User.NotFound',
          message: 'User not found',
        );
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => left(otherFailure));
        viewModel = createViewModel();

        // Act
        await viewModel!.init();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionError>());
        final state = viewModel!.state.value as LogSessionError;
        expect(state.failure.code, 'User.NotFound');
      });
    });

    group('date clamping', () {
      setUp(() {
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test('initialDate_clampsFutureDateToToday', () async {
        // Arrange - The view model clamps dates to prevent future dates
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 5));
        viewModel = createViewModel(initialDate: futureDate);
        await viewModel!.init();

        // Assert - date is clamped to today (start of day)
        final startOfToday = DateTime(now.year, now.month, now.day);
        expect(viewModel!.selectedDate.value.year, startOfToday.year);
        expect(viewModel!.selectedDate.value.month, startOfToday.month);
        expect(viewModel!.selectedDate.value.day, startOfToday.day);
      });

      test('initialDate_clampsTooOldDateToOldestAllowed', () async {
        // Arrange
        final now = DateTime.now();
        final tooOldDate = now.subtract(const Duration(days: 10));
        viewModel = createViewModel(initialDate: tooOldDate);
        await viewModel!.init();

        // Assert - date is clamped to oldest allowed (7 days ago)
        final selected = viewModel!.selectedDate.value;

        // Should be clamped to start-of-day
        expect(selected.hour, 0);
        expect(selected.minute, 0);
        expect(selected.second, 0);
        expect(selected.millisecond, 0);

        // Should be exactly maxBackdateDays (7) days back in whole days
        final nowStartOfDay = DateTime(now.year, now.month, now.day);
        expect(nowStartOfDay.difference(selected).inDays, 7);
      });

      test('updateSelectedDate_clampsFutureDateToToday', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Act - try to set future date
        viewModel!.updateSelectedDate(now.add(const Duration(days: 5)));

        // Assert - clamped to today
        final startOfToday = DateTime(now.year, now.month, now.day);
        expect(viewModel!.selectedDate.value.year, startOfToday.year);
        expect(viewModel!.selectedDate.value.month, startOfToday.month);
        expect(viewModel!.selectedDate.value.day, startOfToday.day);
      });
    });

    group('submit validation', () {
      setUp(() {
        // Set up eligible user for submit tests
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test(
        'submit_withZeroDuration_setsLogSessionErrorWithValidationFailure',
        () async {
          // Arrange
          final now = DateTime.now();
          viewModel = createViewModel(initialDate: now);
          await viewModel!.init();

          // Set duration to 0
          viewModel!.updateDurationMinutes(0);

          // Set up mocks for submission attempt
          when(() => mockUuid.v4()).thenReturn('test-uuid');

          // Act
          await viewModel!.submit();

          // Assert - should be LogSessionError due to duration validation
          expect(viewModel!.state.value, isA<LogSessionError>());
          final state = viewModel!.state.value as LogSessionError;
          expect(
            state.failure.code,
            SessionFailures.durationMustBePositive.code,
          );

          // Verify haptic error feedback
          verify(
            () => mockNotifyService.setHapticFeedbackEvent(
              HapticFeedbackEvent.error,
            ),
          ).called(1);

          // Verify toast error
          verify(
            () => mockNotifyService.setToastEvent(
              any(that: isA<ToastEventError>()),
            ),
          ).called(1);

          // Verify no persistence or sync occurred
          verifyNever(() => mockLocalDataSource.savePendingSession(any()));
          verifyNever(() => mockSyncService.sync());
        },
      );

      test(
        'submit_withNegativeDuration_setsLogSessionErrorWithValidationFailure',
        () async {
          // Arrange
          final now = DateTime.now();
          viewModel = createViewModel(initialDate: now);
          await viewModel!.init();

          // Set negative duration
          viewModel!.updateDurationMinutes(-5);

          // Set up mocks for submission attempt
          when(() => mockUuid.v4()).thenReturn('test-uuid');

          // Act
          await viewModel!.submit();

          // Assert - should be LogSessionError due to duration validation
          expect(viewModel!.state.value, isA<LogSessionError>());
          final state = viewModel!.state.value as LogSessionError;
          expect(
            state.failure.code,
            SessionFailures.durationMustBePositive.code,
          );

          // Verify haptic error feedback
          verify(
            () => mockNotifyService.setHapticFeedbackEvent(
              HapticFeedbackEvent.error,
            ),
          ).called(1);

          // Verify toast error
          verify(
            () => mockNotifyService.setToastEvent(
              any(that: isA<ToastEventError>()),
            ),
          ).called(1);

          // Verify no persistence or sync occurred
          verifyNever(() => mockLocalDataSource.savePendingSession(any()));
          verifyNever(() => mockSyncService.sync());
        },
      );
    });

    group('submit success', () {
      setUp(() {
        // Set up eligible user for submit tests
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test(
        'submit_withValidData_savesPendingSessionWithCorrectContent',
        () async {
          // Arrange
          final now = DateTime.now();
          viewModel = createViewModel(initialDate: now);
          await viewModel!.init();

          viewModel!.updateNotes('Test notes');

          const testUuid = 'test-uuid-123';
          when(() => mockUuid.v4()).thenReturn(testUuid);
          when(
            () => mockLocalDataSource.savePendingSession(any()),
          ).thenAnswer((_) async {});
          when(() => mockSyncService.sync()).thenAnswer((_) async {});

          // Act
          await viewModel!.submit();

          // Assert - capture and verify pending session content
          final captured =
              verify(
                    () => mockLocalDataSource.savePendingSession(captureAny()),
                  ).captured.single
                  as PendingSession;

          expect(captured.localId, testUuid);
          expect(captured.userId, TestConstants.user.id);
          expect(captured.draft.protocolId, viewModel!.protocol.id);
          expect(captured.draft.notes, 'Test notes');
        },
      );

      test('submit_withValidData_triggersSessionSyncServiceSync', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});
        when(() => mockSyncService.sync()).thenAnswer((_) async {});

        // Act
        await viewModel!.submit();

        // Assert
        verify(() => mockSyncService.sync()).called(1);
      });

      test('submit_withValidData_emitsLogSessionSuccessWithSession', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});
        when(() => mockSyncService.sync()).thenAnswer((_) async {});

        // Act
        await viewModel!.submit();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionSuccess>());
        final state = viewModel!.state.value as LogSessionSuccess;
        expect(
          state.session.id,
          '${SessionLocalDataSource.pendingIdPrefix}$testUuid',
        );
        expect(state.session.protocolId, viewModel!.protocol.id);

        // Verify success haptic feedback
        verify(
          () => mockNotifyService.setHapticFeedbackEvent(
            HapticFeedbackEvent.success,
          ),
        ).called(1);

        // Verify toast
        verify(
          () => mockNotifyService.setToastEvent(
            any(that: isA<ToastEventSuccess>()),
          ),
        ).called(1);
      });

      test(
        'submit_withValidDataAndDuration_includesDurationInSession',
        () async {
          // Arrange
          final now = DateTime.now();
          viewModel = createViewModel(initialDate: now);
          await viewModel!.init();

          // Set valid duration
          viewModel!.updateDurationMinutes(30);

          const testUuid = 'test-uuid-123';
          when(() => mockUuid.v4()).thenReturn(testUuid);
          when(
            () => mockLocalDataSource.savePendingSession(any()),
          ).thenAnswer((_) async {});
          when(() => mockSyncService.sync()).thenAnswer((_) async {});

          // Act
          await viewModel!.submit();

          // Assert
          expect(viewModel!.state.value, isA<LogSessionSuccess>());
          final state = viewModel!.state.value as LogSessionSuccess;
          expect(state.session.duration?.inMinutes, 30);
        },
      );

      test('submit_withValidDataAndNotes_includesNotesInSession', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Set notes
        viewModel!.updateNotes('Test notes for the session');

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});
        when(() => mockSyncService.sync()).thenAnswer((_) async {});

        // Act
        await viewModel!.submit();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionSuccess>());
        final state = viewModel!.state.value as LogSessionSuccess;
        expect(state.session.notes, 'Test notes for the session');
      });
    });

    group('form state', () {
      setUp(() {
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test('selectedDate_updatesCorrectly', () async {
        // Arrange
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Act
        viewModel!.updateSelectedDate(yesterday);

        // Assert
        expect(viewModel!.selectedDate.value.year, yesterday.year);
        expect(viewModel!.selectedDate.value.month, yesterday.month);
        expect(viewModel!.selectedDate.value.day, yesterday.day);
      });

      test('durationMinutes_updatesCorrectly', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Act
        viewModel!.updateDurationMinutes(45);

        // Assert
        expect(viewModel!.durationMinutes.value, 45);
      });

      test('durationMinutes_canBeCleared', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Set and clear duration
        viewModel!.updateDurationMinutes(45);
        viewModel!.updateDurationMinutes(null);

        // Assert
        expect(viewModel!.durationMinutes.value, isNull);
      });

      test('notes_updatesCorrectly', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Act
        viewModel!.updateNotes('My session notes');

        // Assert
        expect(viewModel!.notes.value, 'My session notes');
      });

      test('notes_canBeEmptied', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        // Set and clear notes
        viewModel!.updateNotes('Some notes');
        viewModel!.updateNotes('');

        // Assert
        expect(viewModel!.notes.value, '');
      });
    });

    group('submit guards', () {
      setUp(() {
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test('submit_whenInitialState_doesNothing', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        // Do NOT call init() - state remains LogSessionInitial

        when(() => mockUuid.v4()).thenReturn('test-uuid');
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});

        // Act
        await viewModel!.submit();

        // Assert - no save should happen
        verifyNever(() => mockLocalDataSource.savePendingSession(any()));
        expect(viewModel!.state.value, isA<LogSessionInitial>());
      });

      test('submit_whenIneligible_doesNothing', () async {
        // Arrange
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => left(UserFailures.tooManyActiveProtocols));
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        when(() => mockUuid.v4()).thenReturn('test-uuid');
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});

        // Act
        await viewModel!.submit();

        // Assert - no save should happen
        verifyNever(() => mockLocalDataSource.savePendingSession(any()));
        expect(viewModel!.state.value, isA<LogSessionIneligible>());
      });

      test('submit_whenSubmitting_doesNothing', () async {
        // Arrange - Use a slow local save to keep state in Submitting
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(() => mockLocalDataSource.savePendingSession(any())).thenAnswer((
          _,
        ) async {
          // Slow save to simulate being in submitting state
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        when(() => mockSyncService.sync()).thenAnswer((_) async {});

        // Act - start first submit (will be submitting)
        final firstSubmit = viewModel!.submit();

        // State transitions to submitting synchronously before first await
        expect(viewModel!.state.value, isA<LogSessionSubmitting>());

        // Second submit while in submitting state
        await viewModel!.submit();

        // Wait for first to complete
        await firstSubmit;

        // Assert - only one save should happen (second was blocked)
        verify(() => mockLocalDataSource.savePendingSession(any())).called(1);
      });

      test('submit_whenAlreadySuccess_doesNothing', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});
        when(() => mockSyncService.sync()).thenAnswer((_) async {});

        // First submit
        await viewModel!.submit();
        expect(viewModel!.state.value, isA<LogSessionSuccess>());

        // Reset mock counts
        reset(mockLocalDataSource);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenAnswer((_) async {});

        // Act - second submit
        await viewModel!.submit();

        // Assert - no second save
        verifyNever(() => mockLocalDataSource.savePendingSession(any()));
      });
    });

    group('error handling', () {
      setUp(() {
        when(
          () => mockCheckEligibility.execute(any()),
        ).thenAnswer((_) async => right(unit));
      });

      test('submit_whenLocalSaveFails_setsErrorStateWithToast', () async {
        // Arrange
        final now = DateTime.now();
        viewModel = createViewModel(initialDate: now);
        await viewModel!.init();

        const testUuid = 'test-uuid-123';
        when(() => mockUuid.v4()).thenReturn(testUuid);
        when(
          () => mockLocalDataSource.savePendingSession(any()),
        ).thenThrow(Exception('Local storage error'));

        // Act
        await viewModel!.submit();

        // Assert
        expect(viewModel!.state.value, isA<LogSessionError>());
        final state = viewModel!.state.value as LogSessionError;
        expect(state.failure.code, 'Session.LocalSaveFailed');

        // Verify error haptic feedback
        verify(
          () => mockNotifyService.setHapticFeedbackEvent(
            HapticFeedbackEvent.error,
          ),
        ).called(1);

        // Verify toast error
        verify(
          () => mockNotifyService.setToastEvent(
            any(that: isA<ToastEventError>()),
          ),
        ).called(1);

        // Verify sync was not triggered (save failed before sync)
        verifyNever(() => mockSyncService.sync());
      });
    });
  });
}
