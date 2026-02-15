import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

void main() {
  group('EntitlementSnapshot', () {
    group('none() factory', () {
      test('creates snapshot with no entitlement', () {
        const userId = 'test-user-123';
        final snapshot = EntitlementSnapshot.none(appUserId: userId);

        expect(snapshot.appUserId, equals(userId));
        expect(snapshot.hasProEntitlement, isFalse);
        expect(snapshot.isTrialPeriod, isFalse);
        expect(snapshot.isInGracePeriod, isFalse);
        expect(snapshot.productId, isNull);
        expect(snapshot.expirationDate, isNull);
        expect(snapshot.originalTransactionId, isNull);
        expect(snapshot.latestPurchaseDate, isNull);
        expect(snapshot.lastPeriodType, isNull);
      });
    });

    group('isForUser()', () {
      test('returns true when appUserId matches', () {
        const userId = 'test-user-123';
        final snapshot = EntitlementSnapshot.none(appUserId: userId);

        expect(snapshot.isForUser(userId), isTrue);
      });

      test('returns false when appUserId does not match', () {
        const userId = 'test-user-123';
        const otherUserId = 'other-user-456';
        final snapshot = EntitlementSnapshot.none(appUserId: userId);

        expect(snapshot.isForUser(otherUserId), isFalse);
      });

      test('returns false when appUserId is null', () {
        const snapshot = EntitlementSnapshot(
          appUserId: null,
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: null,
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: null,
        );

        expect(snapshot.isForUser('any-user'), isFalse);
      });
    });

    group('wasTrialThatExpired', () {
      test('returns true when no entitlement and lastPeriodType is trial', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.trial,
        );

        expect(snapshot.wasTrialThatExpired, isTrue);
      });

      test('returns false when still has entitlement', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: true,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.trial,
        );

        expect(snapshot.wasTrialThatExpired, isFalse);
      });

      test('returns false when lastPeriodType is normal', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.normal,
        );

        expect(snapshot.wasTrialThatExpired, isFalse);
      });

      test('returns false when lastPeriodType is intro', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.intro,
        );

        expect(snapshot.wasTrialThatExpired, isFalse);
      });

      test(
        'returns false when lastPeriodType is null (never had entitlement)',
        () {
          final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');

          expect(snapshot.wasTrialThatExpired, isFalse);
        },
      );
    });

    group('wasPaidThatExpired', () {
      test('returns true when no entitlement and lastPeriodType is normal', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.normal,
        );

        expect(snapshot.wasPaidThatExpired, isTrue);
      });

      test('returns true when no entitlement and lastPeriodType is intro', () {
        // NOTE: intro is treated as paid (discounted paid period, not free trial)
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_yearly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.intro,
        );

        expect(snapshot.wasPaidThatExpired, isTrue);
      });

      test('returns false when still has entitlement', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.normal,
        );

        expect(snapshot.wasPaidThatExpired, isFalse);
      });

      test('returns false when lastPeriodType is trial', () {
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.trial,
        );

        expect(snapshot.wasPaidThatExpired, isFalse);
      });

      test(
        'returns false when lastPeriodType is null (never had entitlement)',
        () {
          final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');

          expect(snapshot.wasPaidThatExpired, isFalse);
        },
      );
    });

    group('equality', () {
      test('two snapshots with same values are equal', () {
        final date = DateTime(2025, 2, 1);
        final snapshot1 = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: true,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: date,
          originalTransactionId: 'txn-123',
          latestPurchaseDate: date,
          lastPeriodType: EntitlementPeriodType.trial,
        );
        final snapshot2 = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: true,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: date,
          originalTransactionId: 'txn-123',
          latestPurchaseDate: date,
          lastPeriodType: EntitlementPeriodType.trial,
        );

        expect(snapshot1, equals(snapshot2));
        expect(snapshot1.hashCode, equals(snapshot2.hashCode));
      });

      test('two snapshots with different values are not equal', () {
        final snapshot1 = EntitlementSnapshot.none(appUserId: 'user-123');
        final snapshot2 = EntitlementSnapshot.none(appUserId: 'user-456');

        expect(snapshot1, isNot(equals(snapshot2)));
      });
    });

    group('const constructor', () {
      test('EntitlementSnapshot can be const', () {
        // This test verifies the class uses immutable pattern (const constructor)
        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: null,
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: null,
        );

        expect(snapshot.hasProEntitlement, isFalse);
      });
    });
  });

  group('EntitlementPeriodType', () {
    test('has trial, intro, and normal values', () {
      expect(
        EntitlementPeriodType.values,
        containsAll([
          EntitlementPeriodType.trial,
          EntitlementPeriodType.intro,
          EntitlementPeriodType.normal,
        ]),
      );
    });

    test('has exactly 3 values', () {
      expect(EntitlementPeriodType.values.length, equals(3));
    });
  });

  group('PaywallOutcome', () {
    test('has purchased, cancelled, and error values', () {
      expect(
        PaywallOutcome.values,
        containsAll([
          PaywallOutcome.purchased,
          PaywallOutcome.cancelled,
          PaywallOutcome.error,
        ]),
      );
    });

    test('has exactly 3 values', () {
      expect(PaywallOutcome.values.length, equals(3));
    });
  });
}
