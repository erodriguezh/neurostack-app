import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/domain/failures/session_failures.dart';
import 'package:neurostack/features/session/domain/value_objects/session_duration.dart';
import '../../../factories/factories.dart';
import '../../../matchers/either_matchers.dart';

void main() {
  group('SessionDuration', () {
    // INV-S3: Duration must be > 0
    group('create fails with invalid duration', () {
      final invalidCases = [
        (duration: Duration.zero, desc: 'zero'),
        (duration: const Duration(seconds: -1), desc: 'negative'),
        (duration: const Duration(minutes: -30), desc: 'negativeMinutes'),
      ];

      for (final c in invalidCases) {
        test('create_when${c.desc}_returnsDurationMustBePositive', () {
          // Act
          final result = SessionDurationFactory.create(c.duration);

          // Assert
          expect(result, isLeftWith(SessionFailures.durationMustBePositive));
        });
      }
    });

    group('create succeeds with valid duration', () {
      final validCases = [
        (duration: const Duration(seconds: 1), desc: 'oneSecond'),
        (duration: const Duration(minutes: 22), desc: 'twentyTwoMinutes'),
        (duration: const Duration(hours: 2), desc: 'twoHours'),
      ];

      for (final c in validCases) {
        test('create_when${c.desc}_succeeds', () {
          // Act
          final result = SessionDurationFactory.create(c.duration);

          // Assert
          expect(result, isRight<SessionDuration>());
        });
      }
    });

    group('inMinutes', () {
      test('inMinutes_returnsCorrectMinutes', () {
        // Arrange
        final duration = SessionDurationFactory.create(const Duration(minutes: 22))
            .getOrElse((l) => throw Exception('Failed to create duration: $l'));

        // Act & Assert
        expect(duration.inMinutes, 22);
      });
    });

    group('inSeconds', () {
      test('inSeconds_returnsCorrectSeconds', () {
        // Arrange
        final duration = SessionDurationFactory.create(const Duration(seconds: 90))
            .getOrElse((l) => throw Exception('Failed to create duration: $l'));

        // Act & Assert
        expect(duration.inSeconds, 90);
      });
    });

    group('displayText', () {
      final displayCases = [
        (minutes: 22, expected: '22m', desc: 'shortDuration'),
        (minutes: 60, expected: '1h', desc: 'exactHour'),
        (minutes: 90, expected: '1h 30m', desc: 'hourAndMinutes'),
      ];

      for (final c in displayCases) {
        test('displayText_when${c.desc}_returns${c.expected}', () {
          // Arrange
          final duration = SessionDurationFactory.create(Duration(minutes: c.minutes))
              .getOrElse((l) => throw Exception('Failed to create duration: $l'));

          // Act & Assert
          expect(duration.displayText, c.expected);
        });
      }
    });
  });
}
