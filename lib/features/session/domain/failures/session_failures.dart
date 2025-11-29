import '../../../../core/failures/domain_failure.dart';

/// Domain failures specific to the Session aggregate.
///
/// Naming convention: `Session.{Invariant}`
abstract final class SessionFailures {
  // INV-S2: Session timestamp CANNOT be in the future
  static const timestampInFuture = DomainFailure(
    code: 'Session.TimestampInFuture',
    message: 'Session timestamp cannot be in the future',
  );

  // INV-S3: Session duration MUST be > 0 if specified
  static const durationMustBePositive = DomainFailure(
    code: 'Session.DurationMustBePositive',
    message: 'Session duration must be greater than zero',
  );
}
