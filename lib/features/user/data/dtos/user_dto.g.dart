// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  id: json['id'] as String,
  subscriptionStatus: json['subscription_status'] as String,
  trialPeriod: json['trial_period'] == null
      ? null
      : TrialPeriodDto.fromJson(json['trial_period'] as Map<String, dynamic>),
  protocolIds: (json['protocol_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  onboardingCompleted: json['onboarding_completed'] as bool,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'subscription_status': instance.subscriptionStatus,
  'trial_period': instance.trialPeriod,
  'protocol_ids': instance.protocolIds,
  'onboarding_completed': instance.onboardingCompleted,
  'created_at': instance.createdAt,
};
