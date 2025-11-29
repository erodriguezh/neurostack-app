import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/session_failures.dart';

part 'session_duration.freezed.dart';

/// Session duration value object.
///
/// Enforces **INV-S3**: Session duration MUST be > 0 if specified.
@freezed
sealed class SessionDuration with _$SessionDuration {
  const SessionDuration._();

  const factory SessionDuration._internal({
    required Duration value,
  }) = _SessionDuration;

  /// Creates a SessionDuration value object with validation.
  ///
  /// **INV-S3 Enforcement**: Duration must be greater than zero.
  ///
  /// Returns [Left] with [SessionFailures.durationMustBePositive] if duration <= 0.
  static Either<DomainFailure, SessionDuration> create(Duration duration) {
    if (duration.inSeconds <= 0) {
      return left(SessionFailures.durationMustBePositive);
    }

    return right(SessionDuration._internal(value: duration));
  }

  /// Duration in minutes (rounded down).
  int get inMinutes => value.inMinutes;

  /// Duration in seconds.
  int get inSeconds => value.inSeconds;

  /// Display text for UI.
  /// Returns "22m" for short durations or "1h 30m" for longer ones.
  String get displayText {
    final minutes = value.inMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '${hours}h ${remainingMinutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }
}
