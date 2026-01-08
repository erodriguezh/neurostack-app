// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => _SessionDto(
  id: _stringFromJson(json['id']),
  protocolId: _stringFromJson(json['protocol_id']),
  userId: json['user_id'] as String,
  completedAt: json['completed_at'] as String,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SessionDtoToJson(_SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'protocol_id': instance.protocolId,
      'user_id': instance.userId,
      'completed_at': instance.completedAt,
      'duration_seconds': instance.durationSeconds,
      'notes': instance.notes,
    };
