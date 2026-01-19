// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingSessionDto _$PendingSessionDtoFromJson(Map<String, dynamic> json) =>
    _PendingSessionDto(
      localId: json['local_id'] as String,
      userId: json['user_id'] as String,
      protocolId: json['protocol_id'] as String,
      completedAt: json['completed_at'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      retryCount: (json['retry_count'] as num).toInt(),
    );

Map<String, dynamic> _$PendingSessionDtoToJson(_PendingSessionDto instance) =>
    <String, dynamic>{
      'local_id': instance.localId,
      'user_id': instance.userId,
      'protocol_id': instance.protocolId,
      'completed_at': instance.completedAt,
      'duration_seconds': ?instance.durationSeconds,
      'notes': ?instance.notes,
      'created_at': instance.createdAt,
      'retry_count': instance.retryCount,
    };
