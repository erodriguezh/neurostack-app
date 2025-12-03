// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProtocolDto _$ProtocolDtoFromJson(Map<String, dynamic> json) => _ProtocolDto(
  id: json['id'] as String,
  name: json['name'] as String,
  target: TargetDto.fromJson(json['target'] as Map<String, dynamic>),
  category: json['category'] as String,
  evidenceLevel: json['evidenceLevel'] as String,
  citations: (json['citations'] as List<dynamic>)
      .map((e) => ResearchCitationDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] as String,
  deletedAt: json['deletedAt'] as String?,
);

Map<String, dynamic> _$ProtocolDtoToJson(_ProtocolDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'target': instance.target,
      'category': instance.category,
      'evidenceLevel': instance.evidenceLevel,
      'citations': instance.citations,
      'createdAt': instance.createdAt,
      'deletedAt': instance.deletedAt,
    };
