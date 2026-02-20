import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/session_failures.dart';
import '../value_objects/session_duration.dart';

/// Draft representation of a session before persistence assigns an ID.
///
/// Key Invariants:
/// - **INV-S1**: A Session MUST belong to exactly one Protocol (by ID reference)
/// - **INV-S2**: Session timestamp CANNOT be in the future
/// - **INV-S3**: Session duration MUST be > 0 if specified (enforced by SessionDuration VO)
/// - **INV-S4**: Session timestamp CANNOT be more than 7 days in the past
class SessionDraft {
  const SessionDraft._({
    required this.protocolId,
    required this.completedAt,
    this.duration,
    this.notes,
  });

  /// Reference to the protocol this session belongs to.
  final String protocolId;

  /// When the session was completed.
  final DateTime completedAt;

  /// Optional duration of the session.
  final SessionDuration? duration;

  /// Optional notes about the session.
  final String? notes;

  /// Maximum number of days in the past a session can be logged.
  static const maxBackdateDays = 7;

  /// Reconstitutes a draft from persistence (bypasses validation).
  ///
  /// Use this when loading from storage where data was already validated
  /// at creation time. Does not enforce INV-S2 or INV-S4.
  ///
  /// Notes are normalized (trimmed, empty-to-null) for consistency with [create].
  factory SessionDraft.reconstitute({
    required String protocolId,
    required DateTime completedAt,
    SessionDuration? duration,
    String? notes,
  }) {
    // Apply same notes normalization as create() for domain shape consistency
    final trimmedNotes = notes?.trim();

    return SessionDraft._(
      protocolId: protocolId,
      completedAt: completedAt,
      duration: duration,
      notes: trimmedNotes?.isEmpty == true ? null : trimmedNotes,
    );
  }

  /// Creates a draft session with domain validation.
  ///
  /// Enforces:
  /// - **INV-S2**: [completedAt] cannot be in the future
  /// - **INV-S4**: [completedAt] cannot be more than 7 days in the past
  ///
  /// - [currentTime]: Injected for testability (instead of DateTime.now())
  ///
  /// Returns [Left] with [SessionFailures.timestampInFuture] if completedAt > currentTime.
  /// Returns [Left] with [SessionFailures.dateTooOld] if completedAt < currentTime - 7 days.
  static Either<DomainFailure, SessionDraft> create({
    required String protocolId,
    required DateTime completedAt,
    required DateTime currentTime,
    SessionDuration? duration,
    String? notes,
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

    return right(
      SessionDraft._(
        protocolId: protocolId,
        completedAt: completedAt,
        duration: duration,
        notes: trimmedNotes?.isEmpty == true ? null : trimmedNotes,
      ),
    );
  }
}
