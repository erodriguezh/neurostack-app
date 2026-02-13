import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/data/dtos/user_dto.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/value_objects/stack.dart';

import '../../../../constants/test_constants.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('UserDto', () {
    group('toJson', () {
      test('toJson_omitsLegacyTrialFields', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
          protocolIds: const [],
          onboardingCompleted: false,
          createdAt: TestConstants.user.createdAt.toIso8601String(),
        );

        // Act
        final json = dto.toJson();

        // Assert - legacy trial fields must NOT appear
        expect(json.containsKey('trial_ends_at'), isFalse);
        expect(json.containsKey('trial_period'), isFalse);
      });
    });

    group('fromJson', () {
      test('fromJson_parsesCorrectly', () {
        // Arrange
        final json = <String, dynamic>{
          'id': TestConstants.user.id,
          'subscription_status': 'trial',
          'protocol_ids': <dynamic>[],
          'onboarding_completed': false,
          'created_at': TestConstants.user.createdAt.toIso8601String(),
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.id, TestConstants.user.id);
        expect(dto.subscriptionStatus, 'trial');
      });

      test('fromJson_ignoresLegacyTrialFields', () {
        // Arrange - JSON that still has legacy trial fields
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

        // Act - should not throw even though legacy fields are present
        final dto = UserDto.fromJson(json);

        // Assert - parses normally, legacy fields are simply ignored
        expect(dto.id, TestConstants.user.id);
      });
    });

    group('toDomain', () {
      test('toDomain_whenValid_returnsUser', () {
        // Arrange
        final dto = UserDto(
          id: TestConstants.user.id,
          subscriptionStatus: 'trial',
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
        final original = User.reconstitute(
          id: TestConstants.user.id,
          subscriptionStatus: SubscriptionStatus.trial,
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
            expect(restored.activeProtocolIds, original.activeProtocolIds);
            expect(restored.onboardingCompleted, original.onboardingCompleted);
            expect(restored.createdAt, original.createdAt);
          },
        );
      });
    });
  });
}
