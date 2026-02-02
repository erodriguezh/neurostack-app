import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_view_model.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

import '../factories/factories.dart';

// Mocks
class MockNotifyService extends Mock implements NotifyService {}

class MockRouterService extends Mock implements RouterService {}

class MockAuthService extends Mock implements AuthService {}

class MockUserRepository extends Mock implements UserRepository {}

class MockProtocolRepository extends Mock implements ProtocolRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockSessionLocalDataSource extends Mock
    implements SessionLocalDataSource {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockCachedUserStore extends Mock implements CachedUserStore {}

class MockRevenueCatService extends Mock implements RevenueCatService {}

class MockSubscriptionStatusResolver extends Mock
    implements SubscriptionStatusResolver {}

void main() {
  late MockNotifyService mockNotifyService;
  late MockRouterService mockRouterService;
  late MockAuthService mockAuthService;
  late MockUserRepository mockUserRepository;
  late MockProtocolRepository mockProtocolRepository;
  late MockSessionRepository mockSessionRepository;
  late MockSessionLocalDataSource mockSessionLocalDataSource;
  late MockConnectivityService mockConnectivityService;
  late MockCachedUserStore mockCachedUserStore;
  late MockRevenueCatService mockRevenueCatService;
  late SubscriptionStatusResolver subscriptionStatusResolver;

  setUpAll(() {
    registerFallbackValue(ToastEventError(message: 'fallback'));
    registerFallbackValue(UserFactory.create());
  });

  setUp(() {
    mockNotifyService = MockNotifyService();
    mockRouterService = MockRouterService();
    mockAuthService = MockAuthService();
    mockUserRepository = MockUserRepository();
    mockProtocolRepository = MockProtocolRepository();
    mockSessionRepository = MockSessionRepository();
    mockSessionLocalDataSource = MockSessionLocalDataSource();
    mockConnectivityService = MockConnectivityService();
    mockCachedUserStore = MockCachedUserStore();
    mockRevenueCatService = MockRevenueCatService();
    // Use real resolver since it's pure functions
    subscriptionStatusResolver = const SubscriptionStatusResolver();

    // Default connectivity setup
    when(() => mockConnectivityService.status)
        .thenReturn(ValueNotifier(NetworkStatus.online));

    // Default RevenueCat setup - null snapshot (RC unavailable, fallback to DB)
    when(() => mockRevenueCatService.entitlementSnapshot)
        .thenReturn(ValueNotifier<EntitlementSnapshot?>(null));
  });

  HomeViewModel createViewModel() {
    return HomeViewModel(
      notifyService: mockNotifyService,
      routerService: mockRouterService,
      authService: mockAuthService,
      userRepository: mockUserRepository,
      protocolRepository: mockProtocolRepository,
      sessionRepository: mockSessionRepository,
      sessionLocalDataSource: mockSessionLocalDataSource,
      connectivityService: mockConnectivityService,
      subscriptionStatusResolver: subscriptionStatusResolver,
      revenueCatService: mockRevenueCatService,
      cachedUserStore: mockCachedUserStore,
    );
  }

  group('HomeViewModel', () {
    group('handleUseFreeTier', () {
      test(
          'with 2 protocols - status becomes free, cache updated, and refresh called',
          () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
          stack: StackFactory.atFreeCapacity(), // 2 protocols
          onboardingCompleted: true,
        );

        final updatedUser =
            user.updateSubscriptionStatus(SubscriptionStatus.free);

        when(() => mockUserRepository.save(any()))
            .thenAnswer((_) async => right(unit));
        when(() => mockCachedUserStore.saveUser(any()))
            .thenAnswer((_) async {});

        // Setup auth state for refresh
        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(updatedUser));
        when(() => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(() =>
                mockSessionLocalDataSource.upsertSyncedSessions(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockProtocolRepository.getById(any()))
            .thenAnswer((_) async => right(ProtocolFactory.reconstitute()));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        viewModel.state.value = viewModel.state.value.copyWith(user: user);

        // Act
        await viewModel.handleUseFreeTier();

        // Assert - verify save with correct status
        verify(
          () => mockUserRepository.save(
            any(
              that: predicate<User>(
                (u) => u.subscriptionStatus == SubscriptionStatus.free,
              ),
            ),
          ),
        ).called(1);
        verify(() => mockCachedUserStore.saveUser(any())).called(1);
        expect(viewModel.state.value.showDeactivationModal, isFalse);

        // Assert - verify refresh was called (getById invoked)
        verify(() => mockUserRepository.getById(any())).called(1);

        // Assert - verify state was updated with refreshed user
        expect(
          viewModel.state.value.user?.subscriptionStatus,
          SubscriptionStatus.free,
        );
      });

      test('with 3 protocols - triggers deactivation modal', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
          stack: StackFactory.overFreeCapacity(), // 3 protocols
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        viewModel.state.value = viewModel.state.value.copyWith(user: user);

        // Act
        await viewModel.handleUseFreeTier();

        // Assert
        expect(viewModel.state.value.showDeactivationModal, isTrue);
        verifyNever(() => mockUserRepository.save(any()));
      });
    });

    group('_maybeTriggerExpiredModal (via init)', () {
      test(
          'does NOT trigger for trial status without RC snapshot (no transition)',
          () async {
        // Arrange - trial status without RC snapshot means we can't detect
        // expiration. Modal only triggers on status transitions or expired status.
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(() =>
                mockSessionLocalDataSource.upsertSyncedSessions(any(), any()))
            .thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - without RC snapshot, effective status is DB status (trial)
        // Modal does not trigger because there's no detected transition
        expect(viewModel.state.value.showTrialExpiredModal, isFalse);
      });

      test('triggers for premium expiration (expired status)', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(() =>
                mockSessionLocalDataSource.upsertSyncedSessions(any(), any()))
            .thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        expect(viewModel.state.value.showTrialExpiredModal, isTrue);
      });

      test('does NOT trigger for active trial', () async {
        // Arrange - trial started 1 day ago relative to now, 6 days remaining
        final now = DateTime.now();
        final activeTrialPeriod = TrialPeriodFactory.create(
          startDate: now.subtract(const Duration(days: 1)),
        );
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: activeTrialPeriod,
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(() =>
                mockSessionLocalDataSource.upsertSyncedSessions(any(), any()))
            .thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        expect(viewModel.state.value.showTrialExpiredModal, isFalse);
      });

      test('does NOT trigger for free user with expired trialPeriod', () async {
        // Arrange - user who chose free tier (status=free) but still has
        // the old expired trialPeriod. Modal should NOT re-trigger.
        // This is a critical regression test for the modal not re-appearing.
        final now = DateTime.now();
        final expiredTrialPeriod = TrialPeriodFactory.create(
          startDate: now.subtract(const Duration(days: 10)),
        );
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          trialPeriod: expiredTrialPeriod,
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            )).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(() =>
                mockSessionLocalDataSource.upsertSyncedSessions(any(), any()))
            .thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - modal should NOT trigger for free users
        expect(viewModel.state.value.showTrialExpiredModal, isFalse);
      });
    });

    group('isTrialOrPremiumExpired', () {
      // Note: isTrialOrPremiumExpired() is now synchronous and checks
      // effective status (expired/free) rather than legacy trialPeriod.

      test('returns false for trial status (regardless of trialPeriod)', () {
        // Arrange - when RC is unavailable, effective status is the DB status.
        // For trial status, the method returns false since it only checks
        // for expired/free states. The modal trigger logic is in
        // _maybeTriggerExpiredModal() which uses status transitions.
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert - trial is not expired/free, so returns false
        expect(result, isFalse);
      });

      test('returns true for expired status', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert
        expect(result, isTrue);
      });

      test('returns true for free status', () {
        // Arrange - free users are considered "expired" for paywall purposes
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert
        expect(result, isTrue);
      });

      test('returns false for premium monthly', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumMonthly,
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert
        expect(result, isFalse);
      });

      test('returns false for premium annual', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumAnnual,
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert
        expect(result, isFalse);
      });

      test('returns false for grace status', () {
        // Arrange - grace means billing issue but still has access
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.grace,
          onboardingCompleted: true,
        );

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        final result = viewModel.isTrialOrPremiumExpired(user);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
