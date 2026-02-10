import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPrefsTrialExpirationDecisionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = SharedPrefsTrialExpirationDecisionStore(prefs);
  });

  group('SharedPrefsTrialExpirationDecisionStore', () {
    // ---- Legacy trialStartDate-based methods ----

    group('legacy isResolved / markResolved', () {
      test('isResolved returns false initially', () async {
        final result = await store.isResolved(
          userId: 'user-123',
          trialStartDate: DateTime(2024, 1, 1),
        );

        expect(result, isFalse);
      });

      test('markResolved then isResolved returns true', () async {
        const userId = 'user-456';
        final trialStartDate = DateTime(2024, 2, 15, 10, 30);

        // Initially not resolved
        var result = await store.isResolved(
          userId: userId,
          trialStartDate: trialStartDate,
        );
        expect(result, isFalse);

        // Mark as resolved
        await store.markResolved(
          userId: userId,
          trialStartDate: trialStartDate,
        );

        // Now should be resolved
        result = await store.isResolved(
          userId: userId,
          trialStartDate: trialStartDate,
        );
        expect(result, isTrue);
      });

      test('different trial instances are independent', () async {
        const userId = 'user-789';
        final trialStartDate1 = DateTime(2024, 1, 1);
        final trialStartDate2 = DateTime(2024, 6, 1);

        // Mark first trial as resolved
        await store.markResolved(
          userId: userId,
          trialStartDate: trialStartDate1,
        );

        // First trial should be resolved
        final result1 = await store.isResolved(
          userId: userId,
          trialStartDate: trialStartDate1,
        );
        expect(result1, isTrue);

        // Second trial should NOT be resolved (different start date = different trial)
        final result2 = await store.isResolved(
          userId: userId,
          trialStartDate: trialStartDate2,
        );
        expect(result2, isFalse);
      });

      test('different users are independent', () async {
        final trialStartDate = DateTime(2024, 3, 1);

        // Mark user-1's decision as resolved
        await store.markResolved(
          userId: 'user-1',
          trialStartDate: trialStartDate,
        );

        // User-1 should be resolved
        final result1 = await store.isResolved(
          userId: 'user-1',
          trialStartDate: trialStartDate,
        );
        expect(result1, isTrue);

        // User-2 should NOT be resolved (different user)
        final result2 = await store.isResolved(
          userId: 'user-2',
          trialStartDate: trialStartDate,
        );
        expect(result2, isFalse);
      });

      test('key format uses UTC ISO8601 date string', () async {
        const userId = 'user-abc';
        final trialStartDate = DateTime(2024, 5, 15, 14, 30, 45);

        await store.markResolved(
          userId: userId,
          trialStartDate: trialStartDate,
        );

        // Verify the key format uses UTC by checking the underlying SharedPreferences
        final expectedKey =
            'trial_expired_resolved:$userId:${trialStartDate.toUtc().toIso8601String()}';
        expect(prefs.getBool(expectedKey), isTrue);
      });

      test('local and UTC DateTimes with same instant produce same key',
          () async {
        const userId = 'user-tz';
        // Create a local DateTime
        final localTime = DateTime(2024, 5, 15, 14, 30, 45);
        // Convert to UTC (same instant, different representation)
        final utcTime = localTime.toUtc();

        // Mark resolved with local time
        await store.markResolved(
          userId: userId,
          trialStartDate: localTime,
        );

        // Should be resolved when checking with UTC time (same instant)
        final result = await store.isResolved(
          userId: userId,
          trialStartDate: utcTime,
        );
        expect(result, isTrue);
      });
    });

    // ---- New snapshot-based methods ----

    group('isSubscriptionExpirationResolved / markSubscriptionExpirationResolved',
        () {
      const userId = 'user-sub-123';
      const entitlementId = 'Neurostack Pro';

      EntitlementSnapshot snapshotWith({
        String? originalTransactionId,
        DateTime? latestPurchaseDate,
        DateTime? expirationDate,
      }) {
        return EntitlementSnapshot(
          appUserId: userId,
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: expirationDate,
          originalTransactionId: originalTransactionId,
          latestPurchaseDate: latestPurchaseDate,
          lastPeriodType: EntitlementPeriodType.trial,
        );
      }

      test('returns false initially', () async {
        final snapshot = snapshotWith(originalTransactionId: 'txn-abc');

        final result = await store.isSubscriptionExpirationResolved(
          userId: userId,
          entitlementId: entitlementId,
          snapshot: snapshot,
        );

        expect(result, isFalse);
      });

      test('mark then check returns true', () async {
        final snapshot = snapshotWith(originalTransactionId: 'txn-abc');

        await store.markSubscriptionExpirationResolved(
          userId: userId,
          entitlementId: entitlementId,
          snapshot: snapshot,
          decision: ExpirationDecision.useFreeTier,
        );

        final result = await store.isSubscriptionExpirationResolved(
          userId: userId,
          entitlementId: entitlementId,
          snapshot: snapshot,
        );

        expect(result, isTrue);
      });

      test('persists the decision value', () async {
        final snapshot = snapshotWith(originalTransactionId: 'txn-persist');

        await store.markSubscriptionExpirationResolved(
          userId: userId,
          entitlementId: entitlementId,
          snapshot: snapshot,
          decision: ExpirationDecision.upgrade,
        );

        // Verify the stored value is the decision name
        const expectedKey =
            'sub_exp_resolved:$userId:$entitlementId:txn-persist';
        expect(prefs.getString(expectedKey), equals('upgrade'));
      });

      group('decision key fallback hierarchy', () {
        test('prefers originalTransactionId when available', () async {
          final snapshot = snapshotWith(
            originalTransactionId: 'txn-001',
            latestPurchaseDate: DateTime(2025, 3, 1),
            expirationDate: DateTime(2025, 3, 8),
          );

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.useFreeTier,
          );

          // Key should use originalTransactionId
          const expectedKey =
              'sub_exp_resolved:$userId:$entitlementId:txn-001';
          expect(prefs.getString(expectedKey), isNotNull);
        });

        test('falls back to latestPurchaseDate when no transactionId',
            () async {
          final purchaseDate = DateTime.utc(2025, 3, 1, 12, 0, 0);
          final snapshot = snapshotWith(
            latestPurchaseDate: purchaseDate,
            expirationDate: DateTime(2025, 3, 8),
          );

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.useFreeTier,
          );

          // Key should use latestPurchaseDate
          final expectedKey =
              'sub_exp_resolved:$userId:$entitlementId:purchase:${purchaseDate.toIso8601String()}';
          expect(prefs.getString(expectedKey), isNotNull);
        });

        test('falls back to expirationDate when no transactionId or purchaseDate',
            () async {
          final expDate = DateTime.utc(2025, 3, 8, 0, 0, 0);
          final snapshot = snapshotWith(
            expirationDate: expDate,
          );

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.upgrade,
          );

          // Key should use expirationDate
          final expectedKey =
              'sub_exp_resolved:$userId:$entitlementId:exp:${expDate.toIso8601String()}';
          expect(prefs.getString(expectedKey), isNotNull);
        });

        test('latestPurchaseDate key normalizes to UTC', () async {
          final localPurchaseDate = DateTime(2025, 6, 15, 10, 30, 0);
          final snapshot = snapshotWith(
            latestPurchaseDate: localPurchaseDate,
          );

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.useFreeTier,
          );

          // Verify key uses UTC version of the date
          final expectedKey =
              'sub_exp_resolved:$userId:$entitlementId:purchase:${localPurchaseDate.toUtc().toIso8601String()}';
          expect(prefs.getString(expectedKey), isNotNull);
        });

        test('expirationDate key normalizes to UTC', () async {
          final localExpDate = DateTime(2025, 7, 20, 8, 0, 0);
          final snapshot = snapshotWith(
            expirationDate: localExpDate,
          );

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.upgrade,
          );

          // Verify key uses UTC version of the date
          final expectedKey =
              'sub_exp_resolved:$userId:$entitlementId:exp:${localExpDate.toUtc().toIso8601String()}';
          expect(prefs.getString(expectedKey), isNotNull);
        });
      });

      group('null key behavior (non-cacheable)', () {
        test(
            'isSubscriptionExpirationResolved returns false when all identifiers are null',
            () async {
          // Snapshot with no identifiers at all (e.g., EntitlementSnapshot.none)
          final snapshot = EntitlementSnapshot.none(appUserId: userId);

          final result = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
          );

          // Fail-safe: return false so modal shows
          expect(result, isFalse);
        });

        test(
            'markSubscriptionExpirationResolved does nothing when all identifiers are null',
            () async {
          final snapshot = EntitlementSnapshot.none(appUserId: userId);

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.useFreeTier,
          );

          // Nothing should have been persisted
          // Verify by checking that isResolved still returns false
          final result = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot,
          );
          expect(result, isFalse);
        });
      });

      group('isolation', () {
        test('different users are independent', () async {
          final snapshot = snapshotWith(originalTransactionId: 'txn-shared');

          await store.markSubscriptionExpirationResolved(
            userId: 'user-A',
            entitlementId: entitlementId,
            snapshot: snapshot,
            decision: ExpirationDecision.useFreeTier,
          );

          // user-A resolved
          final resultA = await store.isSubscriptionExpirationResolved(
            userId: 'user-A',
            entitlementId: entitlementId,
            snapshot: snapshot,
          );
          expect(resultA, isTrue);

          // user-B NOT resolved
          final resultB = await store.isSubscriptionExpirationResolved(
            userId: 'user-B',
            entitlementId: entitlementId,
            snapshot: snapshot,
          );
          expect(resultB, isFalse);
        });

        test('different entitlement IDs are independent', () async {
          final snapshot = snapshotWith(originalTransactionId: 'txn-ent');

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: 'Entitlement A',
            snapshot: snapshot,
            decision: ExpirationDecision.upgrade,
          );

          // Entitlement A resolved
          final resultA = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: 'Entitlement A',
            snapshot: snapshot,
          );
          expect(resultA, isTrue);

          // Entitlement B NOT resolved
          final resultB = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: 'Entitlement B',
            snapshot: snapshot,
          );
          expect(resultB, isFalse);
        });

        test('different transaction IDs are independent (different subscription periods)',
            () async {
          final snapshot1 = snapshotWith(originalTransactionId: 'txn-period-1');
          final snapshot2 = snapshotWith(originalTransactionId: 'txn-period-2');

          await store.markSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot1,
            decision: ExpirationDecision.useFreeTier,
          );

          // Period 1 resolved
          final result1 = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot1,
          );
          expect(result1, isTrue);

          // Period 2 NOT resolved (new subscription period)
          final result2 = await store.isSubscriptionExpirationResolved(
            userId: userId,
            entitlementId: entitlementId,
            snapshot: snapshot2,
          );
          expect(result2, isFalse);
        });
      });
    });

    // ---- Status transition tracking ----

    group('saveLastSeenStatus / getLastSeenStatus', () {
      test('getLastSeenStatus returns null initially', () async {
        final result = await store.getLastSeenStatus('user-new');
        expect(result, isNull);
      });

      test('round-trips subscription status', () async {
        await store.saveLastSeenStatus(
          userId: 'user-status',
          status: SubscriptionStatus.trial,
        );

        final result = await store.getLastSeenStatus('user-status');
        expect(result, equals(SubscriptionStatus.trial));
      });

      test('overwrites previous status', () async {
        await store.saveLastSeenStatus(
          userId: 'user-transition',
          status: SubscriptionStatus.trial,
        );
        await store.saveLastSeenStatus(
          userId: 'user-transition',
          status: SubscriptionStatus.free,
        );

        final result = await store.getLastSeenStatus('user-transition');
        expect(result, equals(SubscriptionStatus.free));
      });

      test('different users are independent', () async {
        await store.saveLastSeenStatus(
          userId: 'user-X',
          status: SubscriptionStatus.premiumMonthly,
        );
        await store.saveLastSeenStatus(
          userId: 'user-Y',
          status: SubscriptionStatus.free,
        );

        expect(
          await store.getLastSeenStatus('user-X'),
          equals(SubscriptionStatus.premiumMonthly),
        );
        expect(
          await store.getLastSeenStatus('user-Y'),
          equals(SubscriptionStatus.free),
        );
      });

      test('returns null for unrecognized enum value', () async {
        // Simulate an old app version storing a value that no longer exists
        await prefs.setString('lastSeenEffectiveStatus:user-old', 'bogusValue');

        final result = await store.getLastSeenStatus('user-old');
        expect(result, isNull);
      });
    });
  });

  // ---- ExpirationDecision enum ----

  group('ExpirationDecision', () {
    test('has upgrade and useFreeTier values', () {
      expect(
        ExpirationDecision.values,
        containsAll([
          ExpirationDecision.upgrade,
          ExpirationDecision.useFreeTier,
        ]),
      );
    });

    test('has exactly 2 values', () {
      expect(ExpirationDecision.values.length, equals(2));
    });
  });
}
