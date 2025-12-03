import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/frequency.dart';

part 'frequency_dto.freezed.dart';
part 'frequency_dto.g.dart';

/// DTO for [Frequency] value object serialization.
///
/// Maps directly between JSON and the domain [Frequency] type.
@freezed
abstract class FrequencyDto with _$FrequencyDto {
  const FrequencyDto._();

  const factory FrequencyDto({
    required int minPerWeek,
    required int maxPerWeek,
  }) = _FrequencyDto;

  factory FrequencyDto.fromJson(Map<String, dynamic> json) =>
      _$FrequencyDtoFromJson(json);

  /// Converts this DTO to the domain [Frequency] value object.
  ///
  /// Returns [Left] with validation failure if domain rules are violated.
  Either<DomainFailure, Frequency> toDomain() {
    return Frequency.create(
      minPerWeek: minPerWeek,
      maxPerWeek: maxPerWeek,
    );
  }

  /// Creates a DTO from a domain [Frequency] value object.
  factory FrequencyDto.fromDomain(Frequency frequency) {
    return FrequencyDto(
      minPerWeek: frequency.minPerWeek,
      maxPerWeek: frequency.maxPerWeek,
    );
  }
}
