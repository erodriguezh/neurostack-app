import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/domain/failures/protocol_failures.dart';
import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';
import '../../../factories/factories.dart';
import '../../../matchers/either_matchers.dart';

void main() {
  group('Frequency', () {
    group('create succeeds', () {
      final validCases = [
        (min: 1, max: 1, desc: 'oncePerWeek'),
        (min: 3, max: 4, desc: 'threeToFourPerWeek'),
        (min: 7, max: 7, desc: 'daily'),
        (min: 1, max: 7, desc: 'oneToSevenPerWeek'),
      ];

      for (final c in validCases) {
        test('create_when${c.desc}_succeeds', () {
          // Act
          final result = FrequencyFactory.create(
            minPerWeek: c.min,
            maxPerWeek: c.max,
          );

          // Assert
          expect(result, isRight<Frequency>());
        });
      }
    });

    group('create fails', () {
      test('create_whenMinLessThanOne_returnsInvalidFrequency', () {
        // Act
        final result = FrequencyFactory.create(
          minPerWeek: 0,
          maxPerWeek: 3,
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.invalidFrequency));
      });

      test('create_whenMaxLessThanMin_returnsMaxLessThanMin', () {
        // Act
        final result = FrequencyFactory.create(
          minPerWeek: 5,
          maxPerWeek: 3,
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.maxLessThanMin));
      });
    });

    group('displayText', () {
      final displayCases = [
        (min: 1, max: 1, expected: '1x/week', desc: 'oncePerWeek'),
        (min: 3, max: 4, expected: '3-4x/week', desc: 'range'),
        (min: 7, max: 7, expected: '7x/week', desc: 'daily'),
      ];

      for (final c in displayCases) {
        test('displayText_when${c.desc}_returns${c.expected}', () {
          // Arrange
          final frequency = FrequencyFactory.create(
            minPerWeek: c.min,
            maxPerWeek: c.max,
          ).getOrElse((l) => throw Exception('Failed to create frequency: $l'));

          // Act & Assert
          expect(frequency.displayText, c.expected);
        });
      }
    });
  });
}
