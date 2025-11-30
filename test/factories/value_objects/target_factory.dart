import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/target.dart';
import 'package:neurostack/features/protocol/domain/value_objects/frequency.dart';
import 'frequency_factory.dart';

abstract final class TargetFactory {
  /// Creates a valid Target (40 min, 3-4x/week, moderate intensity).
  static Target valid() {
    return Target.create(
      frequency: FrequencyFactory.valid(),
      duration: const Duration(minutes: 40),
      intensity: 'moderate',
    ).getOrElse((l) => throw Exception('Factory produced invalid Target: $l'));
  }

  /// Creates a Target with custom values.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, Target> create({
    required Frequency frequency,
    Duration? duration,
    String? intensity,
  }) {
    return Target.create(
      frequency: frequency,
      duration: duration,
      intensity: intensity,
    );
  }

  /// Creates a Target with only frequency (no duration or intensity).
  static Target frequencyOnly() {
    return Target.create(
      frequency: FrequencyFactory.valid(),
    ).getOrElse((l) => throw Exception('Factory produced invalid Target: $l'));
  }
}
