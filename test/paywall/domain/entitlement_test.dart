import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/paywall/domain/entitlement.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/paywall_constants.dart';

import '../../factories/factories.dart';
import '../../matchers/either_matchers.dart';

void main() {
  group('Entitlement', () {
    test('free tier user is blocked from activating a third protocol', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
        stack: StackFactory.atFreeCapacity(),
        onboardingCompleted: true,
      );
      final entitlement = Entitlement.of(user, null);

      final result = user.activateProtocol(
        'protocol-3',
        limit: entitlement.protocolLimit,
      );

      expect(result, isLeftWith(UserFailures.protocolLimitReached));
    });

    test(
      'falls back to persisted free status when snapshot is unavailable',
      () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );

        final entitlement = Entitlement.of(user, null);

        expect(entitlement.effectiveStatus, SubscriptionStatus.free);
        expect(entitlement.protocolLimit, 2);
        expect(entitlement.isPremium, isFalse);
        expect(entitlement.canAccessPremium, isFalse);
      },
    );

    test('resolves active trial snapshot as trial with premium access', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot = EntitlementSnapshotFactory.activeTrial(userId: user.id);

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.trial);
      expect(entitlement.protocolLimit, isNull);
      expect(entitlement.isPremium, isFalse);
      expect(entitlement.canAccessPremium, isTrue);
    });

    test('resolves paid monthly snapshot as premiumMonthly', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
        userId: user.id,
      );

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.premiumMonthly);
      expect(entitlement.protocolLimit, isNull);
      expect(entitlement.isPremium, isTrue);
      expect(entitlement.canAccessPremium, isTrue);
    });

    test('resolves paid yearly snapshot as premiumAnnual', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot = EntitlementSnapshotFactory.activePaidYearly(
        userId: user.id,
      );

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.premiumAnnual);
      expect(entitlement.protocolLimit, isNull);
      expect(entitlement.isPremium, isTrue);
      expect(entitlement.canAccessPremium, isTrue);
    });

    test('resolves grace snapshot as grace', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot = EntitlementSnapshotFactory.gracePeriod(userId: user.id);

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.grace);
      expect(entitlement.protocolLimit, isNull);
      expect(entitlement.isPremium, isTrue);
      expect(entitlement.canAccessPremium, isTrue);
    });

    test('resolves expired paid snapshot as expired', () {
      final user = UserFactory.createPremiumMonthly();
      final snapshot = EntitlementSnapshotFactory.expiredPaid(userId: user.id);

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.expired);
      expect(entitlement.protocolLimit, 2);
      expect(entitlement.isPremium, isFalse);
      expect(entitlement.canAccessPremium, isFalse);
    });

    test('resolves expired trial snapshot as free', () {
      final user = UserFactory.createPremiumMonthly();
      final snapshot = EntitlementSnapshotFactory.expiredTrial(
        userId: user.id,
      );

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.free);
      expect(entitlement.protocolLimit, 2);
      expect(entitlement.canAccessPremium, isFalse);
    });

    test('preserves snapshot mapping precedence and fallback behavior', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.free,
      );
      final cases = <(EntitlementSnapshot, SubscriptionStatus)>[
        (
          EntitlementSnapshotFactory.expiredIntro(userId: user.id),
          SubscriptionStatus.expired,
        ),
        (
          EntitlementSnapshot(
            appUserId: user.id,
            hasProEntitlement: true,
            isTrialPeriod: true,
            isInGracePeriod: true,
            productId: kProductMonthly,
            expirationDate: null,
            originalTransactionId: null,
            latestPurchaseDate: null,
            lastPeriodType: EntitlementPeriodType.trial,
          ),
          SubscriptionStatus.grace,
        ),
        (
          EntitlementSnapshot(
            appUserId: user.id,
            hasProEntitlement: true,
            isTrialPeriod: false,
            isInGracePeriod: false,
            productId: 'unknown-product',
            expirationDate: null,
            originalTransactionId: null,
            latestPurchaseDate: null,
            lastPeriodType: EntitlementPeriodType.normal,
          ),
          SubscriptionStatus.premiumMonthly,
        ),
      ];

      for (final (snapshot, expectedStatus) in cases) {
        final entitlement = Entitlement.of(user, snapshot);

        expect(entitlement.effectiveStatus, expectedStatus);
      }
    });

    test('ignores snapshot scoped to a different user', () {
      final user = UserFactory.createPremiumAnnual();
      final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
        userId: 'other-user',
      );

      final entitlement = Entitlement.of(user, snapshot);

      expect(entitlement.effectiveStatus, SubscriptionStatus.premiumAnnual);
      expect(entitlement.protocolLimit, isNull);
      expect(entitlement.isPremium, isTrue);
      expect(entitlement.canAccessPremium, isTrue);
    });
  });
}
