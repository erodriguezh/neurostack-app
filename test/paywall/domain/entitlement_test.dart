import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/domain/entitlement.dart';

import '../../factories/factories.dart';

void main() {
  group('Entitlement', () {
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
