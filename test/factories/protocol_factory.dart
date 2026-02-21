import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_name.dart';
import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';
import 'package:neurostack/features/protocol/domain/value_objects/target.dart';
import '../constants/test_constants.dart';
import 'value_objects/protocol_description_factory.dart';
import 'value_objects/protocol_name_factory.dart';
import 'value_objects/research_citation_factory.dart';
import 'value_objects/target_factory.dart';

abstract final class ProtocolFactory {
  /// Creates a valid Protocol (all invariants satisfied).
  static Either<DomainFailure, Protocol> create({
    String? id,
    ProtocolName? name,
    ProtocolDescription? description,
    Target? target,
    Category category = Category.exercise,
    EvidenceLevel evidenceLevel = EvidenceLevel.multipleRcts,
    List<ResearchCitation>? citations,
    DateTime? createdAt,
  }) {
    return Protocol.create(
      id: id ?? TestConstants.protocol.id,
      name: name ?? ProtocolNameFactory.valid(),
      description: description ?? ProtocolDescriptionFactory.valid(),
      target: target ?? TargetFactory.valid(),
      category: category,
      evidenceLevel: evidenceLevel,
      citations: citations ?? [ResearchCitationFactory.valid()],
      createdAt: createdAt ?? TestConstants.protocol.createdAt,
    );
  }

  /// Reconstitutes a Protocol (for testing queries, not creation).
  static Protocol reconstitute({
    String? id,
    ProtocolName? name,
    ProtocolDescription? description,
    Target? target,
    Category category = Category.exercise,
    EvidenceLevel evidenceLevel = EvidenceLevel.multipleRcts,
    List<ResearchCitation>? citations,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Protocol.reconstitute(
      id: id ?? TestConstants.protocol.id,
      name: name ?? ProtocolNameFactory.valid(),
      description: description ?? ProtocolDescriptionFactory.valid(),
      target: target ?? TargetFactory.valid(),
      category: category,
      evidenceLevel: evidenceLevel,
      citations: citations ?? [ResearchCitationFactory.valid()],
      createdAt: createdAt ?? TestConstants.protocol.createdAt,
      deletedAt: deletedAt,
    );
  }

  /// Creates a valid Protocol (unwrapped, throws on failure).
  /// Use for setup when you know the protocol is valid.
  static Protocol valid() {
    return create().getOrElse(
      (l) => throw Exception('Factory produced invalid Protocol: $l'),
    );
  }
}
