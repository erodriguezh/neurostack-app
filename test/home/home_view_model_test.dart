import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/home/home_view_model.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

import '../factories/factories.dart';
import '../mocks/mock_services.dart';

void main() {
  late MockNotifyService mockNotifyService;
  late MockRouterService mockRouterService;
  late MockAuthService mockAuthService;
  late MockUserRepository mockUserRepository;
  late MockProtocolRepository mockProtocolRepository;
  late MockSessionRepository mockSessionRepository;
  late MockSessionLocalDataSource mockSessionLocalDataSource;
  late MockConnectivityService mockConnectivityService;
  late MockRevenueCatService mockRevenueCatService;
  late MockTrialReminderService mockTrialReminderService;
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
    mockRevenueCatService = MockRevenueCatService();
    mockTrialReminderService = MockTrialReminderService();
    // Use real resolver since it's pure functions
    subscriptionStatusResolver = const SubscriptionStatusResolver();

    // Default connectivity setup
    when(
      () => mockConnectivityService.status,
    ).thenReturn(ValueNotifier(NetworkStatus.online));

    // Default RevenueCat setup - null snapshot (RC unavailable, fallback to DB)
    when(
      () => mockRevenueCatService.entitlementSnapshot,
    ).thenReturn(ValueNotifier<EntitlementSnapshot?>(null));

    // Default trial reminder setup - never show reminder
    when(
      () => mockTrialReminderService.shouldShowTrialReminder(
        userId: any(named: 'userId'),
        snapshot: any(named: 'snapshot'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) async => false);
    when(
      () => mockTrialReminderService.markReminderShown(
        userId: any(named: 'userId'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) async {});
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
      trialReminderService: mockTrialReminderService,
    );
  }

  group('HomeViewModel', () {
    group('handleUseFreeTier', () {
      test(
        'with 2 protocols - returns true, refreshes, does NOT write to DB',
        () async {
          // Arrange
          final user = UserFactory.create(
            subscriptionStatus: SubscriptionStatus.trial,
            stack: StackFactory.atFreeCapacity(), // 2 protocols
            onboardingCompleted: true,
          );

          // Setup auth state for refresh
          when(
            () => mockAuthService.authState,
          ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
          when(
            () => mockUserRepository.getById(any()),
          ).thenAnswer((_) async => right(user));
          when(
            () => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
          ).thenAnswer((_) async => right(<Session>[]));
          when(
            () => mockSessionLocalDataSource.listSessions(
              any(),
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
          ).thenAnswer((_) async => <Session>[]);
          when(
            () => mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockProtocolRepository.getById(any()),
          ).thenAnswer((_) async => right(ProtocolFactory.reconstitute()));

          final viewModel = createViewModel();
          addTearDown(viewModel.dispose);
          viewModel.state.value = viewModel.state.value.copyWith(user: user);

          // Act
          final result = await viewModel.handleUseFreeTier();

          // Assert - returns true (success)
          expect(result, isTrue);

          // Assert - does NOT write subscription status to DB
          // (webhook is the only DB writer for subscription state)
          verifyNever(() => mockUserRepository.save(any()));

          expect(viewModel.state.value.showDeactivationModal, isFalse);

          // Assert - refresh was called (getById invoked)
          verify(() => mockUserRepository.getById(any())).called(1);
        },
      );

      test('with 3 protocols - triggers deactivation modal', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
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
            onboardingCompleted: true,
          );

          when(
            () => mockAuthService.authState,
          ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
          when(
            () => mockUserRepository.getById(any()),
          ).thenAnswer((_) async => right(user));
          when(
            () => mockSessionRepository.list(
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
          ).thenAnswer((_) async => right(<Session>[]));
          when(
            () => mockSessionLocalDataSource.listSessions(
              any(),
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
          ).thenAnswer((_) async => <Session>[]);
          when(
            () => mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
          ).thenAnswer((_) async {});

          final viewModel = createViewModel();
          addTearDown(viewModel.dispose);

          // Act
          await viewModel.init();

          // Assert - without RC snapshot, effective status is DB status (trial)
          // Modal does not trigger because there's no detected transition
          expect(viewModel.state.value.showTrialExpiredModal, isFalse);
        },
      );

      test('triggers for premium expiration (expired status)', () async {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        );

        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => right(user));
        when(
          () => mockSessionRepository.list(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(
          () => mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
        ).thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - modal shows with paid-lapse messaging (not trial messaging)
        expect(viewModel.state.value.showTrialExpiredModal, isTrue);
        expect(viewModel.state.value.isTrialExpiration, isFalse);
      });

      test('does NOT trigger for active trial', () async {
        // Arrange - user with trial status
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          onboardingCompleted: true,
        );

        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => right(user));
        when(
          () => mockSessionRepository.list(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(
          () => mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
        ).thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert
        expect(viewModel.state.value.showTrialExpiredModal, isFalse);
      });

      test('does NOT trigger for free user', () async {
        // Arrange - user who chose free tier (status=free).
        // Modal should NOT trigger for free users.
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: true,
        );

        when(
          () => mockAuthService.authState,
        ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => right(user));
        when(
          () => mockSessionRepository.list(
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => right(<Session>[]));
        when(
          () => mockSessionLocalDataSource.listSessions(
            any(),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => <Session>[]);
        when(
          () => mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
        ).thenAnswer((_) async {});

        final viewModel = createViewModel();
        addTearDown(viewModel.dispose);

        // Act
        await viewModel.init();

        // Assert - modal should NOT trigger for free users
        expect(viewModel.state.value.showTrialExpiredModal, isFalse);
      });
    });

    group(
      'regression: mismatched snapshot does not influence effective status',
      () {
        test(
          'mismatchedSnapshot_effectiveStatusUsesDbFallback',
          () async {
            // Regression guard: After removing _scopedSnapshot from HomeViewModel,
            // ensure that a mismatched entitlement snapshot (belonging to a
            // different user) does NOT influence the effective status.
            // Safety relies on SubscriptionStatusResolver.resolveEffectiveStatus
            // checking snapshot.isForUser(user.id) internally.
            final user = UserFactory.create(
              id: 'user-a',
              subscriptionStatus: SubscriptionStatus.free,
              onboardingCompleted: true,
            );

            // Set up a snapshot for a DIFFERENT user with premium status
            final mismatchedSnapshot =
                EntitlementSnapshotFactory.activePaidMonthly(
                  userId: 'user-b',
                );
            when(
              () => mockRevenueCatService.entitlementSnapshot,
            ).thenReturn(
              ValueNotifier<EntitlementSnapshot?>(mismatchedSnapshot),
            );

            when(
              () => mockAuthService.authState,
            ).thenReturn(ValueNotifier(AuthenticatedOnline(user)));
            when(
              () => mockUserRepository.getById(any()),
            ).thenAnswer((_) async => right(user));
            when(
              () => mockSessionRepository.list(
                from: any(named: 'from'),
                to: any(named: 'to'),
              ),
            ).thenAnswer((_) async => right(<Session>[]));
            when(
              () => mockSessionLocalDataSource.listSessions(
                any(),
                from: any(named: 'from'),
                to: any(named: 'to'),
              ),
            ).thenAnswer((_) async => <Session>[]);
            when(
              () =>
                  mockSessionLocalDataSource.upsertSyncedSessions(any(), any()),
            ).thenAnswer((_) async {});

            final viewModel = createViewModel();
            addTearDown(viewModel.dispose);

            // Act - isTrialOrPremiumExpired uses the raw snapshot
            final result = viewModel.isTrialOrPremiumExpired(user);

            // Assert - should use DB status (free), not the mismatched
            // snapshot's premiumMonthly. Free status IS considered expired
            // for paywall purposes, so result is true.
            expect(result, isTrue);

            // Double-check: if it incorrectly used the mismatched snapshot,
            // it would resolve to premiumMonthly and return false.
            // The fact it returns true confirms DB fallback is in effect.
          },
        );

        test(
          'mismatchedSnapshot_premiumUserNotDowngraded',
          () async {
            // Regression guard: A premium user should NOT be downgraded
            // because of a mismatched expired snapshot from another user.
            final user = UserFactory.create(
              id: 'user-a',
              subscriptionStatus: SubscriptionStatus.premiumMonthly,
              onboardingCompleted: true,
            );

            // Set up an expired snapshot for a DIFFERENT user
            final mismatchedSnapshot = EntitlementSnapshotFactory.expiredTrial(
              userId: 'user-b',
            );
            when(
              () => mockRevenueCatService.entitlementSnapshot,
            ).thenReturn(
              ValueNotifier<EntitlementSnapshot?>(mismatchedSnapshot),
            );

            final viewModel = createViewModel();
            addTearDown(viewModel.dispose);

            // Act
            final result = viewModel.isTrialOrPremiumExpired(user);

            // Assert - should use DB status (premiumMonthly), not the
            // mismatched snapshot's expired state. Premium = not expired.
            expect(result, isFalse);
          },
        );
      },
    );

    group('isTrialOrPremiumExpired', () {
      // Note: isTrialOrPremiumExpired() is synchronous and checks
      // effective status (expired/free).

      test('returns false for trial status', () {
        // Arrange - when RC is unavailable, effective status is the DB status.
        // For trial status, the method returns false since it only checks
        // for expired/free states.
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
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
