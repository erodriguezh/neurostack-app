// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'research_citation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResearchCitationDto _$ResearchCitationDtoFromJson(Map<String, dynamic> json) =>
    _ResearchCitationDto(
      authors: json['authors'] as String,
      year: (json['year'] as num).toInt(),
      title: json['title'] as String,
      journal: json['journal'] as String,
      doi: json['doi'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$ResearchCitationDtoToJson(
  _ResearchCitationDto instance,
) => <String, dynamic>{
  'authors': instance.authors,
  'year': instance.year,
  'title': instance.title,
  'journal': instance.journal,
  'doi': instance.doi,
  'url': instance.url,
};
