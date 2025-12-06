import 'package:neurostack/features/protocol/data/dtos/frequency_dto.dart';
import 'package:neurostack/features/protocol/data/dtos/target_dto.dart';
import 'frequency_dto_factory.dart';

/// Factory for creating TargetDto test instances.
///
/// Provides valid DTOs and invalid variations for testing toDomain failures.
abstract final class TargetDtoFactory {
  /// Creates a valid TargetDto with optional overrides.
  ///
  /// Default: Valid frequency, 30 minutes duration, moderate intensity.
  static TargetDto create({
    FrequencyDto? frequency,
    int? durationSeconds,
    String? intensity,
  }) {
    return TargetDto(
      frequency: frequency ?? FrequencyDtoFactory.create(),
      durationSeconds: durationSeconds ?? 1800, // 30 minutes
      intensity: intensity ?? 'moderate',
    );
  }

  // --- State Variations (toDomain failures) ---

  /// Invalid: nested Frequency fails validation (min < 1)
  /// Triggers Protocol.InvalidFrequency
  static TargetDto createWithInvalidFrequency() {
    return create(
      frequency: FrequencyDtoFactory.createWithInvalidMin(),
    );
  }

  /// Invalid: nested Frequency with max < min
  /// Triggers Protocol.MaxLessThanMin
  static TargetDto createWithMaxLessThanMin() {
    return create(
      frequency: FrequencyDtoFactory.createWithMaxLessThanMin(),
    );
  }

  // --- JSON Variations ---

  /// Valid JSON map with snake_case keys.
  static Map<String, dynamic> createValidJson({
    Map<String, dynamic>? frequency,
    int? durationSeconds,
    String? intensity,
  }) {
    return {
      'frequency': frequency ?? FrequencyDtoFactory.createValidJson(),
      'duration_seconds': durationSeconds ?? 1800,
      'intensity': intensity ?? 'moderate',
    };
  }

  /// JSON missing a required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }
}
