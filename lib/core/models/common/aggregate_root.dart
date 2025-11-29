import 'domain_event.dart';
import 'entity.dart';

mixin AggregateRootMixin<TId> on EntityMixin<TId> {
  final List<DomainEvent> _domainEvents = [];

  List<DomainEvent> get domainEvents => List.unmodifiable(_domainEvents);
  bool get hasDomainEvents => _domainEvents.isNotEmpty;

  void raiseDomainEvent(DomainEvent event) {
    _domainEvents.add(event);
  }

  List<DomainEvent> popDomainEvents() {
    final events = List<DomainEvent>.from(_domainEvents);
    _domainEvents.clear();
    return events;
  }

  void clearDomainEvents() {
    _domainEvents.clear();
  }
}
