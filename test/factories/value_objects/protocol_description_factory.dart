import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';

import '../../constants/test_constants.dart';

abstract final class ProtocolDescriptionFactory {
  /// Creates a valid ProtocolDescription.
  static ProtocolDescription valid() {
    return ProtocolDescription.create(
      TestConstants.protocol.validDescription,
    ).getOrElse(
      (l) => throw Exception(
        'Factory produced invalid ProtocolDescription: $l',
      ),
    );
  }

  /// Creates a ProtocolDescription from a custom string.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, ProtocolDescription> create(
    String description,
  ) {
    return ProtocolDescription.create(description);
  }
}
