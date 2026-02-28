import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/settings/settings_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../factories/factories.dart';
import '../mocks/mock_services.dart';

class MockHomeBottomTabCoordinator extends Mock
    implements HomeBottomTabCoordinator {}

void main() {
  late MockRouterService mockRouterService;
  late MockAuthService mockAuthService;
  late MockRevenueCatService mockRevenueCatService;
  late MockHomeBottomTabCoordinator mockTabCoordinator;
  late SubscriptionStatusResolver resolver;
  late List<(Uri, LaunchMode)> launchCalls;

  Future<bool> fakeLaunch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
    launchCalls.add((uri, mode));
    return true;
  }

  setUpAll(() {
    registerFallbackValue(Path(name: '/'));
    registerFallbackValue(HomeBottomTab.stack);
  });

  setUp(() {
    mockRouterService = MockRouterService();
    mockAuthService = MockAuthService();
    mockRevenueCatService = MockRevenueCatService();
    mockTabCoordinator = MockHomeBottomTabCoordinator();
    resolver = const SubscriptionStatusResolver();
    launchCalls = [];

    // Default: null snapshot (RC unavailable, fallback to DB)
    when(
      () => mockRevenueCatService.entitlementSnapshot,
    ).thenReturn(ValueNotifier<EntitlementSnapshot?>(null));
  });

  SettingsViewModel createViewModel({
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  }) {
    return SettingsViewModel(
      routerService: mockRouterService,
      authService: mockAuthService,
      subscriptionStatusResolver: resolver,
      revenueCatService: mockRevenueCatService,
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
        when(() => mockRouterService.goTo(any())).thenReturn(null);

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
        when(() => mockRouterService.goTo(any())).thenReturn(null);

        final vm = createViewModel();
        addTearDown(vm.dispose);

        vm.goToContact();

        final captured = verify(
          () => mockRouterService.goTo(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Path).name, '/settings/contact');
      });
    });

    group('onSelectBottomTab', () {
      test('delegates to tab coordinator with settings as current tab', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockTabCoordinator.onSelect(
            any(),
            currentTab: any(named: 'currentTab'),
          ),
        ).thenReturn(null);

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
