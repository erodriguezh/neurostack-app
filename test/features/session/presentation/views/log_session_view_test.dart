import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/data/services/session_sync_service.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';
import 'package:neurostack/features/session/presentation/view_models/log_session_view_model.dart';
import 'package:neurostack/features/session/presentation/views/log_session_view.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:uuid/uuid.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/protocol_factory.dart';

// Mocks
class MockCheckEligibilityUseCase extends Mock
    implements CheckEligibilityUseCase {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockSessionSyncService extends Mock implements SessionSyncService {}

class MockNotifyService extends Mock implements NotifyService {}

class MockUuid extends Mock implements Uuid {}

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

  group('LogSessionView', () {
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
      when(() => mockNotifyService.setHapticFeedbackEvent(any()))
          .thenAnswer((_) {});
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

    Widget wrapWidget(LogSessionView widget) {
      return MaterialApp(
        theme: AppTheme.buildTheme(Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => widget,
          ),
        ),
      );
    }

    group('Notes counter behavior', () {
      testWidgets(
        'notesCounter_whenLessThan100Characters_isHidden',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Act - enter 99 characters (less than threshold)
          final notesField = find.byType(TextField).last;
          await tester.enterText(notesField, 'A' * 99);
          await tester.pump();

          // Assert - counter should not be visible
          expect(find.textContaining('/140'), findsNothing);

          viewModel.dispose();
        },
      );

      testWidgets(
        'notesCounter_when100OrMoreCharacters_isVisible',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Act - enter exactly 100 characters
          final notesField = find.byType(TextField).last;
          await tester.enterText(notesField, 'A' * 100);
          await tester.pump();

          // Assert - counter should be visible
          expect(find.text('100/140'), findsOneWidget);

          viewModel.dispose();
        },
      );

      testWidgets(
        'notesCounter_when130OrMoreCharacters_isRed',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Act - enter 130 characters (at red threshold)
          final notesField = find.byType(TextField).last;
          await tester.enterText(notesField, 'A' * 130);
          await tester.pump();

          // Assert - counter should be visible and use red400 color
          final counterFinder = find.text('130/140');
          expect(counterFinder, findsOneWidget);

          final counterText = tester.widget<Text>(counterFinder);
          final element = tester.element(counterFinder);
          final kitColors = element.kitColors;

          expect(counterText.style?.color, kitColors.red400);

          viewModel.dispose();
        },
      );

      testWidgets(
        'notesCounter_whenBelow130Characters_isNotRed',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Act - enter 129 characters (just below red threshold)
          final notesField = find.byType(TextField).last;
          await tester.enterText(notesField, 'A' * 129);
          await tester.pump();

          // Assert - counter should be visible and use white30 color (not red)
          final counterFinder = find.text('129/140');
          expect(counterFinder, findsOneWidget);

          final counterText = tester.widget<Text>(counterFinder);
          final element = tester.element(counterFinder);
          final kitColors = element.kitColors;

          expect(counterText.style?.color, kitColors.white30);

          viewModel.dispose();
        },
      );
    });

    group('Submit button', () {
      testWidgets(
        'submitButton_whenSubmitting_showsLoadingIndicator',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));
          when(() => mockUuid.v4()).thenReturn('test-uuid');
          when(() => mockSyncService.sync()).thenAnswer((_) async {});

          // Use Completer for deterministic timing (no real delays)
          final saveCompleter = Completer<void>();
          when(() => mockLocalDataSource.savePendingSession(any()))
              .thenAnswer((_) => saveCompleter.future);

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verify initial state - no loading indicator
          expect(find.byKey(const ValueKey('cta-loading')), findsNothing);
          expect(find.byKey(const ValueKey('cta-label')), findsOneWidget);

          // Act - trigger submit (don't await to keep in submitting state)
          // ignore: unawaited_futures
          viewModel.submit();

          // Pump to rebuild after state change + pump through AnimatedSwitcher
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          // Assert - loading indicator should be visible
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Clean up - allow submit to finish
          saveCompleter.complete();
          await tester.pumpAndSettle();

          viewModel.dispose();
        },
      );

      testWidgets(
        'submitButton_whenReady_showsLabelNotLoading',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert - label should be visible, not loading
          expect(find.byKey(const ValueKey('cta-label')), findsOneWidget);
          expect(find.byKey(const ValueKey('cta-loading')), findsNothing);
          // Log Session appears in both header and button, so we verify via the key
          // The cta-label Row contains the button text

          viewModel.dispose();
        },
      );
    });

    group('Duration field', () {
      testWidgets(
        'durationField_whenValidationError_showsErrorStyling',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));
          when(() => mockUuid.v4()).thenReturn('test-uuid');

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Find the duration field
          final durationField = find.byType(TextField).first;

          // Act - enter invalid duration (0) and submit
          await tester.enterText(durationField, '0');
          await tester.pump();

          // Trigger submit to cause validation error
          await viewModel.submit();
          await tester.pump();

          // Assert - error text should be visible
          expect(
            find.text('Session duration must be greater than zero'),
            findsOneWidget,
          );

          // Assert - duration field container should have error border styling
          // Find the Container ancestor of the TextField that has BoxDecoration
          final decoratedContainerFinder = find.ancestor(
            of: durationField,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Container) return false;
              final decoration = widget.decoration;
              if (decoration is! BoxDecoration) return false;
              return decoration.border != null;
            }),
          ).first;

          final container = tester.widget<Container>(decoratedContainerFinder);
          final decoration = container.decoration! as BoxDecoration;
          final border = decoration.border! as Border;
          final element = tester.element(durationField);
          final kitColors = element.kitColors;

          // Border should be red500 with 0.5 alpha when there's an error
          expect(
            border.top.color,
            kitColors.red500.withValues(alpha: 0.5),
          );

          viewModel.dispose();
        },
      );

      testWidgets(
        'durationField_whenNoError_doesNotShowErrorText',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert - no error text should be visible
          expect(
            find.text('Session duration must be greater than zero'),
            findsNothing,
          );

          viewModel.dispose();
        },
      );

      testWidgets(
        'durationField_errorClears_whenUserTypesNewValue',
        (tester) async {
          // Arrange
          when(() => mockCheckEligibility.execute(any()))
              .thenAnswer((_) async => right(unit));
          when(() => mockUuid.v4()).thenReturn('test-uuid');

          final viewModel = createViewModel();
          await viewModel.init();

          await tester.pumpWidget(
            wrapWidget(
              LogSessionView(
                viewModel: viewModel,
                onSessionLogged: (_) {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Find the duration field
          final durationField = find.byType(TextField).first;

          // Act - enter invalid duration and submit
          await tester.enterText(durationField, '0');
          await tester.pump();
          await viewModel.submit();
          await tester.pump();

          // Verify error is shown
          expect(
            find.text('Session duration must be greater than zero'),
            findsOneWidget,
          );

          // Capture the error border color
          final decoratedContainerFinder = find.ancestor(
            of: durationField,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Container) return false;
              final decoration = widget.decoration;
              if (decoration is! BoxDecoration) return false;
              return decoration.border != null;
            }),
          ).first;

          var container = tester.widget<Container>(decoratedContainerFinder);
          var decoration = container.decoration! as BoxDecoration;
          var border = decoration.border! as Border;
          final element = tester.element(durationField);
          final kitColors = element.kitColors;

          // Verify error border is present
          expect(border.top.color, kitColors.red500.withValues(alpha: 0.5));

          // Act - user types a new value
          await tester.enterText(durationField, '30');
          await tester.pump();

          // Assert - error should be cleared
          expect(
            find.text('Session duration must be greater than zero'),
            findsNothing,
          );

          // Border should return to normal (white10)
          container = tester.widget<Container>(decoratedContainerFinder);
          decoration = container.decoration! as BoxDecoration;
          border = decoration.border! as Border;
          expect(border.top.color, kitColors.white10);

          viewModel.dispose();
        },
      );
    });
  });
}
