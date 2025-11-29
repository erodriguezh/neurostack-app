import '../../../../core/models/common/domain_event.dart';
import '../enums/subscription_status.dart';

/// Raised when a new user is created.
class UserCreatedEvent extends DomainEvent {
  UserCreatedEvent({required this.userId});

  final String userId;

  @override
  String toString() => 'UserCreatedEvent(userId: $userId)';
}

/// Raised when a user's trial period begins.
class TrialStartedEvent extends DomainEvent {
  TrialStartedEvent({required this.userId});

  final String userId;

  @override
  String toString() => 'TrialStartedEvent(userId: $userId)';
}

/// Raised when a protocol is activated in user's stack.
class ProtocolActivatedEvent extends DomainEvent {
  ProtocolActivatedEvent({
    required this.userId,
    required this.protocolId,
  });

  final String userId;
  final String protocolId;

  @override
  String toString() =>
      'ProtocolActivatedEvent(userId: $userId, protocolId: $protocolId)';
}

/// Raised when a protocol is deactivated from user's stack.
class ProtocolDeactivatedEvent extends DomainEvent {
  ProtocolDeactivatedEvent({
    required this.userId,
    required this.protocolId,
  });

  final String userId;
  final String protocolId;

  @override
  String toString() =>
      'ProtocolDeactivatedEvent(userId: $userId, protocolId: $protocolId)';
}

/// Raised when user completes onboarding.
class OnboardingCompletedEvent extends DomainEvent {
  OnboardingCompletedEvent({required this.userId});

  final String userId;

  @override
  String toString() => 'OnboardingCompletedEvent(userId: $userId)';
}

/// Raised when user upgrades to premium subscription.
class SubscriptionUpgradedEvent extends DomainEvent {
  SubscriptionUpgradedEvent({
    required this.userId,
    required this.newStatus,
  });

  final String userId;
  final SubscriptionStatus newStatus;

  @override
  String toString() =>
      'SubscriptionUpgradedEvent(userId: $userId, newStatus: $newStatus)';
}
