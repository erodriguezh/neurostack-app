import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/events/user_events.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import '../../factories/factories.dart';
import '../../matchers/either_matchers.dart';

void main() {
  group('User', () {
    group('create', () {
      // INV-P6: New users MUST start with free status
      test('create_always_setsFreeStatusAndRaisesUserCreatedEvent', () {
        // Act
        final user = UserFactory.createDefault();

        // Assert
        expect(user.subscriptionStatus, SubscriptionStatus.free);
        expect(user.trialPeriod, isNull);
        expect(user.hasDomainEvents, true);
        expect(user.domainEvents.length, 1);
        expect(user.domainEvents[0], isA<UserCreatedEvent>());
      });
    });

    group('activateProtocol', () {
      test('activateProtocol_whenUnderLimit_succeeds', () {
        // Arrange
        final user = UserFactory.createFreeUnderLimit();

        // Act
        final result = user.activateProtocol('protocol-2');

        // Assert
        expect(result, isRight<User>());
        final updated = result.getOrElse(
          (l) => throw Exception('Failed to activate: $l'),
        );
        expect(updated.activeProtocolIds.contains('protocol-2'), true);
      });

      test(
        'activateProtocol_whenAlreadyActive_returnsProtocolAlreadyActive',
        () {
          // Arrange
          final user = UserFactory.create(
            subscriptionStatus: SubscriptionStatus.free,
            stack: StackFactory.fromIds(['protocol-1']),
            onboardingCompleted: true,
          );

          // Act
          final result = user.activateProtocol('protocol-1');

          // Assert
          expect(result, isLeftWith(UserFailures.protocolAlreadyActive));
        },
      );

      // INV-U1, INV-M5: Free tier limit boundary
      test('activateProtocol_whenFreeAtLimit_returnsProtocolLimitReached', () {
        // Arrange - exactly at limit (1 protocol, limit is 2)
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.fromIds(['protocol-1']),
          onboardingCompleted: true,
        );

        // Act - add second (should succeed)
        final result1 = user.activateProtocol('protocol-2');

        // Assert - first activation succeeds
        expect(result1, isRight<User>());

        final userAtLimit = result1.getOrElse(
          (l) => throw Exception('Failed to activate: $l'),
        );

        // Act - add third (should fail at boundary)
        final result2 = userAtLimit.activateProtocol('protocol-3');

        // Assert - second activation fails with specific error
        expect(result2, isLeftWith(UserFailures.protocolLimitReached));
      });

      // INV-U2: Trial has no limit
      test('activateProtocol_whenOnTrial_allowsUnlimitedProtocols', () {
        // Arrange - active trial with 5 protocols already
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
          stack: StackFactory.fromIds(['p-1', 'p-2', 'p-3', 'p-4', 'p-5']),
          onboardingCompleted: true,
        );

        // Act - add 6th protocol
        final result = user.activateProtocol('p-6');

        // Assert - should succeed (no limit on trial)
        expect(result, isRight<User>());
      });

      // Trial expiration gating is now handled by SubscriptionStatusResolver,
      // not the User entity. A user with subscriptionStatus == trial is treated
      // as trial regardless of trialPeriod expiry.
      test(
        'activateProtocol_whenTrialExpiredButStatusStillTrial_allowsUnlimited',
        () {
          // Arrange - expired trial with 2 protocols
          final user = UserFactory.create(
            subscriptionStatus: SubscriptionStatus.trial,
            trialPeriod: TrialPeriodFactory.expired(),
            stack: StackFactory.atFreeCapacity(),
            onboardingCompleted: true,
          );

          // Act - try to add 3rd protocol
          final result = user.activateProtocol('protocol-3');

          // Assert - succeeds because entity no longer checks trialPeriod
          expect(result, isRight<User>());
        },
      );

      test('activateProtocol_whenPremiumMonthly_allowsUnlimitedProtocols', () {
        // Arrange - premium with 10 protocols
        final user = UserFactory.createPremiumMonthly(
          stack: StackFactory.fromIds(
            List.generate(10, (i) => 'protocol-$i'),
          ),
        );

        // Act - add 11th protocol
        final result = user.activateProtocol('protocol-10');

        // Assert - should succeed (no limit on premium)
        expect(result, isRight<User>());
      });

      test('activateProtocol_whenPremiumAnnual_allowsUnlimitedProtocols', () {
        // Arrange - premium annual with 10 protocols
        final user = UserFactory.createPremiumAnnual(
          stack: StackFactory.fromIds(
            List.generate(10, (i) => 'protocol-$i'),
          ),
        );

        // Act - add 11th protocol
        final result = user.activateProtocol('protocol-10');

        // Assert - should succeed (no limit on premium)
        expect(result, isRight<User>());
      });
    });

    group('deactivateProtocol', () {
      test('deactivateProtocol_whenActive_succeeds', () {
        // Arrange
        final user = UserFactory.create(
          stack: StackFactory.fromIds(['protocol-1', 'protocol-2']),
          onboardingCompleted: true,
        );

        // Act
        final result = user.deactivateProtocol('protocol-1');

        // Assert
        expect(result, isRight<User>());
        final updated = result.getOrElse(
          (l) => throw Exception('Failed to deactivate: $l'),
        );
        expect(updated.activeProtocolIds.contains('protocol-1'), false);
        expect(updated.activeProtocolCount, 1);
      });

      test('deactivateProtocol_whenNotActive_returnsProtocolNotActive', () {
        // Arrange
        final user = UserFactory.create(
          stack: StackFactory.fromIds(['protocol-1']),
          onboardingCompleted: true,
        );

        // Act
        final result = user.deactivateProtocol('protocol-2');

        // Assert
        expect(result, isLeftWith(UserFailures.protocolNotActive));
      });
    });

    group('canLogSession', () {
      // INV-U4: Onboarding required
      test(
        'canLogSession_whenOnboardingNotCompleted_returnsOnboardingNotCompleted',
        () {
          // Arrange
          final user = UserFactory.create(
            stack: StackFactory.fromIds(['protocol-1']),
            onboardingCompleted: false,
          );

          // Act
          final result = user.canLogSession('protocol-1');

          // Assert
          expect(result, isLeftWith(UserFailures.onboardingNotCompleted));
        },
      );

      test(
        'canLogSession_whenProtocolNotInStack_returnsProtocolNotInStack',
        () {
          // Arrange
          final user = UserFactory.create(
            stack: StackFactory.fromIds(['protocol-1']),
            onboardingCompleted: true,
          );

          // Act
          final result = user.canLogSession('protocol-2');

          // Assert
          expect(result, isLeftWith(UserFailures.protocolNotInStack));
        },
      );

      // Trial expiration gating is now handled by SubscriptionStatusResolver.
      // The User entity treats trial status as unlimited regardless of
      // trialPeriod expiry.
      test(
        'canLogSession_whenExpiredTrialOverLimit_succeedsBecauseEntityNoLongerGates',
        () {
          // Arrange - expired trial with 3 protocols
          final user = UserFactory.createExpiredTrialOverLimit();

          // Act - try to log session for any protocol
          final result = user.canLogSession(StackFactory.protocol1);

          // Assert - succeeds; entity no longer checks trialPeriod for gating
          expect(result, isRight<Unit>());
        },
      );

      test('canLogSession_whenExpiredTrialAtLimit_succeeds', () {
        // Arrange - expired trial with exactly 2 protocols
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
          stack: StackFactory.atFreeCapacity(),
          onboardingCompleted: true,
        );

        // Act
        final result = user.canLogSession('protocol-1');

        // Assert - should succeed (trial status means unlimited)
        expect(result, isRight<Unit>());
      });

      test('canLogSession_whenAllConditionsMet_returnsUnit', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.fromIds(['protocol-1']),
          onboardingCompleted: true,
        );

        // Act
        final result = user.canLogSession('protocol-1');

        // Assert
        expect(result, isRight<Unit>());
      });
    });

    group('completeOnboarding', () {
      test('completeOnboarding_whenNotCompleted_succeeds', () {
        // Arrange
        final user = UserFactory.create(onboardingCompleted: false);

        // Act
        final result = user.completeOnboarding();

        // Assert
        expect(result, isRight<User>());
        final updated = result.getOrElse(
          (l) => throw Exception('Failed to complete onboarding: $l'),
        );
        expect(updated.onboardingCompleted, true);
      });

      test(
        'completeOnboarding_whenAlreadyCompleted_returnsAlreadyOnboarded',
        () {
          // Arrange
          final user = UserFactory.create(onboardingCompleted: true);

          // Act
          final result = user.completeOnboarding();

          // Assert
          expect(result, isLeftWith(UserFailures.alreadyOnboarded));
        },
      );
    });

    group('upgradeToPremium', () {
      test('upgradeToPremium_withPremiumMonthly_succeeds', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );

        // Act
        final result = user.upgradeToPremium(SubscriptionStatus.premiumMonthly);

        // Assert
        expect(result, isRight<User>());
        final upgraded = result.getOrElse(
          (l) => throw Exception('Failed to upgrade: $l'),
        );
        expect(upgraded.subscriptionStatus, SubscriptionStatus.premiumMonthly);
      });

      test('upgradeToPremium_withPremiumAnnual_succeeds', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
        );

        // Act
        final result = user.upgradeToPremium(SubscriptionStatus.premiumAnnual);

        // Assert
        expect(result, isRight<User>());
        final upgraded = result.getOrElse(
          (l) => throw Exception('Failed to upgrade: $l'),
        );
        expect(upgraded.subscriptionStatus, SubscriptionStatus.premiumAnnual);
      });

      test(
        'upgradeToPremium_withNonPremiumStatus_returnsInvalidSubscriptionUpgrade',
        () {
          // Arrange
          final user = UserFactory.create(
            subscriptionStatus: SubscriptionStatus.free,
          );

          // Act
          final result = user.upgradeToPremium(SubscriptionStatus.trial);

          // Assert
          expect(result, isLeftWith(UserFailures.invalidSubscriptionUpgrade));
        },
      );
    });

    group('getEffectiveStatus', () {
      test('getEffectiveStatus_whenTrialActive_returnsTrial', () {
        // Arrange
        final user = UserFactory.createActiveTrial();

        // Act
        final status = user.getEffectiveStatus();

        // Assert
        expect(status, SubscriptionStatus.trial);
      });

      // getEffectiveStatus no longer checks trialPeriod; it returns
      // subscriptionStatus directly. Trial expiration gating is now handled
      // by SubscriptionStatusResolver.
      test('getEffectiveStatus_whenTrialExpired_returnsTrialUnchanged', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.expired(),
        );

        // Act
        final status = user.getEffectiveStatus();

        // Assert - returns stored status, not free
        expect(status, SubscriptionStatus.trial);
      });

      test('getEffectiveStatus_whenPremiumMonthly_returnsPremiumMonthly', () {
        // Arrange
        final user = UserFactory.createPremiumMonthly();

        // Act
        final status = user.getEffectiveStatus();

        // Assert
        expect(status, SubscriptionStatus.premiumMonthly);
      });

      test('getEffectiveStatus_whenFree_returnsFree', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          trialPeriod: null,
        );

        // Act
        final status = user.getEffectiveStatus();

        // Assert
        expect(status, SubscriptionStatus.free);
      });
    });

    group('domain events', () {
      test('activateProtocol_whenSuccessful_raisesProtocolActivatedEvent', () {
        // Arrange
        final user = UserFactory.create(
          subscriptionStatus: SubscriptionStatus.free,
          stack: StackFactory.empty(),
          onboardingCompleted: true,
        );

        // Act
        final result = user.activateProtocol('protocol-123');

        // Assert
        final updated = result.getOrElse(
          (l) => throw Exception('Failed to activate: $l'),
        );
        expect(updated.hasDomainEvents, true);
        final event = updated.domainEvents
            .whereType<ProtocolActivatedEvent>()
            .first;
        expect(event.userId, user.id);
        expect(event.protocolId, 'protocol-123');
      });

      test(
        'deactivateProtocol_whenSuccessful_raisesProtocolDeactivatedEvent',
        () {
          // Arrange
          final user = UserFactory.create(
            stack: StackFactory.fromIds(['protocol-123']),
            onboardingCompleted: true,
          );

          // Act
          final result = user.deactivateProtocol('protocol-123');

          // Assert
          final updated = result.getOrElse(
            (l) => throw Exception('Failed to deactivate: $l'),
          );
          expect(updated.hasDomainEvents, true);
          final event = updated.domainEvents
              .whereType<ProtocolDeactivatedEvent>()
              .first;
          expect(event.userId, user.id);
          expect(event.protocolId, 'protocol-123');
        },
      );

      test(
        'completeOnboarding_whenSuccessful_raisesOnboardingCompletedEvent',
        () {
          // Arrange
          final user = UserFactory.create(onboardingCompleted: false);

          // Act
          final result = user.completeOnboarding();

          // Assert
          final updated = result.getOrElse(
            (l) => throw Exception('Failed to complete onboarding: $l'),
          );
          expect(updated.hasDomainEvents, true);
          final event = updated.domainEvents
              .whereType<OnboardingCompletedEvent>()
              .first;
          expect(event.userId, user.id);
        },
      );

      test(
        'upgradeToPremium_whenSuccessful_raisesSubscriptionUpgradedEvent',
        () {
          // Arrange
          final user = UserFactory.create(
            subscriptionStatus: SubscriptionStatus.free,
          );

          // Act
          final result = user.upgradeToPremium(
            SubscriptionStatus.premiumMonthly,
          );

          // Assert
          final upgraded = result.getOrElse(
            (l) => throw Exception('Failed to upgrade: $l'),
          );
          expect(upgraded.hasDomainEvents, true);
          final event = upgraded.domainEvents
              .whereType<SubscriptionUpgradedEvent>()
              .first;
          expect(event.userId, user.id);
          expect(event.newStatus, SubscriptionStatus.premiumMonthly);
        },
      );
    });

    group('activeProtocolIds', () {
      test('activeProtocolIds_returnsImmutableList', () {
        // Arrange
        final user = UserFactory.create(
          stack: StackFactory.fromIds(['protocol-1']),
        );

        // Act
        final ids = user.activeProtocolIds;

        // Assert - attempting to modify should not affect user
        expect(ids, ['protocol-1']);
        expect(ids, isA<List<String>>());
      });
    });
  });
}
