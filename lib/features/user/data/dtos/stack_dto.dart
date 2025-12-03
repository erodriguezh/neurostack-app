import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../../domain/value_objects/stack.dart';

part 'stack_dto.freezed.dart';
part 'stack_dto.g.dart';

/// DTO for [Stack] value object serialization.
///
/// Maps a user's active protocol IDs between JSON and domain.
@freezed
abstract class StackDto with _$StackDto {
  const StackDto._();

  const factory StackDto({
    required List<String> protocolIds,
  }) = _StackDto;

  factory StackDto.fromJson(Map<String, dynamic> json) =>
      _$StackDtoFromJson(json);

  /// Converts this DTO to the domain [Stack] value object.
  ///
  /// Stack has no validation that can fail, so always returns [Right].
  Either<DomainFailure, Stack> toDomain() {
    return right(Stack.fromIds(protocolIds));
  }

  /// Creates a DTO from a domain [Stack] value object.
  factory StackDto.fromDomain(Stack stack) {
    return StackDto(protocolIds: stack.protocolIds);
  }
}
