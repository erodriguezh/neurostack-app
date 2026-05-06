import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/settings/settings_view_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../factories/factories.dart';
import '../mocks/mock_services.dart';

class MockHomeBottomTabCoordinator extends Mock
    implements HomeBottomTabCoordinator {}

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  late MockRouterService mockRouterService;
  late MockAuthService mockAuthService;
  late MockRevenueCatService mockRevenueCatService;
  late MockUserOrientService mockUserOrientService;
  late MockNotifyService mockNotifyService;
  late MockHomeBottomTabCoordinator mockTabCoordinator;
  late SubscriptionStatusResolver resolver;
  late List<(Uri, LaunchMode)> launchCalls;
  late BuildContext fakeContext;

  Future<bool> fakeLaunch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    launchCalls.add((uri, mode));
    return true;
  }

  setUpAll(() {
    registerFallbackValue(Path(name: '/'));
    registerFallbackValue(HomeBottomTab.stack);
    registerFallbackValue(_FakeBuildContext());
    registerFallbackValue(ToastEventInfo(message: ''));
  });

  setUp(() {
    mockRouterService = MockRouterService();
    mockAuthService = MockAuthService();
    mockRevenueCatService = MockRevenueCatService();
    mockUserOrientService = MockUserOrientService();
    mockNotifyService = MockNotifyService();
    mockTabCoordinator = MockHomeBottomTabCoordinator();
    resolver = const SubscriptionStatusResolver();
    launchCalls = [];
    fakeContext = _FakeBuildContext();

    // Default: null snapshot (RC unavailable, fallback to DB)
    when(
      () => mockRevenueCatService.entitlementSnapshot,
    ).thenReturn(ValueNotifier<EntitlementSnapshot?>(null));
  });

  SettingsViewModel createViewModel({
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
    PackageInfo? packageInfo,
  }) {
    return SettingsViewModel(
      routerService: mockRouterService,
      authService: mockAuthService,
      subscriptionStatusResolver: resolver,
      revenueCatService: mockRevenueCatService,
      userOrientService: mockUserOrientService,
      notifyService: mockNotifyService,
      packageInfo: packageInfo ??
          PackageInfo(
            appName: 'NeuroStack',
            packageName: 'app.getneurostack',
            version: '1.0.0',
            buildNumber: '1',
          ),
      tabCoordinator: mockTabCoordinator,
      launch: launch ?? fakeLaunch,
    );
  }

  group('SettingsViewModel', () {
    group('isPremium initialization', () {
      test('is false when user is free', () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.isPremium.value, isFalse);
      });

      test('is true when user is premiumMonthly', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.isPremium.value, isTrue);
      });

      test('is true when user is premiumAnnual', () {
        final user = UserFactory.createPremiumAnnual();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.isPremium.value, isTrue);
      });

      test('is false when authState is Unauthenticated', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.isPremium.value, isFalse);
      });

      test('resolves from AuthenticatedOffline', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOffline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.isPremium.value, isTrue);
      });
    });

    group('onEntitlementChanged (live updates)', () {
      test('updates isPremium when entitlement changes', () {
        // Start as free user
        final freeUser = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshotNotifier = ValueNotifier<EntitlementSnapshot?>(null);
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(snapshotNotifier);
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(freeUser)));

        final vm = createViewModel();
        addTearDown(vm.dispose);
        vm.init();

        expect(vm.isPremium.value, isFalse);

        // Simulate entitlement change: user becomes premium via RC snapshot
        final premiumSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: freeUser.id,
        );
        snapshotNotifier.value = premiumSnapshot;

        expect(vm.isPremium.value, isTrue);
      });

      test('stays false when entitlement changes but user is still free', () {
        final freeUser = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshotNotifier = ValueNotifier<EntitlementSnapshot?>(null);
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(snapshotNotifier);
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(freeUser)));

        final vm = createViewModel();
        addTearDown(vm.dispose);
        vm.init();

        expect(vm.isPremium.value, isFalse);

        // Snapshot changes but still no entitlement (expired trial)
        final freeSnapshot = EntitlementSnapshotFactory.expiredTrial(
          userId: freeUser.id,
        );
        snapshotNotifier.value = freeSnapshot;

        expect(vm.isPremium.value, isFalse);
      });
    });

    group('navigation', () {
      test('goToPaywall calls router with /paywall', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.goToPaywall();

        final captured = verify(
          () => mockRouterService.goTo(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Path).name, '/paywall');
      });

      test('goToContact calls router with /settings/contact', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.goToContact();

        final captured = verify(
          () => mockRouterService.goTo(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Path).name, '/settings/contact');
      });

      test('goToRateApp calls router with /settings/rate-app', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.goToRateApp();

        final captured = verify(
          () => mockRouterService.goTo(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Path).name, '/settings/rate-app');
      });
    });

    group('onSelectBottomTab', () {
      test('delegates to tab coordinator with settings as current tab', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.onSelectBottomTab(HomeBottomTab.library);

        verify(
          () => mockTabCoordinator.onSelect(
            HomeBottomTab.library,
            currentTab: HomeBottomTab.settings,
          ),
        ).called(1);
      });
    });

    group('openFeatureRequestBoard', () {
      test('calls openBoard with correct userId and isPaying for premium user',
          () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.openFeatureRequestBoard(fakeContext);

        verify(
          () => mockUserOrientService.openBoard(
            any(),
            userId: user.id,
            isPaying: true,
          ),
        ).called(1);
      });

      test('calls openBoard with isPaying false for free user', () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.openFeatureRequestBoard(fakeContext);

        verify(
          () => mockUserOrientService.openBoard(
            any(),
            userId: user.id,
            isPaying: false,
          ),
        ).called(1);
      });

      test('derives isPaying from RC snapshot when available', () {
        // Free DB status but premium via RC snapshot
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.openFeatureRequestBoard(fakeContext);

        verify(
          () => mockUserOrientService.openBoard(
            any(),
            userId: user.id,
            isPaying: true,
          ),
        ).called(1);
      });

      test('works with AuthenticatedOffline', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOffline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.openFeatureRequestBoard(fakeContext);

        verify(
          () => mockUserOrientService.openBoard(
            any(),
            userId: user.id,
            isPaying: true,
          ),
        ).called(1);
      });

      test('is a no-op when user is not authenticated', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.openFeatureRequestBoard(fakeContext);

        verifyNever(
          () => mockUserOrientService.openBoard(
            any(),
            userId: any(named: 'userId'),
            isPaying: any(named: 'isPaying'),
          ),
        );
      });
    });

    group('sendFeedback', () {
      test('builds mailto URI with correct scheme, path, subject, and body',
          () async {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final info = PackageInfo(
          appName: 'NeuroStack',
          packageName: 'app.getneurostack',
          version: '1.2.3',
          buildNumber: '42',
        );

        final vm = createViewModel(packageInfo: info);
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        final uri = launchCalls.first.$1;

        expect(uri.scheme, 'mailto');
        expect(uri.path, 'feedback@getneurostack.app');

        // Decode query manually (custom encoder, not standard queryParameters)
        final params = Uri.splitQueryString(uri.query);
        expect(params['subject'], 'NeuroStack Feedback');

        final body = params['body']!;
        expect(body, contains('App Version: 1.2.3+42'));
        expect(body, contains('Platform:'));
        expect(body, contains('Subscription: premiumMonthly'));
      });

      test('encodes spaces as %20 not + (Dart SDK #43838 regression)',
          () async {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        final rawQuery = launchCalls.first.$1.query;

        // subject contains a space: "NeuroStack Feedback"
        expect(rawQuery, contains('NeuroStack%20Feedback'));
        expect(rawQuery, isNot(contains('NeuroStack+Feedback')));
      });

      test(
          'effective-status regression: DB free + RC premiumMonthly → body contains premiumMonthly',
          () async {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier(snapshot));
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        final params = Uri.splitQueryString(launchCalls.first.$1.query);
        final body = params['body']!;
        expect(body, contains('Subscription: premiumMonthly'));
        expect(body, isNot(contains('Subscription: free')));
      });

      test('calls launch with LaunchMode.externalApplication', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        expect(launchCalls.first.$2, LaunchMode.externalApplication);
      });

      test('is a no-op when user is not authenticated', () async {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, isEmpty);
      });

      test('works with AuthenticatedOffline', () async {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOffline(user)));

        final info = PackageInfo(
          appName: 'NeuroStack',
          packageName: 'app.getneurostack',
          version: '2.0.0',
          buildNumber: '99',
        );

        final vm = createViewModel(packageInfo: info);
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        final uri = launchCalls.first.$1;
        expect(uri.scheme, 'mailto');
        expect(uri.path, 'feedback@getneurostack.app');

        final params = Uri.splitQueryString(uri.query);
        expect(params['body'], contains('App Version: 2.0.0+99'));
      });

      test('ignores stale snapshot for different user and falls back to DB status',
          () async {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        // Snapshot belongs to a different user — resolver must ignore it
        final staleSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: 'different-user-id',
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier(staleSnapshot));
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.sendFeedback();

        expect(launchCalls, hasLength(1));
        final params = Uri.splitQueryString(launchCalls.first.$1.query);
        final body = params['body']!;
        expect(body, contains('Subscription: free'));
        expect(body, isNot(contains('Subscription: premiumMonthly')));
      });

      test('completes normally when launch throws', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel(
          launch: (uri, {mode = LaunchMode.platformDefault}) async {
            throw Exception('launch failed');
          },
        );
        addTearDown(vm.dispose);

        // Should not propagate the exception
        await expectLater(vm.sendFeedback(), completes);
      });
    });

    group('openSubscriptionManagement', () {
      test('calls launch with iOS URL on iOS platform', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        // Override platform to iOS
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(
          () => debugDefaultTargetPlatformOverride = null,
        );

        await vm.openSubscriptionManagement();

        expect(launchCalls, hasLength(1));
        expect(
          launchCalls.first.$1.toString(),
          'https://apps.apple.com/account/subscriptions',
        );
        expect(launchCalls.first.$2, LaunchMode.externalApplication);
      });

      test('calls launch with Android URL on Android platform', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        // Default platform in tests is Android
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(
          () => debugDefaultTargetPlatformOverride = null,
        );

        await vm.openSubscriptionManagement();

        expect(launchCalls, hasLength(1));
        expect(
          launchCalls.first.$1.toString(),
          'https://play.google.com/store/account/subscriptions',
        );
        expect(launchCalls.first.$2, LaunchMode.externalApplication);
      });
    });

    group('canAccessPremium initialization', () {
      test('is true when user is trial', () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
        );
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.canAccessPremium.value, isTrue);
      });

      test('is false when user is free', () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.canAccessPremium.value, isFalse);
      });

      test('is true when user is premiumMonthly', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.canAccessPremium.value, isTrue);
      });

      test('is false when authState is Unauthenticated', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.canAccessPremium.value, isFalse);
      });

      test('updates when entitlement changes', () {
        final freeUser = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshotNotifier = ValueNotifier<EntitlementSnapshot?>(null);
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(snapshotNotifier);
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(freeUser)));

        final vm = createViewModel();
        addTearDown(vm.dispose);
        vm.init();

        expect(vm.canAccessPremium.value, isFalse);

        // Simulate trial activation via RC snapshot
        final trialSnapshot = EntitlementSnapshotFactory.activeTrial(
          userId: freeUser.id,
        );
        snapshotNotifier.value = trialSnapshot;

        expect(vm.canAccessPremium.value, isTrue);
      });
    });

    group('restorePurchases', () {
      test('calls revenueCatService.restorePurchases', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => true);

        // After restore, snapshot has entitlement
        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        verify(() => mockRevenueCatService.restorePurchases()).called(1);
      });

      test('shows success toast when restore succeeds with entitlement',
          () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => true);

        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventSuccess>());
        expect(
          (captured.first as ToastEventSuccess).message,
          'Purchases restored successfully',
        );
      });

      test('shows info toast when restore succeeds without entitlement',
          () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => true);

        // No entitlement after restore
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(null));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventInfo>());
        expect(
          (captured.first as ToastEventInfo).message,
          'No previous purchases found',
        );
      });

      test('shows error toast when restore fails', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => false);

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventError>());
        expect(
          (captured.first as ToastEventError).message,
          'Unable to restore purchases. Please try again.',
        );
      });

      test('double-tap guard: second call while restoring is ignored',
          () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));

        // Use a completer to control when the restore completes
        var callCount = 0;
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async {
          callCount++;
          // Simulate a slow restore
          await Future<void>.delayed(Duration.zero);
          return true;
        });

        final vm = createViewModel();
        addTearDown(vm.dispose);

        // Fire two restores concurrently
        final f1 = vm.restorePurchases();
        final f2 = vm.restorePurchases();
        await Future.wait([f1, f2]);

        // Only one call should have gone through
        expect(callCount, 1);
      });

      test('shows error toast when restore throws', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenThrow(StateError('init not called'));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventError>());
      });

      test('does not show toast after disposal', () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async {
          // Simulate: VM gets disposed during the async gap
          return true;
        });

        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));

        final vm = createViewModel();

        // Start restore, then dispose before it completes
        final future = vm.restorePurchases();
        vm.dispose();
        await future;

        verifyNever(() => mockNotifyService.setToastEvent(any()));
      });

      test(
          'shows info toast when snapshot belongs to different user (stale)',
          () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => true);

        // Snapshot for a different user — should not count as entitled
        final staleSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: 'different-user-id',
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(staleSnapshot));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventInfo>());
        expect(
          (captured.first as ToastEventInfo).message,
          'No previous purchases found',
        );
      });

      test(
          'shows info toast when restore succeeds but snapshot has no entitlement',
          () async {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockRevenueCatService.restorePurchases(),
        ).thenAnswer((_) async => true);

        // Snapshot present but no entitlement
        final snapshot = EntitlementSnapshotFactory.expiredTrial(
          userId: user.id,
        );
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        await vm.restorePurchases();

        final captured = verify(
          () => mockNotifyService.setToastEvent(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect(captured.first, isA<ToastEventInfo>());
        expect(
          (captured.first as ToastEventInfo).message,
          'No previous purchases found',
        );
      });
    });

    group('dispose', () {
      test('does not throw when called after init', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        vm.init();

        expect(() => vm.dispose(), returnsNormally);
      });

      test('does not throw when called without init', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();

        expect(() => vm.dispose(), returnsNormally);
      });
    });
  });
}
