import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/domain/failures/protocol_failures.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_name.dart';
import '../../../constants/test_constants.dart';
import '../../../factories/factories.dart';
import '../../../matchers/either_matchers.dart';

void main() {
  group('ProtocolName', () {
    group('create succeeds', () {
      final validCases = [
        (name: 'Norwegian 4x4 HIIT', desc: 'standard name'),
        (name: 'Zone 2 Cardio', desc: 'with number'),
        (name: 'Cold Exposure', desc: 'two words'),
        (name: 'A', desc: 'single character'),
        (name: 'A' * 100, desc: 'exactly 100 chars'),
      ];

      for (final c in validCases) {
        test('create_when${c.desc}_succeeds', () {
          // Act
          final result = ProtocolNameFactory.create(c.name);

          // Assert
          expect(result, isRight<ProtocolName>());
        });
      }
    });

    group('create fails', () {
      test('create_whenEmpty_returnsNameEmpty', () {
        // Act
        final result = ProtocolNameFactory.create(TestConstants.protocol.emptyName);

        // Assert
        expect(result, isLeftWith(ProtocolFailures.nameEmpty));
      });

      test('create_whenTooLong_returnsNameTooLong', () {
        // Act
        final result = ProtocolNameFactory.create(TestConstants.protocol.tooLongName);

        // Assert
        expect(result, isLeftWith(ProtocolFailures.nameTooLong));
      });

      // INV-P3: Researcher name patterns
      group('create_whenContainsResearcher', () {
        final researcherCases = [
          (
            name: "Huberman's Protocol",
            desc: 'possessiveForm',
          ),
          (
            name: "Sinclair's Method",
            desc: 'possessiveWithMethod',
          ),
          (
            name: 'Dr. Sinclair',
            desc: 'doctorPrefixWithPeriod',
          ),
          (
            name: 'Dr Huberman',
            desc: 'doctorPrefixWithoutPeriod',
          ),
          (
            name: 'The Huberman Protocol',
            desc: 'theNameProtocol',
          ),
          (
            name: 'The Sinclair Method',
            desc: 'theNameMethod',
          ),
        ];

        for (final c in researcherCases) {
          test('create_when${c.desc}_returnsNameContainsResearcher', () {
            // Act
            final result = ProtocolNameFactory.create(c.name);

            // Assert
            expect(result, isLeftWith(ProtocolFailures.nameContainsResearcher));
          });
        }
      });
    });

    group('toString', () {
      test('toString_returnsUnderlyingValue', () {
        // Arrange
        const expectedName = 'Norwegian 4x4 HIIT';
        final protocolName = ProtocolNameFactory.valid();

        // Act & Assert
        expect(protocolName.toString(), expectedName);
      });
    });
  });
}
