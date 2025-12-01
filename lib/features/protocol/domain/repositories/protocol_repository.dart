import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/domain_failure.dart';
import '../entities/protocol.dart';
import '../enums/category.dart';
import '../enums/evidence_level.dart';

/// Repository interface for Protocol aggregate persistence.
///
/// Defines the contract for protocol storage and retrieval operations.
/// All methods return `Either<DomainFailure, T>` to handle errors at domain level.
abstract interface class ProtocolRepository {
  /// Retrieves a single protocol by its unique identifier.
  ///
  /// Returns [DomainFailure] if the protocol is not found or if an
  /// infrastructure error occurs.
  Future<Either<DomainFailure, Protocol>> getById(String id);

  /// Queries protocols with optional filters.
  ///
  /// Parameters:
  /// - [category]: Filter by protocol category (exercise, heatTherapy, etc.)
  /// - [evidenceLevel]: Filter by scientific backing strength
  /// - [activeOnly]: When `true`, exclude soft-deleted protocols
  ///
  /// Multiple filters combine with AND logic.
  /// Returns an empty list if no protocols match the criteria.
  Future<Either<DomainFailure, List<Protocol>>> list({
    Category? category,
    EvidenceLevel? evidenceLevel,
    bool? activeOnly,
  });

  /// Persists a protocol (insert or update).
  ///
  /// For soft-deletion, call `Protocol.softDelete()` first, then save.
  /// Returns [Unit] on success, [DomainFailure] on infrastructure errors.
  Future<Either<DomainFailure, Unit>> save(Protocol protocol);
}
