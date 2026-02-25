import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/data/dtos/target_dto.dart';
import 'package:neurostack/features/protocol/domain/value_objects/target.dart';

import '../../../../factories/dtos/dtos.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('TargetDto', () {
    group('toDomain', () {
      test('toDomain_whenValid_returnsTarget', () {
        // Arrange
        final dto = TargetDtoFactory.create();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<Target>());
      });

      test('toDomain_whenInvalidFrequency_returnsFailure', () {
        // Arrange
        final dto = TargetDtoFactory.createWithInvalidFrequency();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<Target>('Protocol.InvalidFrequency'));
      });

      test('toDomain_whenMaxLessThanMin_returnsFailure', () {
        // Arrange
        final dto = TargetDtoFactory.createWithMaxLessThanMin();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<Target>('Protocol.MaxLessThanMin'));
      });

      test('toDomain_whenNullDuration_succeedsWithNullDuration', () {
        // Arrange
        final dto = TargetDtoFactory.createWithNullDuration();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<Target>());
        final target = result.getOrElse(
          (l) => throw Exception('Failed: $l'),
        );
        expect(target.duration, isNull);
      });
    });

    group('fromJson', () {
      test('fromJson_whenValid_returnsDto', () {
        // Arrange
        final json = TargetDtoFactory.createValidJson();

        // Act
        final dto = TargetDto.fromJson(json);

        // Assert
        expect(dto.durationSeconds, 1800);
        expect(dto.intensity, 'moderate');
      });

      test('fromJson_whenMissingFrequency_throws', () {
        // Arrange
        final json = TargetDtoFactory.createJsonMissingField('frequency');

        // Act & Assert
        expect(() => TargetDto.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('fromDomain roundtrip', () {
      test('fromDomain_roundtrip_preservesDurationSeconds', () {
        // Arrange — create via DTO, convert to domain, convert back
        final original = TargetDtoFactory.create(durationSeconds: 1800);
        final domainResult = original.toDomain();
        expect(domainResult, isRight<Target>());
        final domain = domainResult.getOrElse(
          (l) => throw Exception('Failed: $l'),
        );

        // Act
        final restored = TargetDto.fromDomain(domain);

        // Assert — key regression gate: durationSeconds survives the roundtrip
        expect(restored.durationSeconds, 1800);
        expect(restored.intensity, original.intensity);
      });

      test('fromJson_toJson_roundtrip_preservesDurationSecondsKey', () {
        // Arrange — this guards against duration_seconds vs durationSeconds mismatch
        final json = TargetDtoFactory.createValidJson(durationSeconds: 2700);

        // Act
        final dto = TargetDto.fromJson(json);
        final reserialized = dto.toJson();

        // Assert — the JSON key must be camelCase 'durationSeconds'
        expect(reserialized.containsKey('durationSeconds'), true);
        expect(reserialized['durationSeconds'], 2700);
        expect(reserialized.containsKey('duration_seconds'), false);
      });
    });
  });
}
