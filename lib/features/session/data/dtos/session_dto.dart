import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/session.dart';
import '../../domain/value_objects/session_duration.dart';

part 'session_dto.freezed.dart';
part 'session_dto.g.dart';

/// DTO for [Session] aggregate serialization.
///
/// Stores date as ISO 8601 string and duration as seconds for JSON compatibility.
/// Uses [Session.reconstitute] to avoid raising domain events on load.
///
/// Flattens [SessionDuration] to `durationSeconds` since it's a single field.
///
/// Supports:
/// - **INV-S1**: A Session MUST belong to exactly one Protocol
/// - **INV-S2**: Session timestamp CANNOT be in the future
/// - **INV-S3**: Session duration MUST be > 0 if specified
@freezed
abstract class SessionDto with _$SessionDto {
  const SessionDto._();

  const factory SessionDto({
    @JsonKey(fromJson: _stringFromJson) required String id,
    @JsonKey(name: 'protocol_id', fromJson: _stringFromJson)
    required String protocolId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'completed_at') required String completedAt,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    String? notes,
  }) = _SessionDto;

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  /// Converts this DTO to the domain [Session] aggregate.
  ///
  /// Uses [Session.reconstitute] since data comes from persistence
  /// where invariants were already validated. Does not raise domain events.
  ///
  /// Returns [Left] with validation failure if:
  /// - Duration validation fails (must be > 0 if specified)
  /// - Date parsing fails
  Either<DomainFailure, Session> toDomain() {
    try {
      // Parse duration if present
      SessionDuration? domainDuration;
      if (durationSeconds != null) {
        final durationResult = SessionDuration.create(
          Duration(seconds: durationSeconds!),
        );
        if (durationResult.isLeft()) {
          return left(
            durationResult.getLeft().getOrElse(
              () => throw StateError('Unreachable'),
            ),
          );
        }
        domainDuration = durationResult.getOrElse(
          (l) => throw StateError('Unreachable'),
        );
      }

      // Parse date
      final completedAtDate = DateTime.parse(completedAt);

      // Reconstitute (not create) to avoid domain events
      return right(
        Session.reconstitute(
          id: id,
          protocolId: protocolId,
          completedAt: completedAtDate,
          duration: domainDuration,
          notes: notes,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Dto.ParseError',
          message: 'Failed to parse SessionDto: $e',
        ),
      );
    }
  }

  /// Creates a DTO from a domain [Session] aggregate.
  factory SessionDto.fromDomain(Session session, String userId) {
    return SessionDto(
      id: session.id,
      protocolId: session.protocolId,
      userId: userId,
      completedAt: session.completedAt.toIso8601String(),
      durationSeconds: session.duration?.inSeconds,
      notes: session.notes,
    );
  }
}

String _stringFromJson(dynamic raw) {
  if (raw == null) {
    return '';
  }
  return raw.toString();
}
