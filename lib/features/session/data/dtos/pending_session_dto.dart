import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/pending_session.dart';
import '../../domain/entities/session_draft.dart';
import '../../domain/value_objects/session_duration.dart';

part 'pending_session_dto.freezed.dart';
part 'pending_session_dto.g.dart';

/// DTO for [PendingSession] entity serialization to SharedPreferences.
///
/// Flattens [SessionDraft] fields into the DTO for simpler JSON storage.
/// Uses [PendingSession.reconstitute] and [SessionDraft.reconstitute] on load
/// to bypass validation (data was already validated when originally saved).
///
/// **Timestamps**: Stored as UTC ISO 8601 strings (with "Z" suffix) for
/// portability across devices/timezones. Converted to local time on load.
@freezed
abstract class PendingSessionDto with _$PendingSessionDto {
  const PendingSessionDto._();

  @JsonSerializable(includeIfNull: false)
  const factory PendingSessionDto({
    /// Client-generated UUID for local deduplication.
    @JsonKey(name: 'local_id') required String localId,

    /// User ID for multi-account safety.
    @JsonKey(name: 'user_id') required String userId,

    /// Protocol ID from the embedded SessionDraft.
    @JsonKey(name: 'protocol_id') required String protocolId,

    /// When the session was completed (ISO 8601 string).
    @JsonKey(name: 'completed_at') required String completedAt,

    /// Duration in seconds (from SessionDraft).
    @JsonKey(name: 'duration_seconds') int? durationSeconds,

    /// Optional notes (from SessionDraft).
    String? notes,

    /// When this pending session was created locally (ISO 8601 string).
    @JsonKey(name: 'created_at') required String createdAt,

    /// Number of failed sync attempts.
    @JsonKey(name: 'retry_count') required int retryCount,
  }) = _PendingSessionDto;

  factory PendingSessionDto.fromJson(Map<String, dynamic> json) =>
      _$PendingSessionDtoFromJson(json);

  /// Converts this DTO to the domain [PendingSession] entity.
  ///
  /// Uses [SessionDraft.reconstitute] and [PendingSession.reconstitute]
  /// to bypass validation since data was already validated when saved.
  PendingSession toDomain() {
    // Reconstitute duration if present
    SessionDuration? domainDuration;
    if (durationSeconds != null) {
      // Use internal create - if stored data is invalid, this will throw.
      // This is acceptable for corrupted data detection.
      final durationResult = SessionDuration.create(
        Duration(seconds: durationSeconds!),
      );
      domainDuration = durationResult.getOrElse(
        (failure) => throw StateError(
          'Corrupted pending session data: invalid duration $durationSeconds',
        ),
      );
    }

    // Reconstitute the SessionDraft (bypasses validation)
    // Parse UTC timestamps and convert to local time for domain use
    final draft = SessionDraft.reconstitute(
      protocolId: protocolId,
      completedAt: DateTime.parse(completedAt).toLocal(),
      duration: domainDuration,
      notes: notes,
    );

    // Reconstitute the PendingSession
    return PendingSession.reconstitute(
      localId: localId,
      userId: userId,
      draft: draft,
      createdAt: DateTime.parse(createdAt).toLocal(),
      retryCount: retryCount,
    );
  }

  /// Creates a DTO from a domain [PendingSession] entity.
  ///
  /// Timestamps are stored as UTC for portability.
  factory PendingSessionDto.fromDomain(PendingSession pending) {
    return PendingSessionDto(
      localId: pending.localId,
      userId: pending.userId,
      protocolId: pending.draft.protocolId,
      completedAt: pending.draft.completedAt.toUtc().toIso8601String(),
      durationSeconds: pending.draft.duration?.inSeconds,
      notes: pending.draft.notes,
      createdAt: pending.createdAt.toUtc().toIso8601String(),
      retryCount: pending.retryCount,
    );
  }
}
