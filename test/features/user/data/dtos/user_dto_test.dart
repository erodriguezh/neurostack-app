import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/data/dtos/trial_period_dto.dart';
import 'package:neurostack/features/user/data/dtos/user_dto.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart';
import 'package:neurostack/features/user/domain/value_objects/trial_period.dart';

import '../../../../constants/test_constants.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('UserDto', () {
    group('toJson does not include trial_ends_at', () {
      test('toJson_withTrialPeriod_omitsTrialEndsAt', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: const TrialPeriodDto(
            startDate: '2025-01-01T10:00:00.000',
            endDate: '2025-01-08T10:00:00.000',
          ),
          protocolIds: const [],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final json = dto.toJson();

        // Assert - trial_ends_at must NOT appear in serialized output
        expect(json.containsKey('trial_ends_at'), isFalse);
      });

      test('toJson_withoutTrialPeriod_omitsTrialEndsAt', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'free',
          trialPeriod: null,
          protocolIds: const [],
          onboardingCompleted: true,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('trial_ends_at'), isFalse);
      });
    });

    group('fromJson', () {
      test('fromJson_withTrialPeriod_parsesCorrectly', () {
        // Arrange
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'trial',
          'trial_period': {
            'start_date': '2025-01-01T10:00:00.000',
            'end_date': '2025-01-08T10:00:00.000',
          },
          'protocol_ids': <dynamic>[],
          'onboarding_completed': false,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.trialPeriod, isNotNull);
        expect(dto.trialPeriod!.startDate, '2025-01-01T10:00:00.000');
        expect(dto.trialPeriod!.endDate, '2025-01-08T10:00:00.000');
      });

      test('fromJson_withoutTrialPeriod_leavesFieldNull', () {
        // Arrange - JSON without trial_period key
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'free',
          'protocol_ids': <dynamic>[],
          'onboarding_completed': true,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.trialPeriod, isNull);
      });

      test('fromJson_ignoresLegacyTrialEndsAtColumn', () {
        // Arrange - JSON that still has trial_ends_at from DB (before column drop)
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'trial',
          'trial_period': {
            'start_date': '2025-01-01T10:00:00.000',
            'end_date': '2025-01-08T10:00:00.000',
          },
          'trial_ends_at': '2025-01-08T10:00:00.000',
          'protocol_ids': <dynamic>[],
          'onboarding_completed': false,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act - should not throw even though trial_ends_at is in the JSON
        final dto = UserDto.fromJson(json);

        // Assert - parses normally, trial_ends_at is simply ignored
        expect(dto.trialPeriod, isNotNull);
      });
    });

    group('toDomain', () {
      test('toDomain_whenValid_returnsUser', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: const TrialPeriodDto(
            startDate: '2025-01-01T10:00:00.000',
            endDate: '2025-01-08T10:00:00.000',
          ),
          protocolIds: const ['1', '2'],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<User>());
        result.match(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.id, TestConstants.user.id);
            expect(user.subscriptionStatus, SubscriptionStatus.trial);
            expect(user.trialPeriod, isNotNull);
            expect(user.activeProtocolIds, ['1', '2']);
            expect(user.onboardingCompleted, false);
          },
        );
      });

      test('toDomain_withTrialStatusButNoTrialPeriod_fallsBackToCreatedAt',
          () {
        // Arrange - DTO with trial status but no trialPeriod JSONB
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: null,
          protocolIds: [],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final result = dto.toDomain();

        // Assert - Should use createdAt for trial start
        expect(result, isRight<User>());
        result.match(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.trialPeriod, isNotNull);
            expect(user.trialPeriod!.startDate, TestConstants.user.createdAt);
            final expectedEnd = TestConstants.user.createdAt
                .add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(user.trialPeriod!.endDate, expectedEnd);
          },
        );
      });

      test('toDomain_withInvalidSubscriptionStatus_returnsFailure', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'invalidStatus',
          trialPeriod: null,
          protocolIds: [],
          onboardingCompleted: true,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<User>('Dto.InvalidSubscriptionStatus'));
      });

      test('toDomain_withInvalidCreatedAt_returnsParseError', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'free',
          trialPeriod: null,
          protocolIds: [],
          onboardingCompleted: true,
          createdAt: 'not-a-date',
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isLeftWithCode<User>('Dto.ParseError'));
      });
    });

    group('fromDomain roundtrip', () {
      test('fromDomain_roundtrip_preservesAllFields', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);
        final endDate = DateTime(2025, 1, 8, 10, 0, 0);
        final original = User.reconstitute(
          id: TestConstants.user.id,
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: TrialPeriod.fromDates(
            startDate: startDate,
            endDate: endDate,
          ),
          stack: Stack.fromIds(['1', '2']),
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt,
        );

        // Act
        final dto = UserDto.fromDomain(original);
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<User>());
        result.match(
          (_) => fail('Expected Right'),
          (restored) {
            expect(restored.id, original.id);
            expect(restored.subscriptionStatus, original.subscriptionStatus);
            expect(restored.trialPeriod?.startDate,
                original.trialPeriod?.startDate);
            expect(
                restored.trialPeriod?.endDate, original.trialPeriod?.endDate);
            expect(restored.activeProtocolIds, original.activeProtocolIds);
            expect(restored.onboardingCompleted, original.onboardingCompleted);
            expect(restored.createdAt, original.createdAt);
          },
        );
      });
    });
  });
}
