// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequency_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FrequencyDto _$FrequencyDtoFromJson(Map<String, dynamic> json) =>
    _FrequencyDto(
      minPerWeek: (json['min_per_week'] as num).toInt(),
      maxPerWeek: (json['max_per_week'] as num).toInt(),
    );

Map<String, dynamic> _$FrequencyDtoToJson(_FrequencyDto instance) =>
    <String, dynamic>{
      'min_per_week': instance.minPerWeek,
      'max_per_week': instance.maxPerWeek,
    };
