// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  id: _stringFromJson(json['id']),
  subscriptionStatus: _stringFromJson(json['subscription_status']),
  protocolIds: _protocolIdsFromJson(json['protocol_ids']),
  onboardingCompleted: json['onboarding_completed'] as bool,
  createdAt: _stringFromJson(json['created_at']),
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'subscription_status': instance.subscriptionStatus,
  'protocol_ids': _protocolIdsToJson(instance.protocolIds),
  'onboarding_completed': instance.onboardingCompleted,
  'created_at': instance.createdAt,
};
