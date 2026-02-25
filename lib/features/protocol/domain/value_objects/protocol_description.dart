import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/protocol_failures.dart';

part 'protocol_description.freezed.dart';

/// Protocol description value object with validation.
///
/// Validation rules:
/// - Not empty after trim
/// - Max 2000 characters after trim
@freezed
sealed class ProtocolDescription with _$ProtocolDescription {
  const ProtocolDescription._();

  const factory ProtocolDescription._internal({
    required String value,
  }) = _ProtocolDescription;

  /// Creates a ProtocolDescription value object with validation.
  ///
  /// Returns [Left] with [ProtocolFailures.descriptionEmpty] if the
  /// trimmed input is empty.
  /// Returns [Left] with [ProtocolFailures.descriptionTooLong] if the
  /// trimmed input exceeds 2000 characters.
  static Either<DomainFailure, ProtocolDescription> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return left(ProtocolFailures.descriptionEmpty);
    }

    if (trimmed.length > 2000) {
      return left(ProtocolFailures.descriptionTooLong);
    }

    return right(ProtocolDescription._internal(value: trimmed));
  }

  @override
  String toString() => value;
}
