import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/protocol.dart';
import '../../domain/enums/category.dart';
import '../../domain/enums/evidence_level.dart';
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
    required String id,
    required String name,
    required TargetDto target,
    required String category,
    required String evidenceLevel,
    required List<ResearchCitationDto> citations,
    required String createdAt,
    String? deletedAt,
  }) = _ProtocolDto;

  factory ProtocolDto.fromJson(Map<String, dynamic> json) =>
      _$ProtocolDtoFromJson(json);

  /// Converts this DTO to the domain [Protocol] aggregate.
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
    try {
      // Parse name
      final nameResult = ProtocolName.create(name);
      if (nameResult.isLeft()) {
        return left(
          nameResult.getLeft().getOrElse(() => throw StateError('Unreachable')),
        );
      }
      final domainName = nameResult.getOrElse(
        (l) => throw StateError('Unreachable'),
      );

      // Parse target
      final targetResult = target.toDomain();
      if (targetResult.isLeft()) {
        return left(
          targetResult.getLeft().getOrElse(
            () => throw StateError('Unreachable'),
          ),
        );
      }
      final domainTarget = targetResult.getOrElse(
        (l) => throw StateError('Unreachable'),
      );

      // Parse category enum
      final Category domainCategory;
      try {
        domainCategory = Category.values.byName(category);
      } catch (_) {
        return left(
          DomainFailure(
            code: 'Dto.InvalidCategory',
            message: 'Invalid category: $category',
          ),
        );
      }

      // Parse evidence level enum
      final EvidenceLevel domainEvidenceLevel;
      try {
        domainEvidenceLevel = EvidenceLevel.values.byName(evidenceLevel);
      } catch (_) {
        return left(
          DomainFailure(
            code: 'Dto.InvalidEvidenceLevel',
            message: 'Invalid evidence level: $evidenceLevel',
          ),
        );
      }

      // Parse all citations
      final domainCitations = <ResearchCitation>[];
      for (final citationDto in citations) {
        final citationResult = citationDto.toDomain();
        if (citationResult.isLeft()) {
          return left(
            citationResult.getLeft().getOrElse(
              () => throw StateError('Unreachable'),
            ),
          );
        }
        domainCitations.add(
          citationResult.getOrElse((l) => throw StateError('Unreachable')),
        );
      }

      // Parse dates
      final createdAtDate = DateTime.parse(createdAt);
      final deletedAtDate = deletedAt != null
          ? DateTime.parse(deletedAt!)
          : null;

      // Reconstitute (not create) to avoid domain events
      return right(
        Protocol.reconstitute(
          id: id,
          name: domainName,
          target: domainTarget,
          category: domainCategory,
          evidenceLevel: domainEvidenceLevel,
          citations: domainCitations,
          createdAt: createdAtDate,
          deletedAt: deletedAtDate,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Dto.ParseError',
          message: 'Failed to parse ProtocolDto: $e',
        ),
      );
    }
  }

  /// Creates a DTO from a domain [Protocol] aggregate.
  factory ProtocolDto.fromDomain(Protocol protocol) {
    return ProtocolDto(
      id: protocol.id,
      name: protocol.name.value,
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
