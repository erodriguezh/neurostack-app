import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../user/domain/repositories/user_repository.dart';
import '../entities/session.dart';
import '../entities/session_draft.dart';
import '../repositories/session_repository.dart';
import '../value_objects/session_duration.dart';

/// Parameters for logging a session.
///
/// Encapsulates all required inputs for the log session operation.
///
/// Note: Session IDs are generated server-side. This use case builds a
/// [SessionDraft] and relies on persistence to assign the final ID.
class LogSessionParams {
  const LogSessionParams({
    required this.userId,
    required this.protocolId,
    required this.completedAt,
    required this.currentTime,
    this.duration,
    this.notes,
  });

  final String userId;
  final String protocolId;
  final DateTime completedAt;
  final DateTime currentTime; // Injected for testability
  final SessionDuration? duration;
  final String? notes;
}

/// Use case for logging a session.
///
/// Coordinates User and Session repositories with domain validation:
/// 1. Load user (UserRepository.getById)
/// 2. Validate session logging eligibility (User.canLogSession)
/// 3. Create session draft (SessionDraft.create)
/// 4. Persist session (SessionRepository.create)
///
/// This use case exists because it coordinates 2 repositories with domain
/// validation in between, following the use case justification criteria.
class LogSessionUseCase {
  const LogSessionUseCase({
    required UserRepository userRepository,
    required SessionRepository sessionRepository,
  })  : _userRepository = userRepository,
        _sessionRepository = sessionRepository;

  final UserRepository _userRepository;
  final SessionRepository _sessionRepository;

  /// Executes the log session operation.
  ///
  /// Returns [Session] on success, [DomainFailure] if:
  /// - User not found (from UserRepository)
  /// - User cannot log session (INV-U4: onboarding, INV-U5: trial expired)
  /// - Session validation fails (INV-S2: timestamp in future)
  /// - Create operation fails (from SessionRepository)
  Future<Either<DomainFailure, Session>> execute(LogSessionParams params) async {
    // Step 1: Load user (async)
    final userResult = await _userRepository.getById(params.userId);

    // Steps 2-3: Chain sync validations with flatMap
    final sessionDraftResult = userResult
        .flatMap((user) => user.canLogSession(
              params.protocolId,
              currentTime: params.currentTime,
            ))
        .flatMap((_) => SessionDraft.create(
              protocolId: params.protocolId,
              completedAt: params.completedAt,
              currentTime: params.currentTime,
              duration: params.duration,
              notes: params.notes,
            ));

    // Step 4: Handle async save with pattern matching
    return switch (sessionDraftResult) {
      Left(:final value) => left(value),
      Right(:final value) => (await _sessionRepository.create(value)).map(
          (session) {
            session.raiseLoggedEvent();
            return session;
          },
        ),
    };
  }
}
