import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart'
    as protocol;
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/library_view_model.dart';
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

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRevenueCatService extends Mock implements RevenueCatService {}

void main() {
  late MockNotifyService mockNotifyService;
  late MockRouterService mockRouterService;
  late MockAuthService mockAuthService;
  late MockUserRepository mockUserRepository;
  late MockProtocolRepository mockProtocolRepository;
  late MockSessionRepository mockSessionRepository;
  late MockConnectivityService mockConnectivityService;
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
    mockConnectivityService = MockConnectivityService();
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

  LibraryViewModel createViewModel() {
    return LibraryViewModel(
      notifyService: mockNotifyService,
      routerService: mockRouterService,
      authService: mockAuthService,
      userRepository: mockUserRepository,
      protocolRepository: mockProtocolRepository,
      sessionRepository: mockSessionRepository,
      connectivityService: mockConnectivityService,
      subscriptionStatusResolver: subscriptionStatusResolver,
      revenueCatService: mockRevenueCatService,
    );
  }

  group('LibraryViewModel', () {
    group('card locking (resolver-based)', () {
      test('free user at capacity - extra protocols are locked', () async {
        // Arrange: free user with 2 active protocols, 3 total protocols available
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.atFreeCapacity(), // protocol-1, protocol-2
          onboardingCompleted: true,
        );

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        final protocol2 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol2,
          category: protocol.Category.exercise,
        );
        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1, protocol2, protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - protocol-1 and protocol-2 are in stack, protocol-3 is locked
        final cards = viewModel.state.value.cards;
        expect(cards, hasLength(3));

        final card1 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol1);
        final card2 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol2);
        final card3 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol3);

        expect(card1.status, LibraryCardStatus.inStack);
        expect(card2.status, LibraryCardStatus.inStack);
        expect(card3.status, LibraryCardStatus.locked);
      });

      test('premium user - all protocols available (no locking)', () async {
        // Arrange: premium user with 2 active protocols
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.premiumMonthly,
          stack: StackFactory.atFreeCapacity(), // protocol-1, protocol-2
          onboardingCompleted: true,
        );

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        final protocol2 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol2,
          category: protocol.Category.exercise,
        );
        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1, protocol2, protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - all non-active protocols are available, not locked
        final cards = viewModel.state.value.cards;
        final card3 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol3);
        expect(card3.status, LibraryCardStatus.available);
      });

      test('trial user - all protocols available (no locking)', () async {
        // Arrange: trial user with 2 active protocols
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,

          stack: StackFactory.atFreeCapacity(),
          onboardingCompleted: true,
        );

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1, protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        final cards = viewModel.state.value.cards;
        final card3 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol3);
        expect(card3.status, LibraryCardStatus.available);
      });

      test('RC snapshot overrides DB status for locking', () async {
        // Arrange: user with trial in DB, but RC says premium monthly
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.atFreeCapacity(),
          onboardingCompleted: true,
        );

        // RC says user has premium monthly subscription
        final snapshot = EntitlementSnapshot(
          appUserId: user.id,
          hasProEntitlement: true,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: DateTime.now().add(const Duration(days: 30)),
          originalTransactionId: 'txn-001',
          latestPurchaseDate: DateTime.now(),
          lastPeriodType: EntitlementPeriodType.normal,
        );

        when(() => mockRevenueCatService.entitlementSnapshot)
            .thenReturn(ValueNotifier<EntitlementSnapshot?>(snapshot));
        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));

        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - RC says premium, so protocol should be available (not locked)
        final cards = viewModel.state.value.cards;
        final card3 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol3);
        expect(card3.status, LibraryCardStatus.available);
      });

      test('expired user - extra protocols are locked', () async {
        // Arrange: expired user with 2 active protocols
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.expired,
          stack: StackFactory.atFreeCapacity(),
          onboardingCompleted: true,
        );

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        final protocol2 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol2,
          category: protocol.Category.exercise,
        );
        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1, protocol2, protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - expired has limit of 2, so protocol-3 is locked
        final cards = viewModel.state.value.cards;
        final card3 = cards.firstWhere((c) => c.protocolId == StackFactory.protocol3);
        expect(card3.status, LibraryCardStatus.locked);
      });
    });

    group('entitlement changes trigger refresh', () {
      test('entitlement snapshot change triggers library refresh', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.atFreeCapacity(),
          onboardingCompleted: true,
        );

        final entitlementNotifier = ValueNotifier<EntitlementSnapshot?>(null);
        when(() => mockRevenueCatService.entitlementSnapshot)
            .thenReturn(entitlementNotifier);
        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        final protocol3 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol3,
          category: protocol.Category.exercise,
        );
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1, protocol3]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        await viewModel.init();

        // First load: free user -> protocol-3 is locked
        final cardsBeforeChange = viewModel.state.value.cards;
        final cardBeforeChange = cardsBeforeChange.firstWhere(
          (c) => c.protocolId == StackFactory.protocol3,
        );
        expect(cardBeforeChange.status, LibraryCardStatus.locked);

        // Verify init called getById once, then clear for clean assertion
        verify(() => mockUserRepository.getById(any())).called(1);
        clearInteractions(mockUserRepository);

        // Act: entitlement changes to premium
        final premiumSnapshot = EntitlementSnapshot(
          appUserId: user.id,
          hasProEntitlement: true,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: 'neurostack_monthly',
          expirationDate: DateTime.now().add(const Duration(days: 30)),
          originalTransactionId: 'txn-001',
          latestPurchaseDate: DateTime.now(),
          lastPeriodType: EntitlementPeriodType.normal,
        );
        entitlementNotifier.value = premiumSnapshot;

        // Allow async refresh to complete
        await pumpEventQueue();

        // Assert - getById called once more (refresh triggered by entitlement change)
        verify(() => mockUserRepository.getById(any())).called(1);

        // After refresh with premium snapshot: protocol-3 should be available
        final cardsAfterChange = viewModel.state.value.cards;
        final cardAfterChange = cardsAfterChange.firstWhere(
          (c) => c.protocolId == StackFactory.protocol3,
        );
        expect(cardAfterChange.status, LibraryCardStatus.available);
      });
    });

    group('connectivity changes', () {
      test('going offline updates state', () async {
        // Arrange
        final connectivityNotifier = ValueNotifier(NetworkStatus.online);
        when(() => mockConnectivityService.status)
            .thenReturn(connectivityNotifier);

        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.underFreeLimit(),
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        await viewModel.init();

        expect(viewModel.state.value.isOffline, isFalse);

        // Act: go offline
        connectivityNotifier.value = NetworkStatus.offline;

        // Assert
        expect(viewModel.state.value.isOffline, isTrue);
      });

      test('going online from offline triggers reload', () async {
        // Arrange: start online, load, then go offline, then go online
        final connectivityNotifier = ValueNotifier(NetworkStatus.online);
        when(() => mockConnectivityService.status)
            .thenReturn(connectivityNotifier);

        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.underFreeLimit(),
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        await viewModel.init();

        verify(() => mockUserRepository.getById(any())).called(1);
        clearInteractions(mockUserRepository);

        // Go offline
        connectivityNotifier.value = NetworkStatus.offline;
        expect(viewModel.state.value.isOffline, isTrue);

        // Act: go back online
        connectivityNotifier.value = NetworkStatus.online;

        // Allow async reload to complete
        await pumpEventQueue();

        // Assert - reload triggered (getById called once more)
        verify(() => mockUserRepository.getById(any())).called(1);
        expect(viewModel.state.value.isOffline, isFalse);
      });

      test('no-op when connectivity status unchanged', () async {
        // Arrange
        final connectivityNotifier = ValueNotifier(NetworkStatus.online);
        when(() => mockConnectivityService.status)
            .thenReturn(connectivityNotifier);

        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.underFreeLimit(),
          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);
        await viewModel.init();

        verify(() => mockUserRepository.getById(any())).called(1);

        // Clear recorded interactions so we can assert no new calls
        clearInteractions(mockUserRepository);

        // Act: fire connectivity event with same status (online -> online)
        // This happens when, e.g., wifi switches to cellular
        connectivityNotifier.notifyListeners();

        // Allow any potential async work
        await pumpEventQueue();

        // Assert - no additional getById call (no reload triggered)
        verifyNever(() => mockUserRepository.getById(any()));
      });
    });

    group('init and state', () {
      test('init sets loaded status with protocols', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,

          onboardingCompleted: true,
        );

        final protocol1 = ProtocolFactory.reconstitute(
          id: StackFactory.protocol1,
          category: protocol.Category.exercise,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([protocol1]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        expect(viewModel.state.value.status, LibraryStatus.loaded);
        expect(viewModel.state.value.cards, hasLength(1));
        expect(viewModel.state.value.user, user);
      });

      test('init sets empty status when no protocols', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,

          onboardingCompleted: true,
        );

        when(() => mockAuthService.authState)
            .thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(user));
        when(() => mockProtocolRepository.list(activeOnly: true))
            .thenAnswer((_) async => right([]));

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        expect(viewModel.state.value.status, LibraryStatus.empty);
        expect(viewModel.state.value.cards, isEmpty);
      });
    });
  });
}
