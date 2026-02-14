import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/paywall/paywall_constants.dart';

import '../../factories/entitlement_snapshot_factory.dart';
import '../../factories/user_factory.dart';

void main() {
  const resolver = SubscriptionStatusResolver();

  // ---------------------------------------------------------------------------
  // mapSnapshotToStatus
  // ---------------------------------------------------------------------------

  group('mapSnapshotToStatus', () {
    test('noEntitlement_neverHadEntitlement_returnsFree', () {
      final snapshot = EntitlementSnapshot.none(appUserId: 'user-001');

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.free));
    });

    test('noEntitlement_trialExpired_returnsFree', () {
      final snapshot = EntitlementSnapshotFactory.expiredTrial();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.free));
    });

    test('noEntitlement_paidExpired_returnsExpired', () {
      final snapshot = EntitlementSnapshotFactory.expiredPaid();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.expired));
    });

    test('noEntitlement_introExpired_returnsExpired', () {
      // Intro is treated as paid for churn UX
      final snapshot = EntitlementSnapshotFactory.expiredIntro();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.expired));
    });

    test('hasEntitlement_inGracePeriod_returnsGrace', () {
      // CRITICAL: Grace takes precedence over trial/product type
      final snapshot = EntitlementSnapshotFactory.gracePeriod();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.grace));
    });

    test('hasEntitlement_isTrialPeriod_returnsTrial', () {
      final snapshot = EntitlementSnapshotFactory.activeTrial();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.trial));
    });

    test('hasEntitlement_monthlyProduct_returnsPremiumMonthly', () {
      final snapshot = EntitlementSnapshotFactory.activePaidMonthly();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.premiumMonthly));
    });

    test('hasEntitlement_yearlyProduct_returnsPremiumAnnual', () {
      final snapshot = EntitlementSnapshotFactory.activePaidYearly();

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.premiumAnnual));
    });

    test('hasEntitlement_unknownProduct_defaultsToPremiumMonthly', () {
      // Fallback for unknown product IDs (should never happen in prod)
      const snapshot = EntitlementSnapshot(
        appUserId: 'user-001',
        hasProEntitlement: true,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: 'neurostack_lifetime_unknown',
        expirationDate: null,
        originalTransactionId: null,
        latestPurchaseDate: null,
        lastPeriodType: EntitlementPeriodType.normal,
      );

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.premiumMonthly));
    });

    // NOTE: Cannot test null productId with hasProEntitlement=true because
    // EntitlementSnapshot's assertion requires at least one of isTrialPeriod,
    // isInGracePeriod, or productId != null when hasProEntitlement is true.

    test('noEntitlement_nullLastPeriodType_returnsFree', () {
      // Unknown period type - safe default is free
      const snapshot = EntitlementSnapshot(
        appUserId: 'user-001',
        hasProEntitlement: false,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: null,
        expirationDate: null,
        originalTransactionId: null,
        latestPurchaseDate: null,
        lastPeriodType: null,
      );

      final result = resolver.mapSnapshotToStatus(snapshot);

      expect(result, equals(SubscriptionStatus.free));
    });

    group('precedence rules', () {
      test('graceTakesPrecedenceOverTrial', () {
        // Grace + trial flags both set → grace wins
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-001',
          hasProEntitlement: true,
          isTrialPeriod: true,
          isInGracePeriod: true,
          productId: kProductMonthly,
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.trial,
        );

        final result = resolver.mapSnapshotToStatus(snapshot);

        expect(result, equals(SubscriptionStatus.grace));
      });

      test('trialTakesPrecedenceOverProductType', () {
        // Trial flag set with a product → trial wins over product type
        final snapshot = EntitlementSnapshotFactory.activeTrial();

        final result = resolver.mapSnapshotToStatus(snapshot);

        expect(result, equals(SubscriptionStatus.trial));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // resolveEffectiveStatus
  // ---------------------------------------------------------------------------

  group('resolveEffectiveStatus', () {
    test('snapshotNull_fallsBackToDbStatus', () {
      final user = UserFactory.create(
        subscriptionStatus: SubscriptionStatus.premiumMonthly,
      );

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: null,
      );

      expect(result, equals(SubscriptionStatus.premiumMonthly));
    });

    test('snapshotForWrongUser_fallsBackToDbStatus', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.premiumAnnual,
      );
      final snapshot =
          EntitlementSnapshotFactory.activePaidMonthly(userId: 'other-user');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      expect(result, equals(SubscriptionStatus.premiumAnnual));
    });

    test('snapshotForCorrectUser_usesRcState', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.free, // DB says free
      );
      final snapshot =
          EntitlementSnapshotFactory.activePaidMonthly(userId: 'user-001');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      // RC says premium monthly - RC wins
      expect(result, equals(SubscriptionStatus.premiumMonthly));
    });

    test('snapshotNone_forCorrectUser_usesRcState', () {
      // RC authoritatively says "no entitlement" → maps to free
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.premiumMonthly, // DB stale
      );
      final snapshot = EntitlementSnapshot.none(appUserId: 'user-001');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      // RC says none → free (overrides stale DB)
      expect(result, equals(SubscriptionStatus.free));
    });

    test('dbFree_rcTrial_returnsTrial', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(userId: 'user-001');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      expect(result, equals(SubscriptionStatus.trial));
    });

    test('dbTrial_rcExpiredTrial_returnsFree', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.trial,
      );
      final snapshot =
          EntitlementSnapshotFactory.expiredTrial(userId: 'user-001');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      expect(result, equals(SubscriptionStatus.free));
    });

    test('dbFree_rcGrace_returnsGrace', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.free,
      );
      final snapshot =
          EntitlementSnapshotFactory.gracePeriod(userId: 'user-001');

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      expect(result, equals(SubscriptionStatus.grace));
    });

    test('snapshotNullAppUserId_fallsBackToDbStatus', () {
      final user = UserFactory.create(
        id: 'user-001',
        subscriptionStatus: SubscriptionStatus.premiumAnnual,
      );
      const snapshot = EntitlementSnapshot(
        appUserId: null,
        hasProEntitlement: true,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: kProductMonthly,
        expirationDate: null,
        originalTransactionId: null,
        latestPurchaseDate: null,
        lastPeriodType: EntitlementPeriodType.normal,
      );

      final result = resolver.resolveEffectiveStatus(
        user: user,
        snapshot: snapshot,
      );

      // Snapshot has null appUserId → isForUser returns false → fallback to DB
      expect(result, equals(SubscriptionStatus.premiumAnnual));
    });
  });

  // ---------------------------------------------------------------------------
  // shouldShowTrialReminder
  // ---------------------------------------------------------------------------

  group('shouldShowTrialReminder', () {
    test('within24h_returnsTrue', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final expiresAt = now.add(const Duration(hours: 12));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isTrue);
    });

    test('exactly24h_returnsTrue', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final expiresAt = now.add(const Duration(hours: 24));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isTrue);
    });

    test('moreThan24h_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final expiresAt = now.add(const Duration(hours: 48));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });

    test('alreadyExpired_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final expiresAt = now.subtract(const Duration(hours: 1));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });

    test('nullSnapshot_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);

      final result = resolver.shouldShowTrialReminder(
        snapshot: null,
        now: now,
      );

      expect(result, isFalse);
    });

    test('noProEntitlement_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      // Expired trial - no longer has entitlement
      final snapshot = EntitlementSnapshotFactory.expiredTrial();

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });

    test('notTrialPeriod_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      // Active paid subscription, not trial - even if expiring soon
      final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
        expirationDate: now.add(const Duration(hours: 12)),
      );

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });

    test('nullExpirationDate_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: null);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });

    test('expiresNow_returnsTrue', () {
      // Duration.zero is not negative, so "now" is within the window
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: now);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isTrue);
    });

    test('expiresIn1Minute_returnsTrue', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      final expiresAt = now.add(const Duration(minutes: 1));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isTrue);
    });

    test('expiresIn24h1s_returnsFalse', () {
      final now = DateTime(2025, 6, 15, 12, 0, 0);
      // Just over 24 hours
      final expiresAt = now.add(const Duration(hours: 24, seconds: 1));
      final snapshot =
          EntitlementSnapshotFactory.activeTrial(expirationDate: expiresAt);

      final result = resolver.shouldShowTrialReminder(
        snapshot: snapshot,
        now: now,
      );

      expect(result, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // shouldShowTrialExpiredModal
  // ---------------------------------------------------------------------------

  group('shouldShowTrialExpiredModal', () {
    group('primary detection: status transition', () {
      test('trialToFree_returnsTrue', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isTrue);
      });

      test('trialToExpired_returnsTrue', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.expired,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isTrue);
      });

      test('trialToPremiumMonthly_returnsFalse', () {
        // Trial converted to paid - no modal needed
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.premiumMonthly,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('trialToPremiumAnnual_returnsFalse', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.premiumAnnual,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('trialToGrace_returnsFalse', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.grace,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('trialToTrial_returnsFalse', () {
        // Still in trial - no change
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.trial,
          lastSeenStatus: SubscriptionStatus.trial,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('freeToFree_returnsFalse', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.free,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('premiumToFree_returnsFalse', () {
        // Paid subscriber churned - NOT a trial expiration
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.premiumMonthly,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('premiumToExpired_returnsFalse', () {
        // Paid subscriber expired - NOT a trial expiration
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.expired,
          lastSeenStatus: SubscriptionStatus.premiumAnnual,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('expiredToFree_returnsFalse', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.expired,
          snapshot: null,
        );

        expect(result, isFalse);
      });
    });

    group('secondary detection: fresh install with RC data', () {
      test('nullLastSeen_rcSaysTrialExpired_returnsTrue', () {
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: null,
          snapshot: snapshot,
        );

        expect(result, isTrue);
      });

      test('nullLastSeen_rcSaysPaidExpired_returnsFalse', () {
        // Paid expiration is NOT trial expiration
        final snapshot = EntitlementSnapshotFactory.expiredPaid();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.expired,
          lastSeenStatus: null,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });

      test('nullLastSeen_rcSaysActiveEntitlement_returnsFalse', () {
        final snapshot = EntitlementSnapshotFactory.activePaidMonthly();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.premiumMonthly,
          lastSeenStatus: null,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });

      test('nullLastSeen_nullSnapshot_returnsFalse', () {
        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: null,
          snapshot: null,
        );

        expect(result, isFalse);
      });

      test('nullLastSeen_rcSaysTrialExpired_ignoresCurrentStatus', () {
        // The secondary path only checks snapshot.wasTrialThatExpired,
        // regardless of currentEffectiveStatus value
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.expired,
          lastSeenStatus: null,
          snapshot: snapshot,
        );

        expect(result, isTrue);
      });

      test('nullLastSeen_snapshotNone_returnsFalse', () {
        // User never had an entitlement - not a trial expiration
        final snapshot = EntitlementSnapshot.none(appUserId: 'user-001');

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: null,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });
    });

    group('secondary detection gated on null lastSeenStatus', () {
      test('lastSeenFree_rcSaysTrialExpired_returnsFalse', () {
        // CRITICAL: When lastSeenStatus is NOT null, the secondary detection
        // (wasTrialThatExpired) is NOT used. This prevents the modal from
        // showing repeatedly after trial churn.
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.free,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });

      test('lastSeenExpired_rcSaysTrialExpired_returnsFalse', () {
        final snapshot = EntitlementSnapshotFactory.expiredTrial();

        final result = resolver.shouldShowTrialExpiredModal(
          currentEffectiveStatus: SubscriptionStatus.free,
          lastSeenStatus: SubscriptionStatus.expired,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });
    });
  });
}
