import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/session_draft.dart';

part 'session_insert_dto.freezed.dart';
part 'session_insert_dto.g.dart';

/// DTO for inserting a new session (no server-generated ID).
@freezed
abstract class SessionInsertDto with _$SessionInsertDto {
  const SessionInsertDto._();

  @JsonSerializable(includeIfNull: false)
  const factory SessionInsertDto({
    @JsonKey(name: 'protocol_id') required String protocolId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'completed_at') required String completedAt,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    String? notes,
  }) = _SessionInsertDto;

  factory SessionInsertDto.fromJson(Map<String, dynamic> json) =>
      _$SessionInsertDtoFromJson(json);

  /// Creates an insert DTO from a validated [SessionDraft].
  ///
  /// Stores timestamps in UTC for consistent storage and portability.
  /// This aligns with the UTC policy used in [SessionDto.fromDomain]
  /// and [PendingSessionDto.fromDomain].
  factory SessionInsertDto.fromDraft(SessionDraft session, String userId) {
    return SessionInsertDto(
      protocolId: session.protocolId,
      userId: userId,
      completedAt: session.completedAt.toUtc().toIso8601String(),
      durationSeconds: session.duration?.inSeconds,
      notes: session.notes,
    );
  }
}
