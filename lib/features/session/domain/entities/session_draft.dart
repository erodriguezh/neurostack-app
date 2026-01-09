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

  /// Creates a draft session with domain validation.
  ///
  /// Enforces **INV-S2**: [completedAt] cannot be in the future.
  ///
  /// - [currentTime]: Injected for testability (instead of DateTime.now())
  ///
  /// Returns [Left] with [SessionFailures.timestampInFuture] if completedAt > currentTime.
  static Either<DomainFailure, SessionDraft> create({
    required String protocolId,
    required DateTime completedAt,
    required DateTime currentTime,
    SessionDuration? duration,
    String? notes,
  }) {
    if (completedAt.isAfter(currentTime)) {
      return left(SessionFailures.timestampInFuture);
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

