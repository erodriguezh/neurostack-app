import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../user/domain/repositories/user_repository.dart';

/// Parameters for checking session logging eligibility.
class CheckEligibilityParams {
  const CheckEligibilityParams({
    required this.userId,
    required this.protocolId,
  });

  final String userId;
  final String protocolId;
}

/// Use case for checking if a user can log a session.
///
/// Gates the Log Session modal by validating:
/// - User exists and is loaded
/// - User.canLogSession() passes (INV-U4: onboarding, protocol stack invariants)
///
/// Note: Time-based trial expiration (INV-U5) is enforced by
/// [SubscriptionStatusResolver] / RevenueCat. This use case trusts the
/// persisted [subscriptionStatus] on the User.
///
/// This use case exists to pre-validate eligibility before opening the modal,
/// avoiding a poor UX where the user fills out a form only to be rejected.
class CheckEligibilityUseCase {
  const CheckEligibilityUseCase({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  final UserRepository _userRepository;

  /// Executes the eligibility check.
  ///
  /// Returns [Right(unit)] if user can log a session, [Left(DomainFailure)] if:
  /// - User not found (from UserRepository)
  /// - Onboarding not completed (INV-U4)
  /// - Protocol not in stack
  /// - Too many active protocols for the current subscription tier
  Future<Either<DomainFailure, Unit>> execute(
    CheckEligibilityParams params,
  ) async {
    final userResult = await _userRepository.getById(params.userId);

    return userResult.flatMap(
      (user) => user.canLogSession(params.protocolId),
    );
  }
}
