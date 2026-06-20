import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/abstractions/entitlement_listener_mixin.dart';
import 'package:neurostack/core/abstractions/premium_aware_view_model_mixin.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

import '../../factories/factories.dart';
import '../../mocks/mock_services.dart';

/// Minimal concrete class that mixes in both
/// [EntitlementListenerMixin] and [PremiumAwareViewModelMixin]
/// so we can test the mixin in isolation.
class _TestViewModel with EntitlementListenerMixin, PremiumAwareViewModelMixin {
  _TestViewModel({
    required AuthService authService,
    required SubscriptionStatusResolver resolver,
    required RevenueCatService revenueCatService,
    CachedUserStore? cachedUserStore,
  }) : _authService = authService,
       _resolver = resolver,
       _revenueCatService = revenueCatService,
       _cachedUserStore = cachedUserStore {
    initPremiumAwareness();
  }

  final AuthService _authService;
  final SubscriptionStatusResolver _resolver;
  final RevenueCatService _revenueCatService;
  final CachedUserStore? _cachedUserStore;

  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;

  @override
  AuthService get premiumAuthService => _authService;

  @override
  SubscriptionStatusResolver get premiumResolver => _resolver;

  @override
  CachedUserStore? get premiumCachedUserStore => _cachedUserStore;

  /// Exposes [resolveAuthUser] for testing without triggering
  /// invalid_use_of_protected_member.
  User? testResolveAuthUser() => resolveAuthUser();

  void init() {
    initEntitlementListener();
    onEntitlementChanged();
  }

  void dispose() {
    disposeEntitlementListener();
    disposePremiumAwareness();
  }
}

class MockCachedUserStore extends Mock implements CachedUserStore {}

void main() {
  late MockAuthService mockAuthService;
  late MockRevenueCatService mockRevenueCatService;
  late SubscriptionStatusResolver resolver;

  setUp(() {
    mockAuthService = MockAuthService();
    mockRevenueCatService = MockRevenueCatService();
    resolver = const SubscriptionStatusResolver();

    // Default: null snapshot (RC unavailable, fallback to DB)
    when(
      () => mockRevenueCatService.entitlementSnapshot,
    ).thenReturn(ValueNotifier<EntitlementSnapshot?>(null));
  });

  _TestViewModel createViewModel({CachedUserStore? cachedUserStore}) {
    return _TestViewModel(
      authService: mockAuthService,
      resolver: resolver,
      revenueCatService: mockRevenueCatService,
      cachedUserStore: cachedUserStore,
    );
  }

  group('PremiumAwareViewModelMixin', () {
    group('initPremiumAwareness (synchronous computation)', () {
      test('isPremium is false when user is free', () {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.entitlement.value.effectiveStatus, SubscriptionStatus.free);
        expect(vm.entitlement.value.protocolLimit, 2);
        expect(vm.isPremium, isFalse);
      });

      test('isPremium is true when user is premiumMonthly', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(
          vm.entitlement.value.effectiveStatus,
          SubscriptionStatus.premiumMonthly,
        );
        expect(vm.entitlement.value.protocolLimit, isNull);
        expect(vm.isPremium, isTrue);
      });

      test('isPremium is true when user is premiumAnnual', () {
        final user = UserFactory.createPremiumAnnual();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(
          vm.entitlement.value.effectiveStatus,
          SubscriptionStatus.premiumAnnual,
        );
        expect(vm.isPremium, isTrue);
      });

      test('isPremium is false when authState is Unauthenticated', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.entitlement.value, same(Entitlement.fallback));
        expect(vm.isPremium, isFalse);
      });

      test('isPremium resolves from AuthenticatedOffline', () {
        final user = UserFactory.createPremiumMonthly();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOffline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(
          vm.entitlement.value.effectiveStatus,
          SubscriptionStatus.premiumMonthly,
        );
        expect(vm.isPremium, isTrue);
      });
    });

    group('onEntitlementChanged (live updates)', () {
      test('updates isPremium when entitlement changes to premium', () {
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

        expect(vm.entitlement.value.effectiveStatus, SubscriptionStatus.free);
        expect(vm.isPremium, isFalse);

        // Simulate entitlement change: user becomes premium via RC snapshot
        final premiumSnapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: freeUser.id,
        );
        snapshotNotifier.value = premiumSnapshot;

        expect(
          vm.entitlement.value.effectiveStatus,
          SubscriptionStatus.premiumMonthly,
        );
        expect(vm.isPremium, isTrue);
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

        expect(vm.entitlement.value.effectiveStatus, SubscriptionStatus.free);
        expect(vm.isPremium, isFalse);

        // Snapshot changes but still no entitlement (expired trial)
        final freeSnapshot = EntitlementSnapshotFactory.expiredTrial(
          userId: freeUser.id,
        );
        snapshotNotifier.value = freeSnapshot;

        expect(vm.entitlement.value.effectiveStatus, SubscriptionStatus.free);
        expect(vm.isPremium, isFalse);
      });
    });

    group('resolveAuthUser', () {
      test('returns user from AuthenticatedOnline', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.testResolveAuthUser(), equals(user));
      });

      test('returns user from AuthenticatedOffline', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOffline(user)));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.testResolveAuthUser(), equals(user));
      });

      test('returns null for Unauthenticated', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.testResolveAuthUser(), isNull);
      });

      test('returns null for AuthUnknown', () {
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const AuthUnknown()));

        final vm = createViewModel();
        addTearDown(vm.dispose);

        expect(vm.testResolveAuthUser(), isNull);
      });
    });

    group('CachedUserStore fallback', () {
      test('uses CachedUserStore when auth state is not authenticated', () async {
        final premiumUser = UserFactory.createPremiumMonthly();
        final mockCachedUserStore = MockCachedUserStore();

        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(const Unauthenticated()));
        when(
          () => mockCachedUserStore.loadUser(),
        ).thenAnswer((_) async => premiumUser);

        final vm = createViewModel(cachedUserStore: mockCachedUserStore);
        addTearDown(vm.dispose);

        // Entitlement starts at fallback because auth state is unauthenticated.
        expect(vm.entitlement.value, same(Entitlement.fallback));
        expect(vm.isPremium, isFalse);

        // Trigger onEntitlementChanged, which falls back to CachedUserStore
        vm.onEntitlementChanged();

        // Allow the async loadUser to complete
        await pumpEventQueue();

        expect(
          vm.entitlement.value.effectiveStatus,
          SubscriptionStatus.premiumMonthly,
        );
        expect(vm.isPremium, isTrue);
        verify(() => mockCachedUserStore.loadUser()).called(1);
      });
    });

    group('dispose safety', () {
      test('does not throw when disposed after init', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        vm.init();

        expect(() => vm.dispose(), returnsNormally);
      });

      test('does not throw when disposed without init', () {
        final user = UserFactory.create();
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();

        expect(() => vm.dispose(), returnsNormally);
      });

      test('no-ops onEntitlementChanged after dispose', () async {
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );
        final snapshotNotifier = ValueNotifier<EntitlementSnapshot?>(null);
        when(
          () => mockRevenueCatService.entitlementSnapshot,
        ).thenReturn(snapshotNotifier);
        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));

        final vm = createViewModel();
        vm.init();
        vm.dispose();

        // After dispose, onEntitlementChanged should early-return without error.
      });
    });
  });
}
