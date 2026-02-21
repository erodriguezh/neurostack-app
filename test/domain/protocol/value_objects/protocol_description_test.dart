import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/domain/failures/protocol_failures.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';

import '../../../constants/test_constants.dart';
import '../../../factories/factories.dart';
import '../../../matchers/either_matchers.dart';

void main() {
  group('ProtocolDescription', () {
    group('create succeeds', () {
      final validCases = [
        (
          input: TestConstants.protocol.validDescription,
          desc: 'standardDescription',
        ),
        (input: 'A', desc: 'singleCharacter'),
        (
          input: TestConstants.protocol.maxLengthDescription,
          desc: 'exactly2000Chars',
        ),
      ];

      for (final c in validCases) {
        test('create_when${c.desc}_succeeds', () {
          // Act
          final result = ProtocolDescriptionFactory.create(c.input);

          // Assert
          expect(result, isRight<ProtocolDescription>());
        });
      }

      test('create_whenWhitespacePadded_trimsAndSucceeds', () {
        // Act
        final result = ProtocolDescriptionFactory.create('  hello  ');

        // Assert
        expect(result, isRight<ProtocolDescription>());
        final description = result.getOrElse((l) => throw Exception('$l'));
        expect(description.value, 'hello');
      });
    });

    group('create fails', () {
      test('create_whenEmpty_returnsDescriptionEmpty', () {
        // Act
        final result = ProtocolDescriptionFactory.create(
          TestConstants.protocol.emptyDescription,
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.descriptionEmpty));
      });

      test('create_whenWhitespaceOnly_returnsDescriptionEmpty', () {
        // Act
        final result = ProtocolDescriptionFactory.create('   ');

        // Assert
        expect(result, isLeftWith(ProtocolFailures.descriptionEmpty));
      });

      test('create_whenTooLong_returnsDescriptionTooLong', () {
        // Act
        final result = ProtocolDescriptionFactory.create(
          TestConstants.protocol.tooLongDescription,
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.descriptionTooLong));
      });
    });

    group('toString', () {
      test('toString_returnsUnderlyingValue', () {
        // Arrange
        final description = ProtocolDescriptionFactory.valid();

        // Act & Assert
        expect(
          description.toString(),
          TestConstants.protocol.validDescription,
        );
      });
    });
  });
}
