import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';

abstract final class FrequencyFactory {
  /// Creates a valid Frequency (3-4x/week, standard for many protocols).
  static Frequency valid() {
    return Frequency.create(minPerWeek: 3, maxPerWeek: 4)
        .getOrElse((l) => throw Exception('Factory produced invalid Frequency: $l'));
  }

  /// Creates a Frequency with custom values.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, Frequency> create({
    required int minPerWeek,
    required int maxPerWeek,
  }) {
    return Frequency.create(minPerWeek: minPerWeek, maxPerWeek: maxPerWeek);
  }
}
