import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/trial_period.dart';

part 'trial_period_dto.freezed.dart';
part 'trial_period_dto.g.dart';

/// DTO for [TrialPeriod] value object serialization.
///
/// Stores date as ISO 8601 string for universal JSON serialization.
/// Supports **INV-M2**: Premium Trial MUST last exactly 7 days.
@freezed
abstract class TrialPeriodDto with _$TrialPeriodDto {
  const TrialPeriodDto._();

  const factory TrialPeriodDto({
    @JsonKey(name: 'start_date', fromJson: _stringFromJson)
    required String startDate,
    @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson)
    String? endDate,
  }) = _TrialPeriodDto;

  factory TrialPeriodDto.fromJson(Map<String, dynamic> json) =>
      _$TrialPeriodDtoFromJson(json);

  /// Converts this DTO to the domain [TrialPeriod] value object.
  ///
  /// If [endDate] is present, uses it directly via [TrialPeriod.fromDates].
  /// Otherwise, falls back to computing end date from start date.
  ///
  /// Returns [Left] with parse failure if date format is invalid.
  Either<DomainFailure, TrialPeriod> toDomain() {
    try {
      final parsedStartDate = DateTime.parse(startDate);
      // Treat null or empty/whitespace endDate as missing, fall back to computed
      final rawEnd = endDate;
      final parsedEndDate = (rawEnd == null || rawEnd.trim().isEmpty)
          ? parsedStartDate
              .add(const Duration(days: TrialPeriod.trialDurationDays))
          : DateTime.parse(rawEnd);
      return right(TrialPeriod.fromDates(
        startDate: parsedStartDate,
        endDate: parsedEndDate,
      ));
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Dto.InvalidDateFormat',
          message: 'Failed to parse trial dates: $e',
        ),
      );
    }
  }

  /// Creates a DTO from a domain [TrialPeriod] value object.
  factory TrialPeriodDto.fromDomain(TrialPeriod trial) {
    return TrialPeriodDto(
      startDate: trial.startDate.toIso8601String(),
      endDate: trial.endDate.toIso8601String(),
    );
  }
}

String _stringFromJson(dynamic raw) {
  if (raw == null) {
    return '';
  }
  return raw.toString();
}

String? _nullableStringFromJson(dynamic raw) {
  if (raw == null) return null;
  return raw.toString();
}
