import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/target.dart';
import 'frequency_dto.dart';

part 'target_dto.freezed.dart';
part 'target_dto.g.dart';

/// DTO for [Target] value object serialization.
///
/// Stores duration as seconds (int) for JSON-friendly serialization.
/// Supports **INV-P2**: Protocol Target specifications MUST be measurable.
@freezed
abstract class TargetDto with _$TargetDto {
  const TargetDto._();

  const factory TargetDto({
    required FrequencyDto frequency,
    int? durationSeconds,
    String? intensity,
  }) = _TargetDto;

  factory TargetDto.fromJson(Map<String, dynamic> json) =>
      _$TargetDtoFromJson(json);

  /// Converts this DTO to the domain [Target] value object.
  ///
  /// Returns [Left] with validation failure if:
  /// - Frequency validation fails (min < 1, max < min)
  Either<DomainFailure, Target> toDomain() {
    return frequency.toDomain().flatMap((domainFrequency) {
      final duration = durationSeconds != null
          ? Duration(seconds: durationSeconds!)
          : null;

      return Target.create(
        frequency: domainFrequency,
        duration: duration,
        intensity: intensity,
      );
    });
  }

  /// Creates a DTO from a domain [Target] value object.
  factory TargetDto.fromDomain(Target target) {
    return TargetDto(
      frequency: FrequencyDto.fromDomain(target.frequency),
      durationSeconds: target.duration?.inSeconds,
      intensity: target.intensity,
    );
  }
}
