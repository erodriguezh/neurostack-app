import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/value_objects/stack.dart';

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
/// - **INV-U4**: Users MUST complete onboarding before tracking Sessions
@freezed
abstract class UserDto with _$UserDto {
  const UserDto._();

  const factory UserDto({
    @JsonKey(fromJson: _stringFromJson) required String id,
    @JsonKey(
      name: 'subscription_status',
      fromJson: _stringFromJson,
    )
    required String subscriptionStatus,
    @JsonKey(
      name: 'protocol_ids',
      fromJson: _protocolIdsFromJson,
      toJson: _protocolIdsToJson,
    )
    required List<String> protocolIds,
    @JsonKey(name: 'onboarding_completed') required bool onboardingCompleted,
    @JsonKey(name: 'created_at', fromJson: _stringFromJson)
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

      // Parse date
      final createdAtDate = DateTime.parse(createdAt);

      // Create stack from protocol IDs
      final domainStack = Stack.fromIds(protocolIds);

      // Reconstitute (not create) to avoid domain events
      return right(
        User.reconstitute(
          id: id,
          subscriptionStatus: domainStatus,
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
      protocolIds: user.activeProtocolIds,
      onboardingCompleted: user.onboardingCompleted,
      createdAt: user.createdAt.toIso8601String(),
    );
  }
}

String _stringFromJson(dynamic raw) {
  if (raw == null) {
    return '';
  }
  return raw.toString();
}

List<String> _protocolIdsFromJson(dynamic raw) {
  if (raw is List) {
    return raw.map((value) => value.toString()).toList();
  }
  return const [];
}

List<dynamic> _protocolIdsToJson(List<String> ids) {
  return ids
      .map<dynamic>((value) => int.tryParse(value) ?? value)
      .toList();
}
