import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import '../../constants/test_constants.dart';
import '../../factories/factories.dart';

void main() {
  group('PendingSession', () {
    group('create', () {
      test('create_withValidData_succeeds', () {
        // Arrange
        final draft = SessionDraftFactory.valid();

        // Act
        final pending = PendingSession.create(
          localId: TestConstants.pendingSession.localId,
          userId: TestConstants.user.id,
          draft: draft,
          createdAt: TestConstants.pendingSession.createdAt,
        );

        // Assert
        expect(pending.localId, TestConstants.pendingSession.localId);
        expect(pending.userId, TestConstants.user.id);
        expect(pending.draft, draft);
        expect(pending.createdAt, TestConstants.pendingSession.createdAt);
        expect(pending.retryCount, 0);
      });

      test('create_initializesRetryCountToZero', () {
        // Act
        final pending = PendingSessionFactory.create();

        // Assert
        expect(pending.retryCount, 0);
      });
    });

    group('reconstitute', () {
      test('reconstitute_preservesRetryCount', () {
        // Arrange
        final draft = SessionDraftFactory.valid();
        const retryCount = 3;

        // Act
        final pending = PendingSession.reconstitute(
          localId: TestConstants.pendingSession.localId,
          userId: TestConstants.user.id,
          draft: draft,
          createdAt: TestConstants.pendingSession.createdAt,
          retryCount: retryCount,
        );

        // Assert
        expect(pending.retryCount, retryCount);
      });
    });

    group('incrementRetry', () {
      test('incrementRetry_returnsNewInstanceWithIncrementedCount', () {
        // Arrange
        final original = PendingSessionFactory.create();
        expect(original.retryCount, 0);

        // Act
        final incremented = original.incrementRetry();

        // Assert
        expect(incremented.retryCount, 1);
        expect(original.retryCount, 0); // Original unchanged (immutable)
      });

      test('incrementRetry_preservesOtherFields', () {
        // Arrange
        final original = PendingSessionFactory.create();

        // Act
        final incremented = original.incrementRetry();

        // Assert
        expect(incremented.localId, original.localId);
        expect(incremented.userId, original.userId);
        expect(incremented.draft, original.draft);
        expect(incremented.createdAt, original.createdAt);
      });

      test('incrementRetry_canBeCalledMultipleTimes', () {
        // Arrange
        final original = PendingSessionFactory.create();

        // Act
        final result = original
            .incrementRetry()
            .incrementRetry()
            .incrementRetry();

        // Assert
        expect(result.retryCount, 3);
      });
    });

    group('equality', () {
      test('equality_sameLocalIdAndUserId_areEqual', () {
        // Arrange
        const localId = 'same-id';
        const userId = 'same-user';
        final pending1 = PendingSessionFactory.create(
          localId: localId,
          userId: userId,
        );
        final pending2 = PendingSessionFactory.create(
          localId: localId,
          userId: userId,
        );

        // Assert
        expect(pending1, equals(pending2));
      });

      test('equality_differentLocalId_areNotEqual', () {
        // Arrange
        final pending1 = PendingSessionFactory.create(localId: 'id-1');
        final pending2 = PendingSessionFactory.create(localId: 'id-2');

        // Assert
        expect(pending1, isNot(equals(pending2)));
      });

      test('equality_sameLocalIdDifferentUserId_areNotEqual', () {
        // Arrange
        const localId = 'same-id';
        final pending1 = PendingSessionFactory.create(
          localId: localId,
          userId: 'user-1',
        );
        final pending2 = PendingSessionFactory.create(
          localId: localId,
          userId: 'user-2',
        );

        // Assert
        expect(pending1, isNot(equals(pending2)));
      });

      test('hashCode_sameLocalIdAndUserId_haveSameHashCode', () {
        // Arrange
        const localId = 'same-id';
        const userId = 'same-user';
        final pending1 = PendingSessionFactory.create(
          localId: localId,
          userId: userId,
        );
        final pending2 = PendingSessionFactory.create(
          localId: localId,
          userId: userId,
        );

        // Assert
        expect(pending1.hashCode, equals(pending2.hashCode));
      });
    });

    group('factory helpers', () {
      test('withRetryCount_createsWithSpecifiedRetryCount', () {
        // Act
        final pending = PendingSessionFactory.withRetryCount(retryCount: 5);

        // Assert
        expect(pending.retryCount, 5);
      });

      test('createBatch_createsMultiplePendingSessions', () {
        // Act
        final batch = PendingSessionFactory.createBatch(count: 3);

        // Assert
        expect(batch.length, 3);
        expect(batch[0].localId, 'local-0');
        expect(batch[1].localId, 'local-1');
        expect(batch[2].localId, 'local-2');
      });

      test('createBatch_allHaveSameUserId', () {
        // Arrange
        const userId = 'batch-user';

        // Act
        final batch = PendingSessionFactory.createBatch(
          count: 3,
          userId: userId,
        );

        // Assert
        for (final pending in batch) {
          expect(pending.userId, userId);
        }
      });
    });
  });
}
