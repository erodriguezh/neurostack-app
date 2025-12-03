// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TargetDto _$TargetDtoFromJson(Map<String, dynamic> json) => _TargetDto(
  frequency: FrequencyDto.fromJson(json['frequency'] as Map<String, dynamic>),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  intensity: json['intensity'] as String?,
);

Map<String, dynamic> _$TargetDtoToJson(_TargetDto instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'durationSeconds': instance.durationSeconds,
      'intensity': instance.intensity,
    };
