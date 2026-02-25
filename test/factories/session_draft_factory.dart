import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/entities/session_draft.dart';
import 'package:neurostack/features/session/domain/value_objects/session_duration.dart';
import '../constants/test_constants.dart';
import 'factory_helpers.dart';

abstract final class SessionDraftFactory {
  /// Creates a valid SessionDraft with all invariants satisfied.
  static Either<DomainFailure, SessionDraft> create({
    String? protocolId,
    DateTime? completedAt,
    DateTime? currentTime,
    SessionDuration? duration,
    String? notes,
  }) {
    return SessionDraft.create(
      protocolId: protocolId ?? TestConstants.session.protocolId,
      completedAt: completedAt ?? TestConstants.session.validCompletedAt,
      currentTime: currentTime ?? TestConstants.session.currentTime,
      duration: duration,
      notes: notes,
    );
  }

  /// Creates a valid SessionDraft (unwrapped, throws on failure).
  /// Use for setup when you know the draft is valid.
  static SessionDraft valid({
    String? protocolId,
    DateTime? completedAt,
    DateTime? currentTime,
    SessionDuration? duration,
    String? notes,
  }) {
    return unwrapOrThrow(
      create(
        protocolId: protocolId,
        completedAt: completedAt,
        currentTime: currentTime,
        duration: duration,
        notes: notes,
      ),
      'SessionDraft',
    );
  }
}
