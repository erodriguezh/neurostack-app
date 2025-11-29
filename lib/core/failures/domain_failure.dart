import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_failure.freezed.dart';

/// Base failure type for all domain validation errors.
///
/// Naming convention: `{Aggregate}.{Invariant}`
/// Example: `Protocol.NoCitations`, `User.ProtocolLimitReached`
@freezed
sealed class DomainFailure with _$DomainFailure {
  const factory DomainFailure({
    required String code,
    required String message,
  }) = _DomainFailure;
}
