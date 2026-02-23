import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/protocol.dart';
import '../../domain/enums/category.dart';
import '../../domain/enums/evidence_level.dart';
import '../../domain/value_objects/protocol_description.dart';
import '../../domain/value_objects/protocol_name.dart';
import '../../domain/value_objects/research_citation.dart';
import 'research_citation_dto.dart';
import 'target_dto.dart';

part 'protocol_dto.freezed.dart';
part 'protocol_dto.g.dart';

/// DTO for [Protocol] aggregate serialization.
///
/// Stores enums as strings and dates as ISO 8601 for JSON compatibility.
/// Uses [Protocol.reconstitute] to avoid raising domain events on load.
///
/// Supports:
/// - **INV-P1**: Every Protocol MUST have at least one Research Citation
/// - **INV-P2**: Protocol Target specifications MUST be measurable
/// - **INV-P3**: Protocol names MUST NOT include researcher names
@freezed
abstract class ProtocolDto with _$ProtocolDto {
  const ProtocolDto._();

  const factory ProtocolDto({
    @JsonKey(fromJson: _stringFromJson) required String id,
    required String name,
    required String description,
    required TargetDto target,
    required String category,
    @JsonKey(name: 'evidence_level') required String evidenceLevel,
    @JsonKey(name: 'research_citations')
    required List<ResearchCitationDto> citations,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'deleted_at') String? deletedAt,
  }) = _ProtocolDto;

  factory ProtocolDto.fromJson(Map<String, dynamic> json) =>
      _$ProtocolDtoFromJson(json);

  /// Converts this DTO to the domain [Protocol] aggregate.
  ///
  /// Uses fpdart `Either.Do` notation (first usage in this codebase) for
  /// concise short-circuit-on-Left semantics. The `$` extractor unwraps
  /// `Right` values and automatically short-circuits to `Left` on failure.
  /// See: https://pub.dev/packages/fpdart#do-notation
  ///
  /// Uses [Protocol.reconstitute] since data comes from persistence
  /// where invariants were already validated. Does not raise domain events.
  ///
  /// Returns [Left] with validation failure if:
  /// - Name validation fails
  /// - Target validation fails
  /// - Category enum parsing fails
  /// - EvidenceLevel enum parsing fails
  /// - Any citation validation fails
  /// - Date parsing fails
  Either<DomainFailure, Protocol> toDomain() {
    return Either<DomainFailure, Protocol>.Do(($) {
      final domainName = $(ProtocolName.create(name));
      final domainDescription = $(ProtocolDescription.create(description));
      final domainTarget = $(target.toDomain());
      final domainCategory = $(_parseEnum(
        Category.values,
        category,
        'Dto.InvalidCategory',
        'Invalid category: $category',
      ));
      final domainEvidenceLevel = $(_parseEnum(
        EvidenceLevel.values,
        evidenceLevel,
        'Dto.InvalidEvidenceLevel',
        'Invalid evidence level: $evidenceLevel',
      ));

      final domainCitations = <ResearchCitation>[];
      for (final c in citations) {
        domainCitations.add($(c.toDomain()));
      }

      final createdAtDate = $(_parseDateTime(createdAt));
      final deletedAtDate = deletedAt != null
          ? $(_parseDateTime(deletedAt!))
          : null;

      return Protocol.reconstitute(
        id: id,
        name: domainName,
        description: domainDescription,
        target: domainTarget,
        category: domainCategory,
        evidenceLevel: domainEvidenceLevel,
        citations: domainCitations,
        createdAt: createdAtDate,
        deletedAt: deletedAtDate,
      );
    });
  }

  /// Creates a DTO from a domain [Protocol] aggregate.
  factory ProtocolDto.fromDomain(Protocol protocol) {
    return ProtocolDto(
      id: protocol.id,
      name: protocol.name.value,
      description: protocol.description.value,
      target: TargetDto.fromDomain(protocol.target),
      category: protocol.category.name,
      evidenceLevel: protocol.evidenceLevel.name,
      citations: protocol.citations
          .map((c) => ResearchCitationDto.fromDomain(c))
          .toList(),
      createdAt: protocol.createdAt.toIso8601String(),
      deletedAt: protocol.deletedAt?.toIso8601String(),
    );
  }
}

/// Parses an enum value by name, returning [Left] with the given failure
/// code and message if the name does not match any enum value.
Either<DomainFailure, T> _parseEnum<T extends Enum>(
  List<T> values,
  String name,
  String code,
  String message,
) {
  try {
    return right(values.byName(name));
  } catch (_) {
    return left(DomainFailure(code: code, message: message));
  }
}

/// Parses an ISO 8601 date string, returning [Left] with `Dto.ParseError`
/// if parsing fails.
///
/// Extracted as a dedicated helper so DateTime parse exceptions are not caught
/// by the `Either.Do` short-circuit mechanism (which uses internal throws).
Either<DomainFailure, DateTime> _parseDateTime(String raw) {
  try {
    return right(DateTime.parse(raw));
  } catch (e) {
    return left(
      DomainFailure(
        code: 'Dto.ParseError',
        message: 'Failed to parse ProtocolDto: $e',
      ),
    );
  }
}

String _stringFromJson(dynamic raw) {
  if (raw == null) {
    return '';
  }
  return raw.toString();
}
