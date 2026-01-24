import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/data/dtos/trial_period_dto.dart';
import 'package:neurostack/features/user/domain/value_objects/trial_period.dart';

import '../../../../matchers/either_matchers.dart';

void main() {
  group('TrialPeriodDto', () {
    group('toDomain', () {
      test('toDomain_withEndDatePresent_usesDbValue', () {
        // Arrange - DTO with explicit end_date from database
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);
        // Use a non-standard end date (10 days instead of 7) to prove
        // we use the DB value, not compute it
        final customEndDate = DateTime(2025, 1, 11, 10, 0, 0);

        final dto = TrialPeriodDto(
          startDate: startDate.toIso8601String(),
          endDate: customEndDate.toIso8601String(),
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<TrialPeriod>());
        result.match(
          (_) => fail('Expected Right'),
          (trial) {
            expect(trial.startDate, startDate);
            expect(trial.endDate, customEndDate);
            // Verify it's NOT the computed value (start + 7 days)
            final computedEnd =
                startDate.add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(trial.endDate, isNot(equals(computedEnd)));
          },
        );
      });

      test('toDomain_withEndDateNull_fallsBackToComputed', () {
        // Arrange - DTO without end_date (legacy data or missing column)
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);

        final dto = TrialPeriodDto(
          startDate: startDate.toIso8601String(),
          endDate: null,
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<TrialPeriod>());
        result.match(
          (_) => fail('Expected Right'),
          (trial) {
            expect(trial.startDate, startDate);
            // Should compute end date as start + 7 days
            final expectedEnd =
                startDate.add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(trial.endDate, expectedEnd);
          },
        );
      });

      test('toDomain_withEmptyEndDate_fallsBackToComputed', () {
        // Arrange - DTO with empty string end_date (edge case)
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);

        final dto = TrialPeriodDto(
          startDate: startDate.toIso8601String(),
          endDate: '',
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<TrialPeriod>());
        result.match(
          (_) => fail('Expected Right'),
          (trial) {
            final expectedEnd =
                startDate.add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(trial.endDate, expectedEnd);
          },
        );
      });

      test('toDomain_withWhitespaceEndDate_fallsBackToComputed', () {
        // Arrange - DTO with whitespace-only end_date (edge case)
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);

        final dto = TrialPeriodDto(
          startDate: startDate.toIso8601String(),
          endDate: '   ',
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<TrialPeriod>());
        result.match(
          (_) => fail('Expected Right'),
          (trial) {
            final expectedEnd =
                startDate.add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(trial.endDate, expectedEnd);
          },
        );
      });

      test('toDomain_withInvalidStartDate_returnsFailure', () {
        // Arrange
        const dto = TrialPeriodDto(
          startDate: 'not-a-date',
          endDate: null,
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<TrialPeriod>('Dto.InvalidDateFormat'));
      });

      test('toDomain_withInvalidEndDate_returnsFailure', () {
        // Arrange
        final dto = TrialPeriodDto(
          startDate: DateTime(2025, 1, 1).toIso8601String(),
          endDate: 'not-a-date',
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<TrialPeriod>('Dto.InvalidDateFormat'));
      });
    });

    group('fromDomain', () {
      test('fromDomain_roundtrip_preservesEndDate', () {
        // Arrange - Create domain entity with specific dates
        final startDate = DateTime(2025, 6, 15, 12, 0, 0);
        final endDate = DateTime(2025, 6, 22, 12, 0, 0);
        final original = TrialPeriod.fromDates(
          startDate: startDate,
          endDate: endDate,
        );

        // Act - Round-trip through DTO
        final dto = TrialPeriodDto.fromDomain(original);
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<TrialPeriod>());
        result.match(
          (_) => fail('Expected Right'),
          (restored) {
            expect(restored.startDate, original.startDate);
            expect(restored.endDate, original.endDate);
          },
        );
      });

      test('fromDomain_serializesEndDate', () {
        // Arrange
        final startDate = DateTime(2025, 3, 10, 8, 30, 0);
        final endDate = DateTime(2025, 3, 17, 8, 30, 0);
        final trial = TrialPeriod.fromDates(
          startDate: startDate,
          endDate: endDate,
        );

        // Act
        final dto = TrialPeriodDto.fromDomain(trial);

        // Assert - endDate should be serialized as ISO 8601 string
        expect(dto.endDate, isNotNull);
        expect(dto.endDate, endDate.toIso8601String());
        expect(dto.startDate, startDate.toIso8601String());
      });
    });

    group('fromJson', () {
      test('fromJson_withEndDate_parsesBothDates', () {
        // Arrange
        final json = {
          'start_date': '2025-01-01T10:00:00.000',
          'end_date': '2025-01-08T10:00:00.000',
        };

        // Act
        final dto = TrialPeriodDto.fromJson(json);

        // Assert
        expect(dto.startDate, '2025-01-01T10:00:00.000');
        expect(dto.endDate, '2025-01-08T10:00:00.000');
      });

      test('fromJson_withoutEndDate_leavesEndDateNull', () {
        // Arrange
        final json = {
          'start_date': '2025-01-01T10:00:00.000',
        };

        // Act
        final dto = TrialPeriodDto.fromJson(json);

        // Assert
        expect(dto.startDate, '2025-01-01T10:00:00.000');
        expect(dto.endDate, isNull);
      });

      test('fromJson_withNullEndDate_leavesEndDateNull', () {
        // Arrange
        final json = <String, dynamic>{
          'start_date': '2025-01-01T10:00:00.000',
          'end_date': null,
        };

        // Act
        final dto = TrialPeriodDto.fromJson(json);

        // Assert
        expect(dto.endDate, isNull);
      });
    });

    group('toJson', () {
      test('toJson_includesEndDate', () {
        // Arrange
        const dto = TrialPeriodDto(
          startDate: '2025-01-01T10:00:00.000',
          endDate: '2025-01-08T10:00:00.000',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['start_date'], '2025-01-01T10:00:00.000');
        expect(json['end_date'], '2025-01-08T10:00:00.000');
      });

      test('toJson_withNullEndDate_includesNullEndDate', () {
        // Arrange
        const dto = TrialPeriodDto(
          startDate: '2025-01-01T10:00:00.000',
          endDate: null,
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['start_date'], '2025-01-01T10:00:00.000');
        expect(json.containsKey('end_date'), true);
        expect(json['end_date'], isNull);
      });
    });
  });
}
