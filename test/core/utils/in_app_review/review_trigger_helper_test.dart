import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/utils/in_app_review/review_trigger_helper.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';

import '../../../mocks/mock_services.dart';

void main() {
  late MockSessionLocalDataSource sessionLocalDataSource;
  late MockInAppReviewService inAppReviewService;
  late ReviewTriggerHelper helper;

  setUp(() {
    sessionLocalDataSource = MockSessionLocalDataSource();
    inAppReviewService = MockInAppReviewService();
    helper = ReviewTriggerHelper(
      sessionLocalDataSource: sessionLocalDataSource,
      inAppReviewService: inAppReviewService,
    );
  });

  group('captureSessionCount', () {
    test('returns sum of synced and pending sessions', () async {
      when(() => sessionLocalDataSource.getSyncedSessions('user-1'))
          .thenAnswer((_) async => [
                Session.reconstitute(
                  id: '1',
                  protocolId: 'p1',
                  completedAt: DateTime(2026),
                  duration: null,
                  notes: null,
                ),
                Session.reconstitute(
                  id: '2',
                  protocolId: 'p1',
                  completedAt: DateTime(2026),
                  duration: null,
                  notes: null,
                ),
              ]);
      when(() => sessionLocalDataSource.getPendingSessions('user-1'))
          .thenAnswer((_) async => <PendingSession>[]);

      final count = await helper.captureSessionCount('user-1');

      expect(count, equals(2));
    });

    test('returns 0 when exception occurs', () async {
      when(() => sessionLocalDataSource.getSyncedSessions('user-1'))
          .thenThrow(Exception('corrupt'));
      when(() => sessionLocalDataSource.getPendingSessions('user-1'))
          .thenAnswer((_) async => <PendingSession>[]);

      final count = await helper.captureSessionCount('user-1');

      expect(count, equals(0));
    });
  });

  group('triggerReviewIfNeeded', () {
    test('does not call service before 2-second delay', () {
      fakeAsync((async) {
        when(() => inAppReviewService.requestReviewIfNeeded(5, 'user-1'))
            .thenAnswer((_) async {});

        helper.triggerReviewIfNeeded(5, 'user-1');

        // Advance to just before the 2-second boundary.
        async.elapse(const Duration(seconds: 1, milliseconds: 999));
        verifyNever(
          () => inAppReviewService.requestReviewIfNeeded(5, 'user-1'),
        );

        // Advance past the 2-second boundary.
        async.elapse(const Duration(milliseconds: 1));
        verify(() => inAppReviewService.requestReviewIfNeeded(5, 'user-1'))
            .called(1);
      });
    });

    test('calls service after 2-second delay', () {
      fakeAsync((async) {
        when(() => inAppReviewService.requestReviewIfNeeded(5, 'user-1'))
            .thenAnswer((_) async {});

        helper.triggerReviewIfNeeded(5, 'user-1');

        async.elapse(const Duration(seconds: 2));

        verify(() => inAppReviewService.requestReviewIfNeeded(5, 'user-1'))
            .called(1);
      });
    });

    test('does not throw when service throws', () {
      fakeAsync((async) {
        when(() => inAppReviewService.requestReviewIfNeeded(5, 'user-1'))
            .thenThrow(Exception('service error'));

        helper.triggerReviewIfNeeded(5, 'user-1');

        // Should not throw when elapsed.
        async.elapse(const Duration(seconds: 2));
      });
    });
  });
}
