import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/paywall_constants.dart';
import 'package:neurostack/paywall/widgets/trial_expired_modal.dart';
import 'package:neurostack/paywall/widgets/trial_reminder_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../test/factories/entitlement_snapshot_factory.dart';
import '../../test/factories/user_factory.dart';
import '../mocks/fake_revenuecat_client.dart';
import '../mocks/fake_services.dart';
import '../mocks/mock_data_sources.dart';
import '../utils/auth_helpers.dart';
import '../utils/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeRevenueCatClient fakeRcClient;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeRcClient = FakeRevenueCatClient();
  });

  tearDown(() {
    fakeRcClient.dispose();
    locator.reset();
  });

  // ---------------------------------------------------------------------------
  // Phase 12.3: Purchase Flow
  // ---------------------------------------------------------------------------

  group('Purchase Flow', () {
    testWidgets(
      'purchaseFlow_paywallPresented_purchaseUpdatesEntitlement',
      (tester) async {
        // Arrange: Free user with no entitlement
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        fakeRcClient.nextPaywallOutcome = PaywallOutcome.purchased;

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: EntitlementSnapshot.none(appUserId: user.id),
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Act: Simulate purchase by updating snapshot before paywall returns
        final purchasedSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        fakeRcClient.setSnapshot(purchasedSnapshot);

        // Present paywall via service (simulates what PaywallView does)
        final outcome = await rcService.presentPaywall();

        // Pump to let UI react to entitlement change
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Assert
        expect(outcome, equals(PaywallOutcome.purchased));
        expect(fakeRcClient.presentPaywallCallCount, equals(1));
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );
        expect(
          rcService.entitlementSnapshot.value?.productId,
          equals(kProductMonthly),
        );
      },
    );

    testWidgets(
      'purchaseFlow_paywallCancelled_entitlementUnchanged',
      (tester) async {
        // Arrange: Free user who cancels paywall
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        fakeRcClient.nextPaywallOutcome = PaywallOutcome.cancelled;

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: EntitlementSnapshot.none(appUserId: user.id),
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Act: Present paywall and cancel
        final outcome = await rcService.presentPaywall();
        await tester.pump(const Duration(milliseconds: 500));

        // Assert
        expect(outcome, equals(PaywallOutcome.cancelled));
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isFalse,
        );
      },
    );

    testWidgets(
      'purchaseFlow_restorePurchases_updatesEntitlement',
      (tester) async {
        // Arrange: Free user with a restorable purchase
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: EntitlementSnapshot.none(appUserId: user.id),
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Simulate that restore will find a premium subscription
        final restoredSnapshot = EntitlementSnapshotFactory.activePaidYearly(
          userId: user.id,
        );
        fakeRcClient.setSnapshot(restoredSnapshot);

        // Act
        final result = await rcService.restorePurchases();
        await tester.pump(const Duration(milliseconds: 500));

        // Assert
        expect(result, isTrue);
        expect(fakeRcClient.restorePurchasesCallCount, equals(1));
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );
        expect(
          rcService.entitlementSnapshot.value?.productId,
          equals(kProductYearly),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Phase 12.3: Trial → Expiration → Modal Flow
  // ---------------------------------------------------------------------------

  group('Trial Expiration Flow', () {
    testWidgets(
      'trialExpiration_trialExpires_showsExpiredModal',
      (tester) async {
        // Arrange: User with expired trial (transition from trial -> free)
        // DB status is 'trial', RC says trial expired (wasTrialThatExpired)
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        // Pre-seed lastSeenStatus as 'trial' to simulate the transition
        await prefs.setString(
          'lastSeenEffectiveStatus:${user.id}',
          SubscriptionStatus.trial.name,
        );

        // RC snapshot shows trial has expired
        final expiredTrialSnapshot = EntitlementSnapshotFactory.expiredTrial(
          userId: user.id,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: expiredTrialSnapshot,
        );
        addTearDown(authController.close);

        // Allow post-frame callbacks to fire (modal is shown via addPostFrameCallback)
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 500));

        // Assert: Trial expired modal should be visible
        expect(find.byType(TrialExpiredModal), findsOneWidget);
      },
    );

    testWidgets(
      'trialExpiration_premiumExpires_showsExpiredModal',
      (tester) async {
        // Arrange: User with expired paid subscription
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        );

        final expiredPaidSnapshot = EntitlementSnapshotFactory.expiredPaid(
          userId: user.id,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: expiredPaidSnapshot,
        );
        addTearDown(authController.close);

        // Allow post-frame callbacks
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 500));

        // Assert: Should show expired modal (for paid subscription lapse)
        expect(find.byType(TrialExpiredModal), findsOneWidget);
      },
    );

    testWidgets(
      'trialExpiration_activeTrialUser_noModalShown',
      (tester) async {
        // Arrange: User with active trial (should NOT show modal)
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        final activeTrialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: user.id,
          expirationDate: DateTime.now().add(const Duration(days: 5)),
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: activeTrialSnapshot,
        );
        addTearDown(authController.close);

        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 500));

        // Assert: No modal should appear
        expect(find.byType(TrialExpiredModal), findsNothing);
      },
    );

    testWidgets(
      'trialExpiration_premiumUser_noModalShown',
      (tester) async {
        // Arrange: Premium monthly user (no modal)
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumMonthly,
          onboardingCompleted: true,
        );

        final premiumSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: premiumSnapshot,
        );
        addTearDown(authController.close);

        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 500));

        // Assert
        expect(find.byType(TrialExpiredModal), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Phase 12.3: Trial Reminder Flow
  // ---------------------------------------------------------------------------

  group('Trial Reminder Flow', () {
    testWidgets(
      'trialReminder_within24h_showsReminderAlert',
      (tester) async {
        // Arrange: Trial user within 24h of expiration
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        final expirationDate = DateTime.now().add(const Duration(hours: 12));
        final trialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: user.id,
          expirationDate: expirationDate,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: trialSnapshot,
        );
        addTearDown(authController.close);

        // Allow UI to fully settle
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert: Trial reminder alert should be visible
        expect(find.byType(TrialReminderAlert), findsOneWidget);
        expect(find.text('Your trial ends soon'), findsOneWidget);
        expect(find.text('Upgrade Now'), findsOneWidget);
      },
    );

    testWidgets(
      'trialReminder_moreThan24h_noReminderShown',
      (tester) async {
        // Arrange: Trial with >24h remaining (no reminder)
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        final expirationDate = DateTime.now().add(const Duration(days: 3));
        final trialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: user.id,
          expirationDate: expirationDate,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: trialSnapshot,
        );
        addTearDown(authController.close);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert: No reminder alert
        expect(find.byType(TrialReminderAlert), findsNothing);
      },
    );

    testWidgets(
      'trialReminder_shownWithin24h_throttledAfterFirstShow',
      (tester) async {
        // Arrange: Trial within 24h, but already shown today
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        // Pre-seed that reminder was shown recently (within 24h)
        final now = DateTime.now();
        await prefs.setString(
          'trialReminder:lastShownAt:${user.id}',
          now.subtract(const Duration(hours: 2)).toUtc().toIso8601String(),
        );

        final expirationDate = now.add(const Duration(hours: 12));
        final trialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: user.id,
          expirationDate: expirationDate,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: trialSnapshot,
        );
        addTearDown(authController.close);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Assert: Reminder throttled (shown within last 24h)
        expect(find.byType(TrialReminderAlert), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Phase 12.3: Entitlement Real-time Updates
  // ---------------------------------------------------------------------------

  group('Real-time Entitlement Updates', () {
    testWidgets(
      'entitlementChange_trialToPurchased_updatesSnapshot',
      (tester) async {
        // Arrange: User starts on trial
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        final trialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: user.id,
          expirationDate: DateTime.now().add(const Duration(days: 5)),
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: trialSnapshot,
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Verify initial state is trial
        expect(rcService.entitlementSnapshot.value?.isTrialPeriod, isTrue);

        // Act: Simulate real-time entitlement change (user purchased)
        final purchasedSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        fakeRcClient.simulateEntitlementChange(purchasedSnapshot);

        // Allow stream event to propagate
        await tester.pump(const Duration(milliseconds: 500));

        // Assert: Snapshot updated to paid
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );
        expect(
          rcService.entitlementSnapshot.value?.isTrialPeriod,
          isFalse,
        );
        expect(
          rcService.entitlementSnapshot.value?.productId,
          equals(kProductMonthly),
        );
      },
    );

    testWidgets(
      'entitlementChange_wrongUser_ignoredByService',
      (tester) async {
        // Arrange: User is identified, but entitlement change is for different user
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: EntitlementSnapshot.none(appUserId: user.id),
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Capture initial snapshot
        final initialSnapshot = rcService.entitlementSnapshot.value;

        // Act: Emit entitlement for a different user
        final wrongUserSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: 'different-user-id',
        );
        fakeRcClient.simulateEntitlementChange(wrongUserSnapshot);

        await tester.pump(const Duration(milliseconds: 500));

        // Assert: Snapshot unchanged (wrong user ignored)
        expect(rcService.entitlementSnapshot.value, equals(initialSnapshot));
      },
    );

    testWidgets(
      'entitlementChange_nullDoesNotClobberKnownState',
      (tester) async {
        // Arrange: User with known premium state
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumMonthly,
          onboardingCompleted: true,
        );

        final premiumSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: premiumSnapshot,
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Verify premium state
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );

        // Act: Set snapshot to null (simulating transient failure)
        // then refresh - should NOT clobber known state
        fakeRcClient.setSnapshot(null);
        await rcService.refreshEntitlement();
        await tester.pump(const Duration(milliseconds: 500));

        // Assert: Known premium state preserved (Design Principle #11)
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Phase 12.3: RevenueCat Service Lifecycle
  // ---------------------------------------------------------------------------

  group('Service Lifecycle', () {
    testWidgets(
      'lifecycle_identifyBeforeInit_throwsStateError',
      (tester) async {
        // Arrange: Minimal app — don't go through full auth flow
        final authStateController =
            StreamController<supabase.AuthState>.broadcast();
        addTearDown(authStateController.close);

        final mockAuth = MockGoTrueClient();
        when(() => mockAuth.onAuthStateChange)
            .thenAnswer((_) => authStateController.stream);
        when(() => mockAuth.currentSession).thenReturn(null);

        final mockDataSource = MockDataSourceAbstraction();
        when(() => mockDataSource.auth).thenReturn(mockAuth);

        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        final app = await createTestApp(
          sharedPreferences: prefs,
          dataSource: mockDataSource,
          connectivityService: FakeConnectivityService(),
          userBootstrapService: FakeUserBootstrapService(user),
          revenueCatClient: fakeRcClient,
        );

        await tester.pumpWidget(app);

        final rcService = locator<RevenueCatService>();

        // Act & Assert: identify() without init() should throw
        expect(
          () => rcService.identify(user.id),
          throwsA(isA<StateError>()),
        );
      },
    );

    testWidgets(
      'lifecycle_presentPaywallBeforeIdentify_returnsError',
      (tester) async {
        // Arrange: Minimal app — init RC but don't identify
        final authStateController =
            StreamController<supabase.AuthState>.broadcast();
        addTearDown(authStateController.close);

        final mockAuth = MockGoTrueClient();
        when(() => mockAuth.onAuthStateChange)
            .thenAnswer((_) => authStateController.stream);
        when(() => mockAuth.currentSession).thenReturn(null);

        final mockDataSource = MockDataSourceAbstraction();
        when(() => mockDataSource.auth).thenReturn(mockAuth);

        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        final app = await createTestApp(
          sharedPreferences: prefs,
          dataSource: mockDataSource,
          connectivityService: FakeConnectivityService(),
          userBootstrapService: FakeUserBootstrapService(user),
          revenueCatClient: fakeRcClient,
        );

        await tester.pumpWidget(app);

        final rcService = locator<RevenueCatService>();
        await rcService.init();
        // Note: NOT calling identify()

        // Act
        final outcome = await rcService.presentPaywall();

        // Assert
        expect(outcome, equals(PaywallOutcome.error));
      },
    );

    testWidgets(
      'lifecycle_logoutClearsSnapshot',
      (tester) async {
        // Arrange: Premium user, fully authenticated
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumMonthly,
          onboardingCompleted: true,
        );

        final premiumSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );

        final authController = await pumpToHomeWithUser(
          tester: tester,
          user: user,
          rcClient: fakeRcClient,
          prefs: prefs,
          initialSnapshot: premiumSnapshot,
        );
        addTearDown(authController.close);

        final rcService = locator<RevenueCatService>();

        // Verify premium state seeded
        expect(
          rcService.entitlementSnapshot.value?.hasProEntitlement,
          isTrue,
        );

        // Act: Logout from RC
        await rcService.logout();
        await tester.pump(const Duration(milliseconds: 200));

        // Assert: Snapshot cleared to null
        expect(rcService.entitlementSnapshot.value, isNull);
      },
    );
  });
}
