import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/events/session_events.dart';
import 'package:neurostack/features/session/domain/failures/session_failures.dart';
import '../../constants/test_constants.dart';
import '../../factories/factories.dart';
import '../../matchers/either_matchers.dart';

void main() {
  group('Session', () {
    group('create', () {
      test('create_withValidData_succeeds', () {
        // Act
        final result = SessionFactory.create();

        // Assert
        expect(result, isRight<Session>());
      });

      // INV-S2: No future timestamps
      test('create_withFutureTimestamp_returnsTimestampInFuture', () {
        // Act
        final result = SessionFactory.withFutureTimestamp();

        // Assert
        expect(result, isLeftWith(SessionFailures.timestampInFuture));
      });

      test('create_withOptionalDuration_succeeds', () {
        // Act
        final result = SessionFactory.withDuration(
          duration: const Duration(minutes: 30),
        );

        // Assert
        expect(result, isRight<Session>());
      });

      test('create_withNullDuration_succeeds', () {
        // Act
        final result = SessionFactory.create(duration: null);

        // Assert
        expect(result, isRight<Session>());
      });

      test('create_trimsEmptyNotes', () {
        // Arrange
        const emptyNotes = '   ';

        // Act
        final result = SessionFactory.create(notes: emptyNotes);

        // Assert
        final session = result.getOrElse(
          (l) => throw Exception('Failed to create session: $l'),
        );
        expect(session.notes, null);
      });

      test('create_preservesNonEmptyNotes', () {
        // Arrange
        const notes = 'Felt great today!';

        // Act
        final result = SessionFactory.create(notes: notes);

        // Assert
        final session = result.getOrElse(
          (l) => throw Exception('Failed to create session: $l'),
        );
        expect(session.notes, notes);
      });
    });

    group('reconstitute', () {
      test('reconstitute_createsSessionWithoutValidation', () {
        // Act
        final session = SessionFactory.reconstitute(
          id: 'session-123',
          protocolId: 'protocol-456',
          completedAt: DateTime(2025, 1, 1),
        );

        // Assert
        expect(session.id, 'session-123');
        expect(session.protocolId, 'protocol-456');
        expect(session.completedAt, DateTime(2025, 1, 1));
      });
    });

    group('domain events', () {
      test('create_raisesSessionLoggedEvent', () {
        // Arrange
        final protocolId = TestConstants.session.protocolId;
        final completedAt = TestConstants.session.validCompletedAt;

        // Act
        final result = SessionFactory.create(
          protocolId: protocolId,
          completedAt: completedAt,
        );

        // Assert
        final session = result.getOrElse(
          (l) => throw Exception('Failed to create session: $l'),
        );
        expect(session.hasDomainEvents, true);
        expect(session.domainEvents.length, 1);
        expect(
          session.domainEvents.first,
          isA<SessionLoggedEvent>()
              .having((e) => e.sessionId, 'sessionId', session.id)
              .having((e) => e.protocolId, 'protocolId', protocolId)
              .having((e) => e.completedAt, 'completedAt', completedAt),
        );
      });
    });
  });
}
