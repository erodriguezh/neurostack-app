import 'package:fpdart/fpdart.dart';
import '../../../../core/failures/domain_failure.dart';
import '../entities/session.dart';
import '../entities/session_draft.dart';

/// Repository interface for Session aggregate persistence.
///
/// Defines the contract for session storage and retrieval operations.
/// All methods return `Either<DomainFailure, T>` to handle errors at domain level.
abstract interface class SessionRepository {
  /// Retrieves a single session by its unique identifier.
  ///
  /// Returns [DomainFailure] if the session is not found or if an
  /// infrastructure error occurs.
  Future<Either<DomainFailure, Session>> getById(String id);

  /// Queries sessions with optional filters.
  ///
  /// Parameters:
  /// - [protocolId]: Filter sessions by protocol (for protocol-specific history)
  /// - [from]: Start of date range (inclusive) for completedAt
  /// - [to]: End of date range (inclusive) for completedAt
  ///
  /// Multiple filters combine with AND logic.
  /// Returns an empty list if no sessions match the criteria.
  /// Date range filtering is critical for streak calculation and weekly/monthly views.
  Future<Either<DomainFailure, List<Session>>> list({
    String? protocolId,
    DateTime? from,
    DateTime? to,
  });

  /// Creates a session and returns the persisted aggregate with server ID.
  ///
  /// Sessions are immutable after creation, so this is insert-only.
  /// Returns [DomainFailure] on infrastructure errors.
  Future<Either<DomainFailure, Session>> create(SessionDraft session);
}
