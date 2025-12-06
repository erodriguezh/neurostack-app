import 'package:neurostack/features/protocol/data/dtos/frequency_dto.dart';

/// Factory for creating FrequencyDto test instances.
///
/// Provides valid DTOs and invalid variations for testing toDomain failures.
abstract final class FrequencyDtoFactory {
  /// Creates a valid FrequencyDto with optional overrides.
  ///
  /// Default: 3-4 times per week (valid range).
  static FrequencyDto create({
    int minPerWeek = 3,
    int maxPerWeek = 4,
  }) {
    return FrequencyDto(
      minPerWeek: minPerWeek,
      maxPerWeek: maxPerWeek,
    );
  }

  // --- State Variations (toDomain failures) ---

  /// Invalid: min < 1 triggers Protocol.InvalidFrequency
  static FrequencyDto createWithInvalidMin() {
    return FrequencyDto(
      minPerWeek: 0,
      maxPerWeek: 4,
    );
  }

  /// Invalid: max < min triggers Protocol.MaxLessThanMin
  static FrequencyDto createWithMaxLessThanMin() {
    return FrequencyDto(
      minPerWeek: 5,
      maxPerWeek: 3,
    );
  }

  // --- JSON Variations ---

  /// Valid JSON map with snake_case keys.
  static Map<String, dynamic> createValidJson({
    int? minPerWeek,
    int? maxPerWeek,
  }) {
    return {
      'min_per_week': minPerWeek ?? 3,
      'max_per_week': maxPerWeek ?? 4,
    };
  }

  /// JSON missing a required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }
}
