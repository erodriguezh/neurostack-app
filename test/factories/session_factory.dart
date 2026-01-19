import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/value_objects/session_duration.dart';
import '../constants/test_constants.dart';
import 'value_objects/session_duration_factory.dart';

abstract final class SessionFactory {
  /// Creates a valid Session with all invariants satisfied.
  static Either<DomainFailure, Session> create({
    String? id,
    String? protocolId,
    DateTime? completedAt,
    DateTime? currentTime,
    SessionDuration? duration,
    String? notes,
  }) {
    return Session.create(
      id: id ?? TestConstants.session.id,
      protocolId: protocolId ?? TestConstants.session.protocolId,
      completedAt: completedAt ?? TestConstants.session.validCompletedAt,
      currentTime: currentTime ?? TestConstants.session.currentTime,
      duration: duration,
      notes: notes,
    );
  }

  /// Reconstitutes a Session (for testing queries, not creation).
  static Session reconstitute({
    String? id,
    String? protocolId,
    DateTime? completedAt,
    SessionDuration? duration,
    String? notes,
  }) {
    return Session.reconstitute(
      id: id ?? TestConstants.session.id,
      protocolId: protocolId ?? TestConstants.session.protocolId,
      completedAt: completedAt ?? TestConstants.session.validCompletedAt,
      duration: duration,
      notes: notes,
    );
  }

  /// Creates a valid Session (unwrapped, throws on failure).
  /// Use for setup when you know the session is valid.
  static Session valid() {
    return create().getOrElse(
      (l) => throw Exception('Factory produced invalid Session: $l'),
    );
  }

  /// Creates a Session with a future timestamp (for testing INV-S2).
  static Either<DomainFailure, Session> withFutureTimestamp() {
    return Session.create(
      id: TestConstants.session.id,
      protocolId: TestConstants.session.protocolId,
      completedAt: TestConstants.session.futureCompletedAt,
      currentTime: TestConstants.session.currentTime,
    );
  }

  /// Creates a Session with a too-old timestamp (for testing INV-S4).
  static Either<DomainFailure, Session> withTooOldTimestamp() {
    return Session.create(
      id: TestConstants.session.id,
      protocolId: TestConstants.session.protocolId,
      completedAt: TestConstants.session.tooOldCompletedAt,
      currentTime: TestConstants.session.currentTime,
    );
  }

  /// Creates a Session with exactly 7 days ago timestamp (boundary test).
  static Either<DomainFailure, Session> withExactlySevenDaysAgo() {
    return Session.create(
      id: TestConstants.session.id,
      protocolId: TestConstants.session.protocolId,
      completedAt: TestConstants.session.exactlySevenDaysAgo,
      currentTime: TestConstants.session.currentTime,
    );
  }

  /// Creates a Session with optional duration.
  static Either<DomainFailure, Session> withDuration({
    required Duration duration,
  }) {
    final sessionDuration = SessionDurationFactory.create(duration);

    return sessionDuration.flatMap(
      (dur) => Session.create(
        id: TestConstants.session.id,
        protocolId: TestConstants.session.protocolId,
        completedAt: TestConstants.session.validCompletedAt,
        currentTime: TestConstants.session.currentTime,
        duration: dur,
      ),
    );
  }
}
