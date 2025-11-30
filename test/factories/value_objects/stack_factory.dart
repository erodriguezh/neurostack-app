import 'package:neurostack/features/user/domain/value_objects/stack.dart';

abstract final class StackFactory {
  static const protocol1 = 'protocol-1';
  static const protocol2 = 'protocol-2';
  static const protocol3 = 'protocol-3';

  /// Creates an empty Stack.
  static Stack empty() => Stack.empty();

  /// Creates a Stack with specific protocol IDs.
  static Stack fromIds(List<String> protocolIds) => Stack.fromIds(protocolIds);

  /// Creates a Stack at free tier capacity (2 protocols).
  static Stack atFreeCapacity() => Stack.fromIds([protocol1, protocol2]);

  /// Creates a Stack with 1 protocol (under free limit).
  static Stack underFreeLimit() => Stack.fromIds([protocol1]);

  /// Creates a Stack over free tier capacity (3 protocols).
  static Stack overFreeCapacity() =>
      Stack.fromIds([protocol1, protocol2, protocol3]);
}
