// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frequency_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FrequencyDto _$FrequencyDtoFromJson(Map<String, dynamic> json) =>
    _FrequencyDto(
      minPerWeek: (json['minPerWeek'] as num).toInt(),
      maxPerWeek: (json['maxPerWeek'] as num).toInt(),
    );

Map<String, dynamic> _$FrequencyDtoToJson(_FrequencyDto instance) =>
    <String, dynamic>{
      'minPerWeek': instance.minPerWeek,
      'maxPerWeek': instance.maxPerWeek,
    };
