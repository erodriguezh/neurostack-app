import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';

/// Extracts a user-facing error message from an [Either] result.
///
/// Used by Home and Library ViewModels. Progress uses a different signature
/// (returns [DomainFailure] instead of [String]) so it keeps its own variant.
String failureMessage<T>(Either<DomainFailure, T> result, String fallback) {
  final failure = result.getLeft().getOrElse(
    () => DomainFailure(
      code: 'UnexpectedError',
      message: fallback,
    ),
  );
  return failure.message;
}
