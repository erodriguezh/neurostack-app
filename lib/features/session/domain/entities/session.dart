import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../../core/models/common/aggregate_root.dart';
import '../../../../core/models/common/entity.dart';
import '../events/session_events.dart';
import '../failures/session_failures.dart';
import '../value_objects/session_duration.dart';

/// Session Aggregate Root - A single instance of completing a protocol.
///
/// Key Invariants:
/// - **INV-S1**: A Session MUST belong to exactly one Protocol (by ID reference)
/// - **INV-S2**: Session timestamp CANNOT be in the future
/// - **INV-S3**: Session duration MUST be > 0 if specified (enforced by SessionDuration VO)
/// - **INV-S4**: Session timestamp CANNOT be more than 7 days in the past
///
/// Example: "Sauna session on Nov 21, 2025, 22 minutes"
class Session with EntityMixin<String>, AggregateRootMixin<String> {
  Session._({
    required this.id,
    required this.protocolId,
    required this.completedAt,
    this.duration,
    this.notes,
  });

  @override
  final String id;

  /// Reference to the protocol this session belongs to.
  /// Enforces **INV-S1**: A Session MUST belong to exactly one Protocol.
  final String protocolId;

  /// When the session was completed.
  /// Enforces **INV-S2**: Cannot be in the future.
  final DateTime completedAt;

  /// Optional duration of the session.
  /// Enforces **INV-S3**: Must be > 0 if specified (via SessionDuration VO).
  final SessionDuration? duration;

  /// Optional notes about the session.
  final String? notes;

  /// Maximum number of days in the past a session can be logged.
  static const maxBackdateDays = 7;

  /// Creates a new Session aggregate.
  ///
  /// Enforces:
  /// - **INV-S2**: [completedAt] cannot be in the future
  /// - **INV-S4**: [completedAt] cannot be more than 7 days in the past
  ///
  /// - [currentTime]: Injected for testability (instead of DateTime.now())
  /// - Use [SessionDraft] when the ID is server-generated.
  ///
  /// Returns [Left] with [SessionFailures.timestampInFuture] if completedAt > currentTime.
  /// Returns [Left] with [SessionFailures.dateTooOld] if completedAt < currentTime - 7 days.
  static Either<DomainFailure, Session> create({
    required String id,
    required String protocolId,
    required DateTime completedAt,
    SessionDuration? duration,
    String? notes,
    required DateTime currentTime,
  }) {
    // INV-S2: Session timestamp CANNOT be in the future
    if (completedAt.isAfter(currentTime)) {
      return left(SessionFailures.timestampInFuture);
    }

    // INV-S4: Session timestamp CANNOT be more than 7 days in the past
    final oldestAllowed = currentTime.subtract(
      const Duration(days: maxBackdateDays),
    );
    if (completedAt.isBefore(oldestAllowed)) {
      return left(SessionFailures.dateTooOld);
    }

    final trimmedNotes = notes?.trim();

    final session = Session._(
      id: id,
      protocolId: protocolId,
      completedAt: completedAt,
      duration: duration,
      notes: trimmedNotes?.isEmpty == true ? null : trimmedNotes,
    );

    session.raiseLoggedEvent();

    return right(session);
  }

  /// Reconstitutes a Session from persistence (no events raised, no validation).
  ///
  /// Use this when loading from database where invariants were already validated.
  factory Session.reconstitute({
    required String id,
    required String protocolId,
    required DateTime completedAt,
    SessionDuration? duration,
    String? notes,
  }) {
    return Session._(
      id: id,
      protocolId: protocolId,
      completedAt: completedAt,
      duration: duration,
      notes: notes,
    );
  }

  /// Raises the domain event for a logged session.
  void raiseLoggedEvent() {
    raiseDomainEvent(
      SessionLoggedEvent(
        sessionId: id,
        protocolId: protocolId,
        completedAt: completedAt,
      ),
    );
  }
}
