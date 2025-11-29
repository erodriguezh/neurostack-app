import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/protocol_failures.dart';

part 'frequency.freezed.dart';

/// Weekly frequency specification for a protocol target.
///
/// Represents how many times per week a protocol should be performed.
/// Example: "3-4x/week" or "3x/week"
@freezed
sealed class Frequency with _$Frequency {
  const Frequency._();

  const factory Frequency._internal({
    required int minPerWeek,
    required int maxPerWeek,
  }) = _Frequency;

  /// Creates a Frequency value object with validation.
  ///
  /// - [minPerWeek]: Minimum times per week (must be >= 1)
  /// - [maxPerWeek]: Maximum times per week (defaults to minPerWeek, must be >= minPerWeek)
  static Either<DomainFailure, Frequency> create({
    required int minPerWeek,
    int? maxPerWeek,
  }) {
    final max = maxPerWeek ?? minPerWeek;

    if (minPerWeek < 1) {
      return left(ProtocolFailures.invalidFrequency);
    }

    if (max < minPerWeek) {
      return left(ProtocolFailures.maxLessThanMin);
    }

    return right(Frequency._internal(minPerWeek: minPerWeek, maxPerWeek: max));
  }

  /// Display text for UI.
  /// Returns "3-4x/week" for range or "3x/week" for single value.
  String get displayText {
    if (minPerWeek == maxPerWeek) {
      return '${minPerWeek}x/week';
    }
    return '$minPerWeek-${maxPerWeek}x/week';
  }
}
