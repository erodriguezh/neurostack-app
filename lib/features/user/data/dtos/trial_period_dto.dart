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
    @JsonKey(name: 'start_date') required String startDate,
  }) = _TrialPeriodDto;

  factory TrialPeriodDto.fromJson(Map<String, dynamic> json) =>
      _$TrialPeriodDtoFromJson(json);

  /// Converts this DTO to the domain [TrialPeriod] value object.
  ///
  /// Returns [Left] with parse failure if date format is invalid.
  Either<DomainFailure, TrialPeriod> toDomain() {
    try {
      final parsedDate = DateTime.parse(startDate);
      return right(TrialPeriod.fromStartDate(parsedDate));
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Dto.InvalidDateFormat',
          message: 'Failed to parse trial start date: $startDate',
        ),
      );
    }
  }

  /// Creates a DTO from a domain [TrialPeriod] value object.
  factory TrialPeriodDto.fromDomain(TrialPeriod trial) {
    return TrialPeriodDto(startDate: trial.startDate.toIso8601String());
  }
}
