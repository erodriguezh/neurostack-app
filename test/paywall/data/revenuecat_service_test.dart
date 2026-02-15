import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

import '../../mocks/fake_revenuecat_client.dart';

void main() {
  late FakeRevenueCatClient fakeClient;
  late RevenueCatService service;

  setUp(() {
    fakeClient = FakeRevenueCatClient();
    service = RevenueCatService(fakeClient);
  });

  tearDown(() {
    try {
      service.dispose();
    } catch (_) {
      // Ignore disposal errors
    }
    fakeClient.dispose();
  });

  group('RevenueCatService', () {
    group('init()', () {
      test('configures the SDK', () async {
        await service.init();

        expect(fakeClient.configureWasCalled, isTrue);
      });

      test('is idempotent - multiple calls return same future', () async {
        // Start two init calls concurrently
        final future1 = service.init();
        final future2 = service.init();

        await Future.wait([future1, future2]);

        // Configure should only be called once
        expect(fakeClient.configureCallCount, equals(1));
      });

      test('subsequent calls return same future without re-configuring',
          () async {
        await service.init();
        final countAfterFirstInit = fakeClient.configureCallCount;

        await service.init();

        // Configure should not be called again
        expect(fakeClient.configureCallCount, equals(countAfterFirstInit));
      });

      test('rethrows error if configure fails', () async {
        fakeClient.configureThrows = true;

        Object? caughtError;
        try {
          await service.init();
        } catch (e) {
          caughtError = e;
        }

        expect(caughtError, isA<Exception>());
      });

      test('subsequent calls return error future if init failed', () async {
        fakeClient.configureThrows = true;

        try {
          await service.init();
        } catch (_) {}

        // Second call should also throw (same failed completer)
        Object? caughtError;
        try {
          await service.init();
        } catch (e) {
          caughtError = e;
        }

        expect(caughtError, isA<Exception>());
      });

      test('subscribes to entitlement changes', () async {
        await service.init();
        await service.identify('user-123');

        final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.snapshotToReturn = snapshot;

        fakeClient.simulateEntitlementChange(snapshot);

        // Allow stream event to propagate
        await Future<void>.delayed(Duration.zero);

        expect(service.entitlementSnapshot.value, equals(snapshot));
      });
    });

    group('identify()', () {
      test('throws StateError if init not called', () async {
        expect(
          () => service.identify('user-123'),
          throwsA(isA<StateError>()),
        );
      });

      test('waits for init to complete', () async {
        fakeClient.configureDelay = const Duration(milliseconds: 50);
        var identifyCompleted = false;

        // Start init but don't await
        final initFuture = service.init();

        // Start identify - should wait for init
        final identifyFuture = service.identify('user-123').then((_) {
          identifyCompleted = true;
        });

        // Identify should not complete yet
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(identifyCompleted, isFalse);

        // Wait for both to complete
        await Future.wait([initFuture, identifyFuture]);
        expect(identifyCompleted, isTrue);
      });

      test('logs in with the given userId', () async {
        await service.init();
        await service.identify('user-123');

        expect(fakeClient.loggedInUserId, equals('user-123'));
      });

      test('calls refreshEntitlement after identify', () async {
        final snapshot =
            EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.snapshotToReturn = snapshot;

        await service.init();
        await service.identify('user-123');

        expect(service.entitlementSnapshot.value, equals(snapshot));
      });
    });

    group('logout()', () {
      test('throws StateError if init not called', () async {
        expect(
          () => service.logout(),
          throwsA(isA<StateError>()),
        );
      });

      test('clears local state even when init failed', () async {
        fakeClient.configureThrows = true;

        try {
          await service.init();
        } catch (_) {}

        // Manually set some state to simulate a partial flow
        // (In practice this shouldn't happen, but testing the safety)
        service.entitlementSnapshot.value =
            EntitlementSnapshot.none(appUserId: 'user-123');

        // Logout should complete without throwing and clear state
        await expectLater(service.logout(), completes);
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('calls client logout on success', () async {
        await service.init();
        await service.identify('user-123');
        await service.logout();

        expect(fakeClient.logOutWasCalled, isTrue);
      });

      test('clears entitlement snapshot', () async {
        final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.snapshotToReturn = snapshot;

        await service.init();
        await service.identify('user-123');

        expect(service.entitlementSnapshot.value, isNotNull);

        await service.logout();

        expect(service.entitlementSnapshot.value, isNull);
      });

      test('logs out from client', () async {
        await service.init();
        await service.identify('user-123');
        await service.logout();

        expect(fakeClient.logOutWasCalled, isTrue);
      });
    });

    group('presentPaywall()', () {
      test('returns error if init never called', () async {
        final result = await service.presentPaywall();
        expect(result, equals(PaywallOutcome.error));
      });

      test('returns error if init failed', () async {
        fakeClient.configureThrows = true;

        try {
          await service.init();
        } catch (_) {}

        final result = await service.presentPaywall();

        expect(result, equals(PaywallOutcome.error));
      });

      test('returns error if no user identified', () async {
        await service.init();

        final result = await service.presentPaywall();

        expect(result, equals(PaywallOutcome.error));
      });

      test('returns cancelled if already presenting', () async {
        await service.init();
        await service.identify('user-123');

        // Use a completer to block the first paywall presentation
        final paywallBlocker = Completer<PaywallOutcome>();
        fakeClient.paywallCompleter = paywallBlocker;

        // Start first paywall presentation (will block on completer)
        final firstResultFuture = service.presentPaywall();

        // Second call should return cancelled immediately
        final secondResult = await service.presentPaywall();
        expect(secondResult, equals(PaywallOutcome.cancelled));

        // Complete the first paywall
        paywallBlocker.complete(PaywallOutcome.purchased);
        final firstResult = await firstResultFuture;
        expect(firstResult, equals(PaywallOutcome.purchased));
      });

      test('returns client result on success', () async {
        await service.init();
        await service.identify('user-123');
        fakeClient.paywallOutcome = PaywallOutcome.purchased;

        final result = await service.presentPaywall();

        expect(result, equals(PaywallOutcome.purchased));
      });

      test('refreshes entitlement after paywall closes', () async {
        await service.init();
        await service.identify('user-123');

        final initialSnapshot =
            EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.snapshotToReturn = initialSnapshot;
        await service.refreshEntitlement();

        const updatedSnapshot = EntitlementSnapshot(
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
        fakeClient.snapshotToReturn = updatedSnapshot;
        fakeClient.paywallOutcome = PaywallOutcome.purchased;

        await service.presentPaywall();

        expect(service.entitlementSnapshot.value, equals(updatedSnapshot));
      });
    });

    group('refreshEntitlement()', () {
      test('silently returns if init not called', () async {
        // Should not throw, just return silently
        await expectLater(
          service.refreshEntitlement(),
          completes,
        );
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('silently returns if no user identified', () async {
        await service.init();

        final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.snapshotToReturn = snapshot;

        await service.refreshEntitlement();

        // Snapshot should remain null - no identified user
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('ignores snapshot for wrong user', () async {
        await service.init();
        await service.identify('user-123');

        // Clear the snapshot set by identify
        service.entitlementSnapshot.value = null;

        // Return a snapshot for a different user
        fakeClient.snapshotToReturn =
            EntitlementSnapshot.none(appUserId: 'other-user');

        await service.refreshEntitlement();

        // Snapshot should remain null - wrong user
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('updates snapshot with client result', () async {
        await service.init();
        await service.identify('user-123');

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
        fakeClient.snapshotToReturn = snapshot;

        await service.refreshEntitlement();

        expect(service.entitlementSnapshot.value, equals(snapshot));
      });

      test('does not clobber known state with null', () async {
        await service.init();
        await service.identify('user-123');

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
        fakeClient.snapshotToReturn = snapshot;
        await service.refreshEntitlement();

        // Now client returns null (simulating unavailable)
        fakeClient.snapshotToReturn = null;
        await service.refreshEntitlement();

        // Snapshot should remain unchanged
        expect(service.entitlementSnapshot.value, equals(snapshot));
      });

      test('swallows exceptions from getEntitlementSnapshot', () async {
        await service.init();
        fakeClient.getSnapshotThrows = true;

        // This should not throw - exceptions are swallowed
        await expectLater(
          service.refreshEntitlement(),
          completes,
        );
      });

      test('does not call client after logout (no churn)', () async {
        await service.init();
        await service.identify('user-123');
        await service.logout();

        fakeClient.snapshotToReturn = const EntitlementSnapshot(
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

        final callsBefore = fakeClient.getEntitlementSnapshotCallCount;
        await service.refreshEntitlement();

        // Should not have called getEntitlementSnapshot at all
        expect(fakeClient.getEntitlementSnapshotCallCount, equals(callsBefore));
        // Snapshot should remain null (cleared by logout)
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('ignores in-flight result if logout happens mid-refresh', () async {
        await service.init();
        await service.identify('user-123');

        fakeClient.getSnapshotCompleter = Completer<EntitlementSnapshot?>();

        final refreshFuture = service.refreshEntitlement();

        // Logout while refresh is in-flight
        await service.logout();

        // Complete the in-flight snapshot fetch
        fakeClient.getSnapshotCompleter!.complete(const EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.normal,
        ));

        await refreshFuture;

        // Snapshot should remain null (logout cleared it, in-flight ignored)
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('swallows exceptions when init failed', () async {
        fakeClient.configureThrows = true;
        try {
          await service.init();
        } catch (_) {}

        // This should complete without throwing even though init failed
        await expectLater(
          service.refreshEntitlement(),
          completes,
        );
      });
    });

    group('restorePurchases()', () {
      test('throws StateError if init not called', () async {
        expect(
          () => service.restorePurchases(),
          throwsA(isA<StateError>()),
        );
      });

      test('does nothing if init failed', () async {
        fakeClient.configureThrows = true;

        try {
          await service.init();
        } catch (_) {}

        await service.restorePurchases();

        expect(fakeClient.restorePurchasesWasCalled, isFalse);
      });

      test('does nothing if not identified', () async {
        await service.init();

        await service.restorePurchases();

        expect(fakeClient.restorePurchasesWasCalled, isFalse);
      });

      test('calls client restore and refreshes entitlement', () async {
        await service.init();
        await service.identify('user-123');

        const snapshot = EntitlementSnapshot(
          appUserId: 'user-123',
          hasProEntitlement: true,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_yearly',
          expirationDate: null,
          originalTransactionId: null,
          latestPurchaseDate: null,
          lastPeriodType: EntitlementPeriodType.normal,
        );
        fakeClient.snapshotToReturn = snapshot;

        await service.restorePurchases();

        expect(fakeClient.restorePurchasesWasCalled, isTrue);
        expect(service.entitlementSnapshot.value, equals(snapshot));
      });
    });

    group('entitlement stream listener', () {
      test('ignores snapshots for wrong user', () async {
        await service.init();
        await service.identify('user-123');

        // Clear the snapshot set by identify
        fakeClient.snapshotToReturn = null;
        service.entitlementSnapshot.value = null;

        // Emit a snapshot for a different user
        final wrongUserSnapshot =
            EntitlementSnapshot.none(appUserId: 'other-user');
        fakeClient.simulateEntitlementChange(wrongUserSnapshot);

        // Allow stream event to propagate
        await Future<void>.delayed(Duration.zero);

        // Snapshot should not be updated
        expect(service.entitlementSnapshot.value, isNull);
      });

      test('updates snapshot for correct user', () async {
        await service.init();
        await service.identify('user-123');

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

        fakeClient.simulateEntitlementChange(snapshot);

        // Allow stream event to propagate
        await Future<void>.delayed(Duration.zero);

        expect(service.entitlementSnapshot.value, equals(snapshot));
      });

      test('ignores snapshots when no user identified', () async {
        await service.init();

        final snapshot = EntitlementSnapshot.none(appUserId: 'user-123');
        fakeClient.simulateEntitlementChange(snapshot);

        // Allow stream event to propagate
        await Future<void>.delayed(Duration.zero);

        // Snapshot should remain null (no identified user)
        expect(service.entitlementSnapshot.value, isNull);
      });
    });

    group('initial state', () {
      test('entitlementSnapshot starts as null', () {
        expect(service.entitlementSnapshot.value, isNull);
      });
    });
  });
}
