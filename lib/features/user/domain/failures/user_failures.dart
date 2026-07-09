import '../../../../core/failures/domain_failure.dart';

/// Domain failures specific to the User aggregate.
///
/// Naming convention: `User.{Invariant}`
abstract final class UserFailures {
  // Protocol management - INV-U1, INV-M5, INV-B2
  static const protocolLimitReached = DomainFailure(
    code: 'User.ProtocolLimitReached',
    message: 'Upgrade to Premium to activate more than 2 protocols',
  );

  static const protocolAlreadyActive = DomainFailure(
    code: 'User.ProtocolAlreadyActive',
    message: 'This protocol is already in your stack',
  );

  static const protocolNotActive = DomainFailure(
    code: 'User.ProtocolNotActive',
    message: 'This protocol is not in your stack',
  );

  static const invalidProtocolLimitSelection = DomainFailure(
    code: 'User.InvalidProtocolLimitSelection',
    message: 'Choose exactly 2 protocols to keep',
  );

  static const duplicateProtocolSelection = DomainFailure(
    code: 'User.DuplicateProtocolSelection',
    message: 'Choose each protocol only once',
  );

  // Session logging - INV-U4
  // Note: Trial expiration gating (INV-U5) is enforced by SubscriptionStatusResolver.
  static const onboardingNotCompleted = DomainFailure(
    code: 'User.OnboardingNotCompleted',
    message: 'Complete onboarding to start tracking sessions',
  );

  static const tooManyActiveProtocols = DomainFailure(
    code: 'User.TooManyActiveProtocols',
    message: 'Deactivate protocols or upgrade to continue logging',
  );

  static const protocolNotInStack = DomainFailure(
    code: 'User.ProtocolNotInStack',
    message: 'Cannot log session for protocol not in your stack',
  );

  static const alreadyOnboarded = DomainFailure(
    code: 'User.AlreadyOnboarded',
    message: 'Onboarding has already been completed',
  );
}
