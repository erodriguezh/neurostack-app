// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProtocolDto _$ProtocolDtoFromJson(Map<String, dynamic> json) => _ProtocolDto(
  id: _stringFromJson(json['id']),
  name: json['name'] as String,
  description: json['description'] as String,
  target: TargetDto.fromJson(json['target'] as Map<String, dynamic>),
  category: json['category'] as String,
  evidenceLevel: json['evidence_level'] as String,
  citations: (json['research_citations'] as List<dynamic>)
      .map((e) => ResearchCitationDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] as String,
  deletedAt: json['deleted_at'] as String?,
);

Map<String, dynamic> _$ProtocolDtoToJson(_ProtocolDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'target': instance.target,
      'category': instance.category,
      'evidence_level': instance.evidenceLevel,
      'research_citations': instance.citations,
      'created_at': instance.createdAt,
      'deleted_at': instance.deletedAt,
    };
