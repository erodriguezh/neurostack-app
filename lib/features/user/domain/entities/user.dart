import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../../../core/models/common/aggregate_root.dart';
import '../../../../core/models/common/entity.dart';
import '../enums/subscription_status.dart';
import '../events/user_events.dart';
import '../failures/user_failures.dart';
import '../value_objects/stack.dart';

/// User Aggregate Root - Manages user's stack, persisted subscription status,
/// and onboarding state.
///
/// This aggregate enforces:
/// - **INV-U1**: Users CANNOT activate beyond the supplied protocol limit
/// - **INV-U2**: A null supplied limit allows unlimited protocols
/// - **INV-U4**: Users MUST complete onboarding before tracking Sessions
/// - **INV-M1**: Free Tier MUST have no time limit
/// - **INV-M5**: Free Tier users CANNOT activate more than 2 protocols
/// - **INV-B2**: Paywall MUST trigger when Free Tier user tries 3rd protocol
/// - **INV-B5**: Users MUST be able to use Free Tier indefinitely
/// - **INV-P6**: New users MUST start with `free` status (not `trial`)
///
/// Entitlement resolution is external. This aggregate receives the resolved
/// protocol limit as input and remains independent of RevenueCat types.
class User with EntityMixin<String>, AggregateRootMixin<String> {
  User._({
    required this.id,
    required this.subscriptionStatus,
    required Stack stack,
    required this.onboardingCompleted,
    required this.createdAt,
  }) : _stack = stack;

  @override
  final String id;

  /// Current subscription status as persisted.
  ///
  /// Gating decisions are resolved externally from this persisted fallback.
  final SubscriptionStatus subscriptionStatus;

  /// User's active protocol collection.
  final Stack _stack;

  /// Whether onboarding has been completed (INV-U4).
  final bool onboardingCompleted;

  /// When the user was created.
  final DateTime createdAt;

  /// Unmodifiable list of active protocol IDs.
  List<String> get activeProtocolIds => _stack.protocolIds;

  /// Number of active protocols.
  int get activeProtocolCount => _stack.count;

  /// Creates a new User with free subscription status.
  ///
  /// Enforces **INV-P6**: New users MUST start with `free` status.
  /// Trial activation is now managed by RevenueCat, not auto-activated
  /// on first app launch. INV-U3 (DEPRECATED).
  ///
  /// This is the primary factory for new users.
  static User create({
    required String id,
    DateTime? createdAt,
  }) {
    final effectiveCreatedAt = createdAt ?? DateTime.now();
    final user = User._(
      id: id,
      subscriptionStatus: SubscriptionStatus.free,
      stack: Stack.empty(),
      onboardingCompleted: false,
      createdAt: effectiveCreatedAt,
    );

    user.raiseDomainEvent(UserCreatedEvent(userId: id));

    return user;
  }

  /// Reconstitutes a User from persistence (no events raised, no validation).
  factory User.reconstitute({
    required String id,
    required SubscriptionStatus subscriptionStatus,
    required Stack stack,
    required bool onboardingCompleted,
    required DateTime createdAt,
  }) {
    return User._(
      id: id,
      subscriptionStatus: subscriptionStatus,
      stack: stack,
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
    );
  }

  /// Activates a protocol in the user's stack.
  ///
  /// Enforces:
  /// - **INV-U1**: Free tier has 2 protocol limit
  /// - **INV-U2**: Trial/Premium has unlimited protocols
  /// - **INV-M5/B2**: Shows paywall when free tier user tries 3rd protocol
  ///
  /// Returns [Left] with:
  /// - [UserFailures.protocolAlreadyActive] if already in stack
  /// - [UserFailures.protocolLimitReached] if at limit
  Either<DomainFailure, User> activateProtocol(
    String protocolId, {
    required int? limit,
  }) {
    // Check if already active
    if (_stack.contains(protocolId)) {
      return left(UserFailures.protocolAlreadyActive);
    }

    // INV-U1, INV-M5, INV-B2: Check protocol limit
    if (limit != null && _stack.count >= limit) {
      return left(UserFailures.protocolLimitReached);
    }

    final updated = User._(
      id: id,
      subscriptionStatus: subscriptionStatus,
      stack: _stack.add(protocolId),
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
    );

    updated.raiseDomainEvent(
      ProtocolActivatedEvent(
        userId: id,
        protocolId: protocolId,
      ),
    );

    return right(updated);
  }

  /// Deactivates a protocol from the user's stack.
  ///
  /// Returns [Left] with [UserFailures.protocolNotActive] if not in stack.
  Either<DomainFailure, User> deactivateProtocol(String protocolId) {
    if (!_stack.contains(protocolId)) {
      return left(UserFailures.protocolNotActive);
    }

    final updated = User._(
      id: id,
      subscriptionStatus: subscriptionStatus,
      stack: _stack.remove(protocolId),
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
    );

    updated.raiseDomainEvent(
      ProtocolDeactivatedEvent(
        userId: id,
        protocolId: protocolId,
      ),
    );

    return right(updated);
  }

  /// Applies the free-tier protocol limit by keeping exactly two active
  /// protocols and deactivating every other active protocol.
  ///
  /// The user's subscription status is intentionally unchanged; subscription
  /// state is written by the webhook, not client-side downgrade flows.
  Either<DomainFailure, User> applyProtocolLimitSelection(
    List<String> keepIds,
  ) {
    if (keepIds.length != 2) {
      return left(UserFailures.invalidProtocolLimitSelection);
    }

    if (keepIds.toSet().length != keepIds.length) {
      return left(UserFailures.duplicateProtocolSelection);
    }

    for (final protocolId in keepIds) {
      if (!_stack.contains(protocolId)) {
        return left(UserFailures.protocolNotActive);
      }
    }

    final keptIds = keepIds.toSet();
    final removedIds = _stack.protocolIds
        .where((protocolId) => !keptIds.contains(protocolId))
        .toList(growable: false);

    if (removedIds.isEmpty) {
      return right(this);
    }

    var nextStack = _stack;
    for (final protocolId in removedIds) {
      nextStack = nextStack.remove(protocolId);
    }

    final updated = User._(
      id: id,
      subscriptionStatus: subscriptionStatus,
      stack: nextStack,
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
    );

    for (final protocolId in removedIds) {
      updated.raiseDomainEvent(
        ProtocolDeactivatedEvent(
          userId: id,
          protocolId: protocolId,
        ),
      );
    }

    return right(updated);
  }

  /// Checks if the user can log a session for a protocol.
  ///
  /// Enforces:
  /// - **INV-U4**: Must complete onboarding first
  /// - Active stack must not exceed the supplied protocol limit
  ///
  /// - [protocolId]: Protocol to log session for.
  ///
  /// Returns [Left] with appropriate failure if cannot log.
  Either<DomainFailure, Unit> canLogSession(
    String protocolId, {
    required int? limit,
  }) {
    // INV-U4: Must complete onboarding
    if (!onboardingCompleted) {
      return left(UserFailures.onboardingNotCompleted);
    }

    // Must be in stack
    if (!_stack.contains(protocolId)) {
      return left(UserFailures.protocolNotInStack);
    }

    // Protocol count exceeds limit for current subscription tier
    if (limit != null && _stack.count > limit) {
      return left(UserFailures.tooManyActiveProtocols);
    }

    return right(unit);
  }

  /// Completes the onboarding flow.
  ///
  /// Enforces **INV-U4**: Users MUST complete onboarding before tracking Sessions.
  ///
  /// Returns [Left] with [UserFailures.alreadyOnboarded] if already completed.
  Either<DomainFailure, User> completeOnboarding() {
    if (onboardingCompleted) {
      return left(UserFailures.alreadyOnboarded);
    }

    final updated = User._(
      id: id,
      subscriptionStatus: subscriptionStatus,
      stack: _stack,
      onboardingCompleted: true,
      createdAt: createdAt,
    );

    updated.raiseDomainEvent(OnboardingCompletedEvent(userId: id));

    return right(updated);
  }
}
