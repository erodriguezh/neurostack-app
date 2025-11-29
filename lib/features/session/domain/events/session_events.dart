import '../../../../core/models/common/domain_event.dart';

/// Raised when a new session is logged.
class SessionLoggedEvent extends DomainEvent {
  SessionLoggedEvent({
    required this.sessionId,
    required this.protocolId,
    required this.completedAt,
  });

  final String sessionId;
  final String protocolId;
  final DateTime completedAt;

  @override
  String toString() =>
      'SessionLoggedEvent(sessionId: $sessionId, protocolId: $protocolId, completedAt: $completedAt)';
}
