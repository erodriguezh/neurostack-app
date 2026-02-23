import 'package:fpdart/fpdart.dart';

/// Unwraps an [Either] result, throwing if it is a [Left].
///
/// Use this in test factories to convert `Either<L, T>` into `T` when
/// the factory is expected to produce a valid value. The [context] string
/// is included in the exception message to identify which factory failed.
///
/// ```dart
/// static Frequency valid() {
///   return unwrapOrThrow(
///     Frequency.create(minPerWeek: 3, maxPerWeek: 4),
///     'Frequency',
///   );
/// }
/// ```
///
/// This is a top-level function (not an extension on `Either`) to prevent
/// accidental auto-import into `lib/` production code.
T unwrapOrThrow<L, T>(Either<L, T> result, [String? context]) {
  return result.getOrElse(
    (l) => throw Exception(
      'Factory produced invalid ${context ?? 'value'}: $l',
    ),
  );
}
