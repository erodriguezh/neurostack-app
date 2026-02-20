import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../../core/models/common/aggregate_root.dart';
import '../../../../core/models/common/entity.dart';
import '../enums/category.dart';
import '../enums/evidence_level.dart';
import '../events/protocol_events.dart';
import '../failures/protocol_failures.dart';
import '../value_objects/protocol_name.dart';
import '../value_objects/research_citation.dart';
import '../value_objects/target.dart';

/// Protocol Aggregate Root - A science-backed routine with specific parameters.
///
/// Key Invariants:
/// - **INV-P1**: Every Protocol MUST have at least one Research Citation
/// - **INV-P2**: Protocol Target specifications MUST be measurable (enforced by Target VO)
/// - **INV-P3**: Protocol names MUST NOT include researcher names (enforced by ProtocolName VO)
/// - **INV-P4**: Deleted Protocols MUST preserve historical Session data (soft delete)
///
/// Example: "Norwegian 4x4 HIIT: 4x4 min at 90-95% max HR, 3x/week"
class Protocol with EntityMixin<String>, AggregateRootMixin<String> {
  Protocol._({
    required this.id,
    required this.name,
    required this.target,
    required this.category,
    required this.evidenceLevel,
    required List<ResearchCitation> citations,
    required this.createdAt,
    this.deletedAt,
  }) : _citations = List.unmodifiable(citations),
       isActive = deletedAt == null;

  @override
  final String id;

  final ProtocolName name;
  final Target target;
  final Category category;
  final EvidenceLevel evidenceLevel;
  final List<ResearchCitation> _citations;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final bool isActive;

  /// Unmodifiable list of research citations backing this protocol.
  List<ResearchCitation> get citations => _citations;

  /// Creates a new Protocol aggregate.
  ///
  /// Enforces **INV-P1**: [citations] list must not be empty.
  ///
  /// Returns [Left] with [ProtocolFailures.noCitations] if citations is empty.
  static Either<DomainFailure, Protocol> create({
    required String id,
    required ProtocolName name,
    required Target target,
    required Category category,
    required EvidenceLevel evidenceLevel,
    required List<ResearchCitation> citations,
    DateTime? createdAt,
  }) {
    // INV-P1: Every Protocol MUST have at least one Research Citation
    if (citations.isEmpty) {
      return left(ProtocolFailures.noCitations);
    }

    final protocol = Protocol._(
      id: id,
      name: name,
      target: target,
      category: category,
      evidenceLevel: evidenceLevel,
      citations: citations,
      createdAt: createdAt ?? DateTime.now(),
    );

    protocol.raiseDomainEvent(ProtocolCreatedEvent(protocolId: id));

    return right(protocol);
  }

  /// Reconstitutes a Protocol from persistence (no events raised, no validation).
  ///
  /// Use this when loading from database where invariants were already validated.
  factory Protocol.reconstitute({
    required String id,
    required ProtocolName name,
    required Target target,
    required Category category,
    required EvidenceLevel evidenceLevel,
    required List<ResearchCitation> citations,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) {
    return Protocol._(
      id: id,
      name: name,
      target: target,
      category: category,
      evidenceLevel: evidenceLevel,
      citations: citations,
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }

  /// Soft deletes the protocol, preserving session history.
  ///
  /// Enforces **INV-P4**: Historical Session data must be preserved.
  ///
  /// Returns [Left] with [ProtocolFailures.alreadyDeleted] if already deleted.
  Either<DomainFailure, Protocol> softDelete({required DateTime currentTime}) {
    if (!isActive) {
      return left(ProtocolFailures.alreadyDeleted);
    }

    final deleted = Protocol._(
      id: id,
      name: name,
      target: target,
      category: category,
      evidenceLevel: evidenceLevel,
      citations: _citations,
      createdAt: createdAt,
      deletedAt: currentTime,
    );

    deleted.raiseDomainEvent(ProtocolDeletedEvent(protocolId: id));

    return right(deleted);
  }
}
