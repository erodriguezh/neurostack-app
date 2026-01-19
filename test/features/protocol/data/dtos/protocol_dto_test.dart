import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/data/dtos/protocol_dto.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/dtos/dtos.dart';
import '../../../../factories/protocol_factory.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('ProtocolDto', () {
    group('toDomain', () {
      test('toDomain_whenValid_returnsProtocol', () {
        // Arrange
        final dto = ProtocolDtoFactory.create();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<Protocol>());
      });

      // Parameterized invalid field tests
      final invalidCases = [
        (
          factory: ProtocolDtoFactory.createWithInvalidName,
          code: 'Protocol.NameTooLong',
        ),
        (
          factory: ProtocolDtoFactory.createWithResearcherName,
          code: 'Protocol.NameContainsResearcher',
        ),
        (
          factory: ProtocolDtoFactory.createWithInvalidCategory,
          code: 'Dto.InvalidCategory',
        ),
        (
          factory: ProtocolDtoFactory.createWithInvalidEvidenceLevel,
          code: 'Dto.InvalidEvidenceLevel',
        ),
        (
          factory: ProtocolDtoFactory.createWithInvalidTarget,
          code: 'Protocol.InvalidFrequency',
        ),
        (
          factory: ProtocolDtoFactory.createWithInvalidCitation,
          code: 'Protocol.CitationAuthorsEmpty',
        ),
      ];

      for (final c in invalidCases) {
        test('toDomain_when${c.code.split('.').last}_returnsFailure', () {
          // Arrange
          final dto = c.factory();

          // Act
          final result = dto.toDomain();

          // Assert
          expect(result, isLeftWithCode<Protocol>(c.code));
        });
      }

      test('toDomain_whenInvalidDateTime_returnsParseError', () {
        // Arrange
        final dto = ProtocolDtoFactory.createWithInvalidDateTime();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<Protocol>('Dto.ParseError'));
      });
    });

    group('fromJson', () {
      // Note: 'id' is excluded because _stringFromJson returns '' for null
      // instead of throwing. The domain validation catches empty ids.
      final requiredFields = [
        'name',
        'target',
        'category',
        'evidence_level',
        'research_citations',
        'created_at',
      ];

      for (final field in requiredFields) {
        test('fromJson_whenMissing${_pascalCase(field)}_throws', () {
          // Arrange
          final json = ProtocolDtoFactory.createJsonMissingField(field);

          // Act & Assert
          expect(() => ProtocolDto.fromJson(json), throwsA(isA<TypeError>()));
        });
      }

      test('fromJson_whenValid_returnsDto', () {
        // Arrange
        final json = ProtocolDtoFactory.createValidJson();

        // Act
        final dto = ProtocolDto.fromJson(json);

        // Assert
        expect(dto.id, TestConstants.dto.defaultProtocolId);
        expect(dto.name, TestConstants.protocol.validName);
        expect(dto.category, 'exercise');
      });

      test('fromJson_withNullDeletedAt_succeeds', () {
        // Arrange
        final json = ProtocolDtoFactory.createValidJson();
        json['deleted_at'] = null;

        // Act
        final dto = ProtocolDto.fromJson(json);

        // Assert
        expect(dto.deletedAt, isNull);
      });
    });

    group('fromDomain', () {
      test('fromDomain_roundtrip_preservesData', () {
        // Arrange - Create valid domain entity
        final domainResult = ProtocolFactory.create();

        expect(
          domainResult.isRight(),
          true,
          reason: 'Domain entity creation should succeed',
        );

        final original = domainResult.getRight().toNullable()!;

        // Act
        final dto = ProtocolDto.fromDomain(original);
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<Protocol>());
        result.match(
          (_) => fail('Expected Right'),
          (restored) {
            expect(restored.id, original.id);
            expect(restored.name.value, original.name.value);
            expect(restored.category, original.category);
            expect(restored.evidenceLevel, original.evidenceLevel);
            expect(restored.citations.length, original.citations.length);
          },
        );
      });

      test('fromDomain_withDeletedProtocol_preservesDeletedAt', () {
        // Arrange - Create and soft-delete a protocol
        final domainResult = ProtocolFactory.create();

        final protocol = domainResult.getRight().toNullable()!;
        final deletedResult = protocol.softDelete(
          currentTime: DateTime(2025, 1, 15),
        );
        final deleted = deletedResult.getRight().toNullable()!;

        // Act
        final dto = ProtocolDto.fromDomain(deleted);

        // Assert
        expect(dto.deletedAt, isNotNull);
      });
    });
  });
}

/// Converts snake_case to PascalCase for test naming.
String _pascalCase(String snakeCase) {
  return snakeCase
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
