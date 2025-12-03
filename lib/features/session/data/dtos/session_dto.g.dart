// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => _SessionDto(
  id: json['id'] as String,
  protocolId: json['protocolId'] as String,
  completedAt: json['completedAt'] as String,
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$SessionDtoToJson(_SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'protocolId': instance.protocolId,
      'completedAt': instance.completedAt,
      'durationSeconds': instance.durationSeconds,
      'notes': instance.notes,
    };
