// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stack_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StackDto _$StackDtoFromJson(Map<String, dynamic> json) => _StackDto(
  protocolIds: (json['protocolIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$StackDtoToJson(_StackDto instance) => <String, dynamic>{
  'protocolIds': instance.protocolIds,
};
