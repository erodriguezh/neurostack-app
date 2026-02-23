import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_description.dart';

import '../../constants/test_constants.dart';
import '../factory_helpers.dart';

abstract final class ProtocolDescriptionFactory {
  /// Creates a valid ProtocolDescription.
  static ProtocolDescription valid() {
    return unwrapOrThrow(
      ProtocolDescription.create(
        TestConstants.protocol.validDescription,
      ),
      'ProtocolDescription',
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
