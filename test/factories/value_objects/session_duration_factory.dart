import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/session/domain/value_objects/session_duration.dart';

abstract final class SessionDurationFactory {
  /// Creates a valid SessionDuration (22 minutes, common session length).
  static SessionDuration valid() {
    return SessionDuration.create(const Duration(minutes: 22))
        .getOrElse((l) => throw Exception('Factory produced invalid SessionDuration: $l'));
  }

  /// Creates a SessionDuration with custom duration.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, SessionDuration> create(Duration duration) {
    return SessionDuration.create(duration);
  }
}
