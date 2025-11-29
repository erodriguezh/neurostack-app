import '../../../../core/models/common/domain_event.dart';

/// Raised when a new protocol is created.
class ProtocolCreatedEvent extends DomainEvent {
  ProtocolCreatedEvent({required this.protocolId});

  final String protocolId;

  @override
  String toString() => 'ProtocolCreatedEvent(protocolId: $protocolId)';
}

/// Raised when a protocol is soft-deleted.
class ProtocolDeletedEvent extends DomainEvent {
  ProtocolDeletedEvent({required this.protocolId});

  final String protocolId;

  @override
  String toString() => 'ProtocolDeletedEvent(protocolId: $protocolId)';
}
