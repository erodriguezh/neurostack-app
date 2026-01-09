// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_insert_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionInsertDto _$SessionInsertDtoFromJson(Map<String, dynamic> json) =>
    _SessionInsertDto(
      protocolId: json['protocol_id'] as String,
      userId: json['user_id'] as String,
      completedAt: json['completed_at'] as String,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SessionInsertDtoToJson(_SessionInsertDto instance) =>
    <String, dynamic>{
      'protocol_id': instance.protocolId,
      'user_id': instance.userId,
      'completed_at': instance.completedAt,
      'duration_seconds': ?instance.durationSeconds,
      'notes': ?instance.notes,
    };
