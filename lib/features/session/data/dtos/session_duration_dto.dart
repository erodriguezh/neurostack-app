import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/session_duration.dart';

part 'session_duration_dto.freezed.dart';
part 'session_duration_dto.g.dart';

/// DTO for [SessionDuration] value object serialization.
///
/// Stores duration as seconds (int) for JSON-friendly serialization.
/// Supports **INV-S3**: Session duration MUST be > 0 if specified.
@freezed
abstract class SessionDurationDto with _$SessionDurationDto {
  const SessionDurationDto._();

  const factory SessionDurationDto({
    required int seconds,
  }) = _SessionDurationDto;

  factory SessionDurationDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDurationDtoFromJson(json);

  /// Converts this DTO to the domain [SessionDuration] value object.
  ///
  /// Returns [Left] with validation failure if duration <= 0.
  Either<DomainFailure, SessionDuration> toDomain() {
    return SessionDuration.create(Duration(seconds: seconds));
  }

  /// Creates a DTO from a domain [SessionDuration] value object.
  factory SessionDurationDto.fromDomain(SessionDuration duration) {
    return SessionDurationDto(seconds: duration.value.inSeconds);
  }
}
