// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trial_period_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrialPeriodDto _$TrialPeriodDtoFromJson(Map<String, dynamic> json) =>
    _TrialPeriodDto(
      startDate: _stringFromJson(json['start_date']),
      endDate: _nullableStringFromJson(json['end_date']),
    );

Map<String, dynamic> _$TrialPeriodDtoToJson(_TrialPeriodDto instance) =>
    <String, dynamic>{
      'start_date': instance.startDate,
      'end_date': instance.endDate,
    };
