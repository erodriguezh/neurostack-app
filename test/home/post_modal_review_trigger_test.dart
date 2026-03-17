import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';

import '../mocks/mock_services.dart';

/// Simulates the callback-future orchestration used in both HomeView and
/// ProgressView when a session is logged:
///
/// 1. `captureSessionCount` Future started inside `onSessionLogged` callback
/// 2. Future runs concurrently with modal dismiss
/// 3. After modal dismiss, `await sessionCountFuture` resolves with correct count
/// 4. `triggerReviewIfNeeded` called after dismiss with the captured count
/// 5. 2-second delay occurs before `requestReviewIfNeeded` fires
void main() {
  late MockReviewTriggerHelper mockHelper;

  setUp(() {
    mockHelper = MockReviewTriggerHelper();
  });

  group('post-modal review trigger orchestration', () {
    test(
      'Future started in onSessionLogged, awaited after dismiss, '
      'delayed trigger fires with correct count',
      () {
        fakeAsync((async) {
          const userId = 'user-123';
          const sessionCount = 5;

          when(
            () => mockHelper.captureSessionCount(userId),
          ).thenAnswer((_) async => sessionCount);
          when(
            () => mockHelper.triggerReviewIfNeeded(sessionCount, userId),
          ).thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 2));
          });

          // --- Simulate the pattern used in HomeView / ProgressView ---

          Future<int>? sessionCountFuture;

          // Simulate showLogSessionModal: callback fires, then modal dismisses.
          final modalCompleter = Completer<void>();

          // Phase 1: onSessionLogged callback fires (pre-dismiss)
          void onSessionLogged(Session session) {
            sessionCountFuture = mockHelper.captureSessionCount(userId);
          }

          // Trigger the callback (simulating session logged event)
          onSessionLogged(_fakeSession());

          // Verify captureSessionCount was called
          verify(() => mockHelper.captureSessionCount(userId)).called(1);

          // triggerReviewIfNeeded should NOT have been called yet
          verifyNever(
            () => mockHelper.triggerReviewIfNeeded(any(), any()),
          );

          // Phase 2: Modal dismisses
          modalCompleter.complete();
          async.flushMicrotasks();

          // Phase 3: After modal dismiss, await the future and trigger review
          var triggerCompleted = false;
          unawaited(
            () async {
              if (sessionCountFuture != null) {
                try {
                  final count = await sessionCountFuture!;
                  await mockHelper.triggerReviewIfNeeded(count, userId);
                } catch (_) {
                  // Non-critical
                }
              }
              triggerCompleted = true;
            }(),
          );

          // Flush microtasks to resolve the captureSessionCount future
          async.flushMicrotasks();

          // triggerReviewIfNeeded should have been called now
          verify(
            () => mockHelper.triggerReviewIfNeeded(sessionCount, userId),
          ).called(1);

          // The 2-second delay inside triggerReviewIfNeeded is still pending
          expect(triggerCompleted, isFalse);

          // Advance time to complete it
          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();

          expect(triggerCompleted, isTrue);
        });
      },
    );

    test('no trigger when onSessionLogged never fires (modal cancelled)', () {
      fakeAsync((async) {
        Future<int>? sessionCountFuture;

        // Modal dismissed without logging a session -- onSessionLogged never
        // called, so sessionCountFuture stays null.
        async.flushMicrotasks();

        // The post-dismiss guard should skip the trigger entirely.
        expect(sessionCountFuture, isNull);

        verifyNever(() => mockHelper.captureSessionCount(any()));
        verifyNever(
          () => mockHelper.triggerReviewIfNeeded(any(), any()),
        );
      });
    });

    test('trigger is resilient to captureSessionCount failure', () {
      fakeAsync((async) {
        const userId = 'user-456';

        when(
          () => mockHelper.captureSessionCount(userId),
        ).thenAnswer((_) async => throw Exception('DB error'));

        Future<int>? sessionCountFuture;

        // onSessionLogged fires -- start the future
        sessionCountFuture = mockHelper.captureSessionCount(userId);

        // Post-dismiss: immediately start the closure that awaits the future
        // so the error is caught by the try/catch before flushMicrotasks
        // surfaces it as uncaught.
        var triggerCompleted = false;
        unawaited(
          () async {
            if (sessionCountFuture != null) {
              try {
                final count = await sessionCountFuture;
                await mockHelper.triggerReviewIfNeeded(count, userId);
              } catch (_) {
                // Non-critical -- review prompt is best-effort
              }
            }
            triggerCompleted = true;
          }(),
        );

        async.flushMicrotasks();

        // triggerReviewIfNeeded should NOT have been called (count future threw)
        verifyNever(
          () => mockHelper.triggerReviewIfNeeded(any(), any()),
        );

        // Despite the error, the orchestration completed gracefully
        expect(triggerCompleted, isTrue);
      });
    });

    test('trigger is resilient to triggerReviewIfNeeded failure', () {
      fakeAsync((async) {
        const userId = 'user-789';
        const sessionCount = 15;

        when(
          () => mockHelper.captureSessionCount(userId),
        ).thenAnswer((_) async => sessionCount);
        when(
          () => mockHelper.triggerReviewIfNeeded(sessionCount, userId),
        ).thenAnswer((_) async => throw Exception('Review API error'));

        Future<int>? sessionCountFuture;

        // onSessionLogged fires
        sessionCountFuture = mockHelper.captureSessionCount(userId);

        // Post-dismiss: immediately start the closure so the error handler
        // is wired before flushMicrotasks resolves the futures.
        var triggerCompleted = false;
        unawaited(
          () async {
            if (sessionCountFuture != null) {
              try {
                final count = await sessionCountFuture;
                await mockHelper.triggerReviewIfNeeded(count, userId);
              } catch (_) {
                // Non-critical -- review prompt is best-effort
              }
            }
            triggerCompleted = true;
          }(),
        );

        async.flushMicrotasks();

        // Both methods called, but exception caught gracefully
        verify(() => mockHelper.captureSessionCount(userId)).called(1);
        verify(
          () => mockHelper.triggerReviewIfNeeded(sessionCount, userId),
        ).called(1);

        expect(triggerCompleted, isTrue);
      });
    });
  });
}

Session _fakeSession() {
  return Session.reconstitute(
    id: 'session-1',
    protocolId: 'proto-1',
    completedAt: DateTime(2026, 3, 17),
  );
}
