import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/research_citation.dart';

part 'research_citation_dto.freezed.dart';
part 'research_citation_dto.g.dart';

/// DTO for [ResearchCitation] value object serialization.
///
/// Maps between JSON and the domain [ResearchCitation] type.
/// Supports **INV-P1**: Every Protocol MUST have at least one Research Citation.
@freezed
abstract class ResearchCitationDto with _$ResearchCitationDto {
  const ResearchCitationDto._();

  const factory ResearchCitationDto({
    required String authors,
    required int year,
    required String title,
    required String journal,
    String? doi,
    String? url,
  }) = _ResearchCitationDto;

  factory ResearchCitationDto.fromJson(Map<String, dynamic> json) =>
      _$ResearchCitationDtoFromJson(json);

  /// Converts this DTO to the domain [ResearchCitation] value object.
  ///
  /// Returns [Left] with validation failure if domain rules are violated:
  /// - Authors cannot be empty
  /// - Title cannot be empty
  /// - Journal cannot be empty
  /// - Year must be between 1900 and next year
  Either<DomainFailure, ResearchCitation> toDomain() {
    return ResearchCitation.create(
      authors: authors,
      year: year,
      title: title,
      journal: journal,
      doi: doi,
      url: url,
    );
  }

  /// Creates a DTO from a domain [ResearchCitation] value object.
  factory ResearchCitationDto.fromDomain(ResearchCitation citation) {
    return ResearchCitationDto(
      authors: citation.authors,
      year: citation.year,
      title: citation.title,
      journal: citation.journal,
      doi: citation.doi,
      url: citation.url,
    );
  }
}
