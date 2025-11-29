import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/protocol_failures.dart';

part 'protocol_name.freezed.dart';

/// Protocol name value object with validation.
///
/// Enforces **INV-P3**: Protocol names MUST NOT include researcher names.
///
/// Validation rules:
/// - Not empty
/// - Max 100 characters
/// - Must not contain researcher name patterns
@freezed
sealed class ProtocolName with _$ProtocolName {
  const ProtocolName._();

  const factory ProtocolName._internal({
    required String value,
  }) = _ProtocolName;

  /// Patterns that indicate researcher names (INV-P3).
  ///
  /// Detects patterns like:
  /// - "Huberman's Protocol", "Sinclair's Method"
  /// - "Dr. Sinclair", "Dr Huberman"
  /// - "The Huberman Protocol"
  static final _researcherPatterns = [
    // Possessive form: "Huberman's Protocol", "Sinclair's Method"
    RegExp(r"\b[A-Z][a-z]+[''']s\s+(Protocol|Method|Routine|Stack|Plan)", caseSensitive: false),
    // Doctor prefix: "Dr. Sinclair", "Dr Huberman"
    RegExp(r'\bDr\.?\s+[A-Z][a-z]+', caseSensitive: false),
    // "The [Name] Protocol/Method"
    RegExp(r'\bThe\s+[A-Z][a-z]+\s+(Protocol|Method|Routine)', caseSensitive: false),
  ];

  /// Creates a ProtocolName value object with validation.
  ///
  /// Returns [Left] with appropriate failure if validation fails.
  static Either<DomainFailure, ProtocolName> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return left(ProtocolFailures.nameEmpty);
    }

    if (trimmed.length > 100) {
      return left(ProtocolFailures.nameTooLong);
    }

    // INV-P3: Check for researcher name patterns
    for (final pattern in _researcherPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return left(ProtocolFailures.nameContainsResearcher);
      }
    }

    return right(ProtocolName._internal(value: trimmed));
  }

  @override
  String toString() => value;
}
