import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart';
import 'package:neurostack/features/user/domain/value_objects/trial_period.dart';
import '../constants/test_constants.dart';
import 'value_objects/stack_factory.dart';
import 'value_objects/trial_period_factory.dart';

abstract final class UserFactory {
  /// Creates a new User via `User.create()` (free status, INV-P6).
  static User createNew({
    String? id,
    DateTime? createdAt,
  }) {
    return User.create(
      id: id ?? TestConstants.user.id,
      createdAt: createdAt ?? TestConstants.user.createdAt,
    );
  }

  /// Reconstitutes a User with specific subscription state.
  /// Use for testing subscription-dependent behavior.
  static User create({
    String? id,
    SubscriptionStatus subscriptionStatus = SubscriptionStatus.trial,
    TrialPeriod? trialPeriod,
    Stack? stack,
    bool onboardingCompleted = false,
    DateTime? createdAt,
  }) {
    return User.reconstitute(
      id: id ?? TestConstants.user.id,
      subscriptionStatus: subscriptionStatus,
      trialPeriod: trialPeriod,
      stack: stack ?? Stack.empty(),
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt ?? TestConstants.user.createdAt,
    );
  }

  /// Creates a Free Tier user at protocol capacity (2 protocols).
  /// Use for boundary tests (INV-U1, INV-M5).
  static User createFreeAtCapacity() {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.free,
      trialPeriod: null,
      stack: StackFactory.atFreeCapacity(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }

  /// Creates a Free Tier user under protocol capacity (1 protocol).
  /// Use for boundary tests (success case before failure).
  static User createFreeUnderLimit() {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.free,
      trialPeriod: null,
      stack: StackFactory.underFreeLimit(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }

  /// Creates an expired trial user with >2 protocols.
  /// Use for INV-U5 tests.
  static User createExpiredTrialOverLimit() {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.trial,
      trialPeriod: TrialPeriodFactory.expired(),
      stack: StackFactory.overFreeCapacity(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }

  /// Creates a Premium user (monthly).
  static User createPremiumMonthly({Stack? stack}) {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.premiumMonthly,
      trialPeriod: null,
      stack: stack ?? Stack.empty(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }

  /// Creates a Premium user (annual).
  static User createPremiumAnnual({Stack? stack}) {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.premiumAnnual,
      trialPeriod: null,
      stack: stack ?? Stack.empty(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }

  /// Creates a user on active trial.
  static User createActiveTrial({Stack? stack}) {
    return User.reconstitute(
      id: TestConstants.user.id,
      subscriptionStatus: SubscriptionStatus.trial,
      trialPeriod: TrialPeriodFactory.create(),
      stack: stack ?? Stack.empty(),
      onboardingCompleted: true,
      createdAt: TestConstants.user.createdAt,
    );
  }
}
