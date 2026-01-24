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
    group('trialEndsAt serialization', () {
      test('fromDomain_withTrialPeriod_writesTrialEndsAt', () {
        // Arrange - User with trial period
        final startDate = DateTime(2025, 1, 1, 10, 0, 0);
        final endDate = DateTime(2025, 1, 8, 10, 0, 0);
        final trialPeriod = TrialPeriod.fromDates(
          startDate: startDate,
          endDate: endDate,
        );

        final user = User.reconstitute(
          id: TestConstants.user.id,
          subscriptionStatus: SubscriptionStatus.trial,
          trialPeriod: trialPeriod,
          stack: Stack.empty(),
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt,
        );

        // Act
        final dto = UserDto.fromDomain(user);

        // Assert - trialEndsAt should be written as denormalized field
        expect(dto.trialEndsAt, isNotNull);
        expect(dto.trialEndsAt, endDate);
      });

      test('fromDomain_withoutTrialPeriod_trialEndsAtIsNull', () {
        // Arrange - Free user without trial period
        final user = User.reconstitute(
          id: TestConstants.user.id,
          subscriptionStatus: SubscriptionStatus.free,
          trialPeriod: null,
          stack: Stack.empty(),
          onboardingCompleted: true,
          createdAt: TestConstants.user.createdAt,
        );

        // Act
        final dto = UserDto.fromDomain(user);

        // Assert
        expect(dto.trialEndsAt, isNull);
      });

      test('toJson_withTrialEndsAt_serializesField', () {
        // Arrange
        final endDate = DateTime(2025, 1, 8, 10, 0, 0);
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: const TrialPeriodDto(
            startDate: '2025-01-01T10:00:00.000',
            endDate: '2025-01-08T10:00:00.000',
          ),
          trialEndsAt: endDate,
          protocolIds: const [],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['trial_ends_at'], isNotNull);
        expect(json['trial_ends_at'], endDate.toIso8601String());
      });
    });

    group('toDomain ignores trialEndsAt', () {
      test('toDomain_usesTrialPeriodNotTrialEndsAt', () {
        // Arrange - DTO with trialPeriod and trialEndsAt that differ
        // This simulates a case where the denormalized field might be out of sync
        final trialPeriodEndDate = DateTime(2025, 1, 8, 10, 0, 0);
        final wrongTrialEndsAt = DateTime(2025, 2, 15, 10, 0, 0); // Different!

        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: TrialPeriodDto(
            startDate: '2025-01-01T10:00:00.000',
            endDate: trialPeriodEndDate.toIso8601String(),
          ),
          trialEndsAt: wrongTrialEndsAt, // This should be ignored
          protocolIds: [],
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
            // trialPeriod.endDate should come from trialPeriod JSONB, not trialEndsAt
            expect(user.trialPeriod, isNotNull);
            expect(user.trialPeriod!.endDate, trialPeriodEndDate);
            expect(user.trialPeriod!.endDate, isNot(equals(wrongTrialEndsAt)));
          },
        );
      });

      test('toDomain_withOnlyTrialEndsAt_fallsBackToCreatedAt', () {
        // Arrange - DTO with trial status but no trialPeriod JSONB
        // This tests backwards compatibility when only trialEndsAt exists
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          trialPeriod: null, // No trialPeriod JSONB
          trialEndsAt: DateTime(2025, 1, 8, 10, 0, 0), // Has trialEndsAt
          protocolIds: [],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final result = dto.toDomain();

        // Assert - Should use createdAt for trial start, not trialEndsAt
        expect(result, isRight<User>());
        result.match(
          (_) => fail('Expected Right'),
          (user) {
            expect(user.trialPeriod, isNotNull);
            // Trial period should be computed from createdAt
            expect(user.trialPeriod!.startDate, TestConstants.user.createdAt);
            final expectedEnd = TestConstants.user.createdAt
                .add(const Duration(days: TrialPeriod.trialDurationDays));
            expect(user.trialPeriod!.endDate, expectedEnd);
          },
        );
      });
    });

    group('fromJson', () {
      test('fromJson_withTrialEndsAt_parsesDenormalizedField', () {
        // Arrange
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

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.trialEndsAt, isNotNull);
        expect(dto.trialEndsAt, DateTime(2025, 1, 8, 10, 0, 0));
      });

      test('fromJson_withNullTrialEndsAt_leavesFieldNull', () {
        // Arrange
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'free',
          'trial_period': null,
          'trial_ends_at': null,
          'protocol_ids': <dynamic>[],
          'onboarding_completed': true,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.trialEndsAt, isNull);
      });

      test('fromJson_withoutTrialEndsAt_leavesFieldNull', () {
        // Arrange - JSON without trial_ends_at key at all
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
        expect(dto.trialEndsAt, isNull);
      });

      test('fromJson_withInvalidTrialEndsAtFormat_returnsNull', () {
        // Arrange - Invalid date format should be handled gracefully
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'trial',
          'trial_period': {
            'start_date': '2025-01-01T10:00:00.000',
            'end_date': '2025-01-08T10:00:00.000',
          },
          'trial_ends_at': 'not-a-date',
          'protocol_ids': <dynamic>[],
          'onboarding_completed': false,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert - _nullableDateTimeFromJson uses tryParse, returns null on failure
        expect(dto.trialEndsAt, isNull);
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
          trialEndsAt: DateTime(2025, 1, 8, 10, 0, 0),
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

      test('toDomain_withInvalidSubscriptionStatus_returnsFailure', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'invalidStatus',
          trialPeriod: null,
          trialEndsAt: null,
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
          trialEndsAt: null,
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
            expect(restored.trialPeriod?.startDate, original.trialPeriod?.startDate);
            expect(restored.trialPeriod?.endDate, original.trialPeriod?.endDate);
            expect(restored.activeProtocolIds, original.activeProtocolIds);
            expect(restored.onboardingCompleted, original.onboardingCompleted);
            expect(restored.createdAt, original.createdAt);
          },
        );
      });
    });
  });
}
