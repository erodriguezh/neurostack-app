import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/entities/session_draft.dart';
import 'package:neurostack/features/session/domain/failures/session_failures.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/session/domain/use_cases/log_session_use_case.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart';

import '../../../constants/test_constants.dart';
import '../../../factories/session_factory.dart';
import '../../../factories/user_factory.dart';
import '../../../factories/value_objects/stack_factory.dart';
import '../../../factories/value_objects/trial_period_factory.dart';
import '../../../matchers/either_matchers.dart';

// Mocks
class MockUserRepository extends Mock implements UserRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late LogSessionUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockSessionRepository mockSessionRepository;

  // Valid test data
  late LogSessionParams validParams;

  setUpAll(() {
    // Register fallback values for mocktail
    final draft = SessionDraft.create(
      protocolId: TestConstants.session.protocolId,
      completedAt: TestConstants.session.validCompletedAt,
      currentTime: TestConstants.session.currentTime,
    ).getOrElse(
      (l) => throw Exception('Factory produced invalid SessionDraft: $l'),
    );
    registerFallbackValue(draft);
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockSessionRepository = MockSessionRepository();
    useCase = LogSessionUseCase(
      userRepository: mockUserRepository,
      sessionRepository: mockSessionRepository,
    );

    // Setup valid params for most tests
    validParams = LogSessionParams(
      userId: TestConstants.user.id,
      protocolId: TestConstants.session.protocolId,
      completedAt: TestConstants.session.validCompletedAt,
      currentTime: TestConstants.session.currentTime,
    );
  });

  group('LogSessionUseCase', () {
    group('execute', () {
      test('whenAllValid_returnsSessionAndCreates', () async {
        // Arrange
        final validUser = UserFactory.create(
          onboardingCompleted: true,
          stack: StackFactory.withProtocol(TestConstants.session.protocolId),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(validUser));
        final createdSession = SessionFactory.reconstitute();
        when(() => mockSessionRepository.create(any()))
            .thenAnswer((_) async => right(createdSession));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isRight<Session>());
        result.fold(
          (_) => fail('Expected Right'),
          (session) {
            // IDs are generated server-side; assert on stable domain fields.
            expect(session.protocolId, createdSession.protocolId);
            expect(session.completedAt, createdSession.completedAt);
          },
        );
        verify(() => mockSessionRepository.create(any())).called(1);
      });

      test('whenUserNotFound_propagatesFailure', () async {
        // Arrange
        const userNotFoundFailure = DomainFailure(
          code: 'User.NotFound',
          message: 'User not found',
        );
        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => left(userNotFoundFailure));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(userNotFoundFailure));
        verifyNever(() => mockSessionRepository.create(any()));
      });

      test('whenOnboardingNotCompleted_returnsOnboardingNotCompleted',
          () async {
        // Arrange
        final userWithoutOnboarding = UserFactory.create(
          onboardingCompleted: false,
          stack: StackFactory.withProtocol(TestConstants.session.protocolId),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(userWithoutOnboarding));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(UserFailures.onboardingNotCompleted));
        verifyNever(() => mockSessionRepository.create(any()));
      });

      test('whenProtocolNotInStack_returnsProtocolNotInStack', () async {
        // Arrange
        final userWithoutProtocol = UserFactory.create(
          onboardingCompleted: true,
          stack: Stack.empty(),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(userWithoutProtocol));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(UserFailures.protocolNotInStack));
        verifyNever(() => mockSessionRepository.create(any()));
      });

      test('whenExpiredTrialOverLimit_returnsTooManyActiveProtocols',
          () async {
        // Arrange
        final expiredTrialUser = UserFactory.createExpiredTrialOverLimit();

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(expiredTrialUser));

        // Use protocol from the expired user's stack
        final paramsWithStackProtocol = LogSessionParams(
          userId: validParams.userId,
          protocolId: StackFactory.protocol1, // Protocol that exists in stack
          completedAt: validParams.completedAt,
          currentTime: validParams.currentTime,
        );

        // Act
        final result = await useCase.execute(paramsWithStackProtocol);

        // Assert
        expect(result, isLeftWith(UserFailures.tooManyActiveProtocols));
        verifyNever(() => mockSessionRepository.create(any()));
      });

      test('whenTimestampInFuture_returnsTimestampInFuture', () async {
        // Arrange
        final validUser = UserFactory.create(
          onboardingCompleted: true,
          stack: StackFactory.withProtocol(TestConstants.session.protocolId),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(validUser));

        final futureParams = LogSessionParams(
          userId: validParams.userId,
          protocolId: validParams.protocolId,
          completedAt: TestConstants.session.futureCompletedAt,
          currentTime: TestConstants.session.currentTime,
        );

        // Act
        final result = await useCase.execute(futureParams);

        // Assert
        expect(result, isLeftWith(SessionFailures.timestampInFuture));
        verifyNever(() => mockSessionRepository.create(any()));
      });

      test('whenCreateFails_propagatesFailure', () async {
        // Arrange
        final validUser = UserFactory.create(
          onboardingCompleted: true,
          stack: StackFactory.withProtocol(TestConstants.session.protocolId),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        const saveFailure = DomainFailure(
          code: 'Session.SaveFailed',
          message: 'Failed to save session',
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(validUser));
        when(() => mockSessionRepository.create(any()))
            .thenAnswer((_) async => left(saveFailure));

        // Act
        final result = await useCase.execute(validParams);

        // Assert
        expect(result, isLeftWith(saveFailure));
        verify(() => mockSessionRepository.create(any())).called(1);
      });

      test('whenValidationFails_doesNotCallCreate', () async {
        // Arrange - user without protocol in stack
        final userWithoutProtocol = UserFactory.create(
          onboardingCompleted: true,
          stack: Stack.empty(),
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriodFactory.create(),
        );

        when(() => mockUserRepository.getById(any()))
            .thenAnswer((_) async => right(userWithoutProtocol));

        // Act
        await useCase.execute(validParams);

        // Assert
        verifyNever(() => mockSessionRepository.create(any()));
      });
    });
  });
}
