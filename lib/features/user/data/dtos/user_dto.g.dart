// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  id: _stringFromJson(json['id']),
  subscriptionStatus: _stringFromJson(json['subscription_status']),
  trialPeriod: json['trial_period'] == null
      ? null
      : TrialPeriodDto.fromJson(json['trial_period'] as Map<String, dynamic>),
  trialEndsAt: _nullableDateTimeFromJson(json['trial_ends_at']),
  protocolIds: _protocolIdsFromJson(json['protocol_ids']),
  onboardingCompleted: json['onboarding_completed'] as bool,
  createdAt: _stringFromJson(json['created_at']),
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'subscription_status': instance.subscriptionStatus,
  'trial_period': instance.trialPeriod,
  'trial_ends_at': instance.trialEndsAt?.toIso8601String(),
  'protocol_ids': _protocolIdsToJson(instance.protocolIds),
  'onboarding_completed': instance.onboardingCompleted,
  'created_at': instance.createdAt,
};
