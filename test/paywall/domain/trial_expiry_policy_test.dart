import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/paywall/domain/trial_expiry_policy.dart';

import '../../factories/entitlement_snapshot_factory.dart';

void main() {
  const policy = TrialExpiryPolicy(
    resolver: SubscriptionStatusResolver(),
  );

  group('TrialExpiryPolicy', () {
    group('shouldShowReminder', () {
      test('activeTrialExpiringWithin24h_returnsTrue', () {
        final now = DateTime(2026, 6, 19, 10);
        final snapshot = EntitlementSnapshotFactory.activeTrial(
          expirationDate: now.add(const Duration(hours: 12)),
        );

        final result = policy.shouldShowReminder(
          snapshot: snapshot,
          now: now,
        );

        expect(result, isTrue);
      });

      test('activeTrialExpiringAfter24h_returnsFalse', () {
        final now = DateTime(2026, 6, 19, 10);
        final snapshot = EntitlementSnapshotFactory.activeTrial(
          expirationDate: now.add(const Duration(hours: 24, seconds: 1)),
        );

        final result = policy.shouldShowReminder(
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });

      test('expiredTrial_returnsFalse', () {
        final now = DateTime(2026, 6, 19, 10);
        final snapshot = EntitlementSnapshotFactory.activeTrial(
          expirationDate: now.subtract(const Duration(minutes: 1)),
        );

        final result = policy.shouldShowReminder(
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });
    });

    group('shouldShowExpiredModal', () {
      test('trialToFreeTransition_returnsTrue', () {
        final result = policy.shouldShowExpiredModal(
          effectiveStatus: SubscriptionStatus.free,
          lastSeen: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isTrue);
      });

      test('trialToExpiredTransition_returnsTrue', () {
        final result = policy.shouldShowExpiredModal(
          effectiveStatus: SubscriptionStatus.expired,
          lastSeen: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isTrue);
      });

      test('trialToPremiumTransition_returnsFalse', () {
        final result = policy.shouldShowExpiredModal(
          effectiveStatus: SubscriptionStatus.premiumMonthly,
          lastSeen: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('freshInstallWithExpiredTrialSnapshot_returnsTrue', () {
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = policy.shouldShowExpiredModal(
          effectiveStatus: SubscriptionStatus.free,
          lastSeen: null,
          snapshot: snapshot,
        );

        expect(result, isTrue);
      });

      test('lastSeenFreeWithExpiredTrialSnapshot_returnsFalse', () {
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = policy.shouldShowExpiredModal(
          effectiveStatus: SubscriptionStatus.free,
          lastSeen: SubscriptionStatus.free,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });
    });
  });
}
