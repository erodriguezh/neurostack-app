import 'package:freezed_annotation/freezed_annotation.dart';

part 'stack.freezed.dart';

/// A user's collection of active protocol IDs.
///
/// Immutable value object - User aggregate creates new instances on mutations.
///
/// Example: "My morning stack: Sunlight, Cold Shower, Zone 2"
@freezed
sealed class Stack with _$Stack {
  const Stack._();

  @internal
  const factory Stack({
    required List<String> protocolIds,
  }) = _Stack;

  /// Creates an empty stack.
  factory Stack.empty() => const Stack(protocolIds: []);

  /// Creates a stack from a list of protocol IDs.
  factory Stack.fromIds(List<String> ids) =>
      Stack(protocolIds: List.unmodifiable(ids));

  /// Number of protocols in the stack.
  int get count => protocolIds.length;

  /// True if no protocols are in the stack.
  bool get isEmpty => protocolIds.isEmpty;

  /// True if stack is not empty.
  bool get isNotEmpty => protocolIds.isNotEmpty;

  /// Check if a protocol is in the stack.
  bool contains(String protocolId) => protocolIds.contains(protocolId);

  /// Returns a new Stack with the protocol added.
  /// Does not check for duplicates - caller should verify.
  Stack add(String protocolId) => Stack.fromIds([...protocolIds, protocolId]);

  /// Returns a new Stack with the protocol removed.
  Stack remove(String protocolId) =>
      Stack.fromIds(protocolIds.where((id) => id != protocolId).toList());
}
