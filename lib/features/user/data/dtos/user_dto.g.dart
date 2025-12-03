// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  id: json['id'] as String,
  subscriptionStatus: json['subscriptionStatus'] as String,
  trialPeriod: json['trialPeriod'] == null
      ? null
      : TrialPeriodDto.fromJson(json['trialPeriod'] as Map<String, dynamic>),
  protocolIds: (json['protocolIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  onboardingCompleted: json['onboardingCompleted'] as bool,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'subscriptionStatus': instance.subscriptionStatus,
  'trialPeriod': instance.trialPeriod,
  'protocolIds': instance.protocolIds,
  'onboardingCompleted': instance.onboardingCompleted,
  'createdAt': instance.createdAt,
};
