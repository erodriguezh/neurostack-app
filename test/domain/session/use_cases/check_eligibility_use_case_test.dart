import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart';

import '../../../constants/test_constants.dart';
import '../../../factories/user_factory.dart';
import '../../../factories/value_objects/stack_factory.dart';
import '../../../matchers/either_matchers.dart';
import '../../../mocks/mock_services.dart';

void main() {
  late CheckEligibilityUseCase useCase;
  late MockUserRepository mockUserRepository;
  late CheckEligibilityParams validParams;

  setUp(() {
    mockUserRepository = MockUserRepository();
    useCase = CheckEligibilityUseCase(userRepository: mockUserRepository);

    validParams = CheckEligibilityParams(
      userId: TestConstants.user.id,
      protocolId: TestConstants.session.protocolId,
    );
  });

  group('CheckEligibilityUseCase', () {
    group('execute', () {
      test('whenUserNotFound_propagatesFailure', () async {
        // Arrange
        const userNotFoundFailure = DomainFailure(
          code: 'User.NotFound',
          message: 'User not found',
        );
        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => left(userNotFoundFailure));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(userNotFoundFailure));
      });

      test(
        'whenOnboardingNotCompleted_returnsOnboardingNotCompleted',
        () async {
          // Arrange
          final userWithoutOnboarding = UserFactory.create(
            onboardingCompleted: false,
            stack: StackFactory.withProtocol(TestConstants.session.protocolId),
            subscriptionStatus: SubscriptionStatus.trial,
          );

          when(
            () => mockUserRepository.getById(any()),
          ).thenAnswer((_) async => right(userWithoutOnboarding));

          // Act
          final result = await useCase.execute(validParams);

          // Assert
          expect(result, isLeftWith(UserFailures.onboardingNotCompleted));
        },
      );

      test('whenProtocolNotInStack_returnsProtocolNotInStack', () async {
        // Arrange
        final userWithoutProtocol = UserFactory.create(
          onboardingCompleted: true,
          stack: Stack.empty(),
          subscriptionStatus: SubscriptionStatus.trial,
        );

        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => right(userWithoutProtocol));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(UserFailures.protocolNotInStack));
      });

      // Trial expiration gating is now handled by SubscriptionStatusResolver,
      // not the User entity. An expired trial user with >2 protocols is still
      // treated as trial (unlimited) by the entity.
      test(
        'whenExpiredTrialOverLimit_succeedsBecauseEntityNoLongerGatesOnTrialExpiry',
        () async {
          // Arrange
          final expiredTrialUser = UserFactory.createExpiredTrialOverLimit();

          when(
            () => mockUserRepository.getById(any()),
          ).thenAnswer((_) async => right(expiredTrialUser));

          // Derive protocol from user's stack to avoid coupling to factory internals
          final protocolIdInStack = expiredTrialUser.activeProtocolIds.first;
          final paramsWithStackProtocol = CheckEligibilityParams(
            userId: validParams.userId,
            protocolId: protocolIdInStack,
          );

          // Act
          final result = await useCase.execute(paramsWithStackProtocol);

          // Assert - succeeds; trial status has no protocol limit
          expect(result, isRight<Unit>());
        },
      );

      test('whenEligible_returnsUnit', () async {
        // Arrange
        final validUser = UserFactory.create(
          onboardingCompleted: true,
          stack: StackFactory.withProtocol(TestConstants.session.protocolId),
          subscriptionStatus: SubscriptionStatus.trial,
        );

        when(
          () => mockUserRepository.getById(any()),
        ).thenAnswer((_) async => right(validUser));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isRight<Unit>());
      });
    });
  });
}
