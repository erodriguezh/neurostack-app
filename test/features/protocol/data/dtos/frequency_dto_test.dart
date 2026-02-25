import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/data/dtos/frequency_dto.dart';
import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';

import '../../../../factories/dtos/dtos.dart';
import '../../../../helpers/helpers.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('FrequencyDto', () {
    group('toDomain', () {
      test('toDomain_whenValid_returnsFrequency', () {
        // Arrange
        final dto = FrequencyDtoFactory.create();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<Frequency>());
      });

      test('toDomain_whenInvalidMin_returnsFailure', () {
        // Arrange
        final dto = FrequencyDtoFactory.createWithInvalidMin();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(
          result,
          isLeftWithCode<Frequency>('Protocol.InvalidFrequency'),
        );
      });

      test('toDomain_whenMaxLessThanMin_returnsFailure', () {
        // Arrange
        final dto = FrequencyDtoFactory.createWithMaxLessThanMin();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<Frequency>('Protocol.MaxLessThanMin'));
      });
    });

    group('fromJson', () {
      test('fromJson_whenValid_returnsDto', () {
        // Arrange
        final json = FrequencyDtoFactory.createValidJson();

        // Act
        final dto = FrequencyDto.fromJson(json);

        // Assert
        expect(dto.minPerWeek, 3);
        expect(dto.maxPerWeek, 4);
      });

      final requiredFields = ['min_per_week', 'max_per_week'];

      for (final field in requiredFields) {
        test('fromJson_whenMissing${pascalCase(field)}_throws', () {
          // Arrange
          final json = FrequencyDtoFactory.createJsonMissingField(field);

          // Act & Assert
          expect(
            () => FrequencyDto.fromJson(json),
            throwsA(isA<TypeError>()),
          );
        });
      }
    });

    group('fromDomain roundtrip', () {
      test('fromDomain_roundtrip_preservesValues', () {
        // Arrange
        final original = FrequencyDtoFactory.create(
          minPerWeek: 2,
          maxPerWeek: 5,
        );
        final domainResult = original.toDomain();
        expect(domainResult, isRight<Frequency>());
        final domain = domainResult.getOrElse(
          (l) => throw Exception('Failed: $l'),
        );

        // Act
        final restored = FrequencyDto.fromDomain(domain);

        // Assert
        expect(restored.minPerWeek, 2);
        expect(restored.maxPerWeek, 5);
      });

      test('fromJson_toJson_roundtrip_preservesSnakeCaseKeys', () {
        // Arrange — guards @JsonKey snake_case mapping
        final json = FrequencyDtoFactory.createValidJson(
          minPerWeek: 1,
          maxPerWeek: 7,
        );

        // Act
        final dto = FrequencyDto.fromJson(json);
        final reserialized = dto.toJson();

        // Assert — keys must be snake_case per @JsonKey annotations
        expect(reserialized.containsKey('min_per_week'), true);
        expect(reserialized.containsKey('max_per_week'), true);
        expect(reserialized['min_per_week'], 1);
        expect(reserialized['max_per_week'], 7);
      });
    });
  });
}
