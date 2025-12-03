import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/value_objects/stack.dart';
import '../../domain/value_objects/trial_period.dart';
import 'trial_period_dto.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// DTO for [User] aggregate serialization.
///
/// Stores enum as string and dates as ISO 8601 for JSON compatibility.
/// Flattens [Stack] to `protocolIds` list since it's a simple wrapper.
/// Uses [User.reconstitute] to avoid raising domain events on load.
///
/// Supports:
/// - **INV-U1**: Free Tier users CANNOT activate more than 2 protocols
/// - **INV-U2**: Premium Trial users CAN activate unlimited protocols
/// - **INV-U3**: Trial MUST auto-activate on first app launch
/// - **INV-U4**: Users MUST complete onboarding before tracking Sessions
/// - **INV-M2**: Premium Trial MUST last exactly 7 days
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    required String id,
    required String subscriptionStatus,
    TrialPeriodDto? trialPeriod,
    required List<String> protocolIds,
    required bool onboardingCompleted,
    required String createdAt,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  /// Converts this DTO to the domain [User] aggregate.
  ///
  /// Uses [User.reconstitute] since data comes from persistence
  /// where invariants were already validated. Does not raise domain events.
  ///
  /// Returns [Left] with validation failure if:
  /// - SubscriptionStatus enum parsing fails
  /// - Trial period date parsing fails
  /// - CreatedAt date parsing fails
  Either<DomainFailure, User> toDomain() {
    try {
      // Parse subscription status enum
      final SubscriptionStatus domainStatus;
      try {
        domainStatus = SubscriptionStatus.values.byName(subscriptionStatus);
      } catch (_) {
        return left(
          DomainFailure(
            code: 'Dto.InvalidSubscriptionStatus',
            message: 'Invalid subscription status: $subscriptionStatus',
          ),
        );
      }

      // Parse trial period if present
      TrialPeriod? domainTrialPeriod;
      if (trialPeriod != null) {
        final trialResult = trialPeriod!.toDomain();
        if (trialResult.isLeft()) {
          return left(trialResult.getLeft().getOrElse(() => throw StateError('Unreachable')));
        }
        domainTrialPeriod = trialResult.getOrElse((l) => throw StateError('Unreachable'));
      }

      // Create stack from protocol IDs
      final domainStack = Stack.fromIds(protocolIds);

      // Parse date
      final createdAtDate = DateTime.parse(createdAt);

      // Reconstitute (not create) to avoid domain events
      return right(
        User.reconstitute(
          id: id,
          subscriptionStatus: domainStatus,
          trialPeriod: domainTrialPeriod,
          stack: domainStack,
          onboardingCompleted: onboardingCompleted,
          createdAt: createdAtDate,
        ),
      );
    } catch (e) {
      return left(
        DomainFailure(
          code: 'Dto.ParseError',
          message: 'Failed to parse UserDto: $e',
        ),
      );
    }
  }

  /// Creates a DTO from a domain [User] aggregate.
  factory UserDto.fromDomain(User user) {
    return UserDto(
      id: user.id,
      subscriptionStatus: user.subscriptionStatus.name,
      trialPeriod: user.trialPeriod != null
          ? TrialPeriodDto.fromDomain(user.trialPeriod!)
          : null,
      protocolIds: user.activeProtocolIds,
      onboardingCompleted: user.onboardingCompleted,
      createdAt: user.createdAt.toIso8601String(),
    );
  }
}
