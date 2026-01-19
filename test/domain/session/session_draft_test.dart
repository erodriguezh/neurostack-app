import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/domain/entities/session_draft.dart';
import 'package:neurostack/features/session/domain/failures/session_failures.dart';
import '../../constants/test_constants.dart';
import '../../factories/factories.dart';
import '../../matchers/either_matchers.dart';

void main() {
  group('SessionDraft', () {
    group('create', () {
      test('create_withValidData_succeeds', () {
        // Act
        final result = SessionDraftFactory.create();

        // Assert
        expect(result, isRight<SessionDraft>());
      });

      // INV-S2: No future timestamps
      test('create_withFutureTimestamp_returnsTimestampInFuture', () {
        // Arrange
        final futureTime = TestConstants.session.currentTime.add(
          const Duration(hours: 1),
        );

        // Act
        final result = SessionDraftFactory.create(completedAt: futureTime);

        // Assert
        expect(result, isLeftWith(SessionFailures.timestampInFuture));
      });

      // INV-S4: No timestamps older than 7 days
      test('create_withTooOldTimestamp_returnsDateTooOld', () {
        // Arrange
        final tooOldTime = TestConstants.session.currentTime.subtract(
          const Duration(days: 8),
        );

        // Act
        final result = SessionDraftFactory.create(completedAt: tooOldTime);

        // Assert
        expect(result, isLeftWith(SessionFailures.dateTooOld));
      });

      // INV-S4: Boundary - exactly 7 days ago should be valid
      test('create_withExactlySevenDaysAgo_succeeds', () {
        // Arrange
        final exactlySevenDaysAgo = TestConstants.session.currentTime.subtract(
          const Duration(days: 7),
        );

        // Act
        final result = SessionDraftFactory.create(
          completedAt: exactlySevenDaysAgo,
        );

        // Assert
        expect(result, isRight<SessionDraft>());
      });

      test('create_trimsEmptyNotes', () {
        // Arrange
        const emptyNotes = '   ';

        // Act
        final result = SessionDraftFactory.create(notes: emptyNotes);

        // Assert
        final draft = result.getOrElse(
          (l) => throw Exception('Failed to create draft: $l'),
        );
        expect(draft.notes, null);
      });

      test('create_preservesNonEmptyNotes', () {
        // Arrange
        const notes = 'Felt great today!';

        // Act
        final result = SessionDraftFactory.create(notes: notes);

        // Assert
        final draft = result.getOrElse(
          (l) => throw Exception('Failed to create draft: $l'),
        );
        expect(draft.notes, notes);
      });
    });
  });
}
