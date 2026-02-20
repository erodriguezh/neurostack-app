import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/protocol_name.dart';
import '../../constants/test_constants.dart';

abstract final class ProtocolNameFactory {
  /// Creates a valid ProtocolName.
  static ProtocolName valid() {
    return ProtocolName.create(TestConstants.protocol.validName).getOrElse(
      (l) => throw Exception('Factory produced invalid ProtocolName: $l'),
    );
  }

  /// Creates a ProtocolName from a custom string.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, ProtocolName> create(String name) {
    return ProtocolName.create(name);
  }
}
