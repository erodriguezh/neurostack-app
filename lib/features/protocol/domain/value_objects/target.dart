import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import 'frequency.dart';

part 'target.freezed.dart';

/// The ideal specification for a protocol (frequency, duration, intensity).
///
/// Enforces **INV-P2**: Protocol Target specifications MUST be measurable.
/// At minimum, frequency must be present.
///
/// Examples:
/// - "20 min at 108°F, 3-4x/week"
/// - "40 min at 65% max HR, 3x/week"
@freezed
sealed class Target with _$Target {
  const Target._();

  const factory Target._internal({
    required Frequency frequency,
    Duration? duration,
    String? intensity,
  }) = _Target;

  /// Creates a Target value object with validation.
  ///
  /// **INV-P2 Enforcement**: [frequency] is required to ensure measurability.
  ///
  /// - [frequency]: How often (required)
  /// - [duration]: How long per session (optional)
  /// - [intensity]: Intensity specification like "108°F" or "65% max HR" (optional)
  static Either<DomainFailure, Target> create({
    required Frequency frequency,
    Duration? duration,
    String? intensity,
  }) {
    // INV-P2: frequency is required, which is enforced by the type system
    // Additional validations could be added here if needed

    return right(Target._internal(
      frequency: frequency,
      duration: duration,
      intensity: intensity?.trim().isEmpty == true ? null : intensity?.trim(),
    ));
  }

  /// Display text for UI.
  /// Returns formatted string like "20 min at 108°F, 3-4x/week"
  String get displayText {
    final parts = <String>[];

    if (duration != null) {
      final minutes = duration!.inMinutes;
      if (minutes >= 60) {
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        if (remainingMinutes > 0) {
          parts.add('${hours}h ${remainingMinutes}m');
        } else {
          parts.add('${hours}h');
        }
      } else {
        parts.add('$minutes min');
      }
    }

    if (intensity != null) {
      parts.add('at $intensity');
    }

    parts.add(frequency.displayText);

    return parts.join(', ');
  }
}
