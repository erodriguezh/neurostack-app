import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/events/protocol_events.dart';
import 'package:neurostack/features/protocol/domain/failures/protocol_failures.dart';
import '../../factories/factories.dart';
import '../../matchers/either_matchers.dart';

void main() {
  group('Protocol', () {
    group('create', () {
      test('create_withValidData_succeeds', () {
        // Act
        final result = ProtocolFactory.create();

        // Assert
        expect(result, isRight<Protocol>());
      });

      test('create_withDescription_preservesDescription', () {
        // Arrange
        final description = ProtocolDescriptionFactory.valid();

        // Act
        final result = ProtocolFactory.create(description: description);

        // Assert
        expect(result, isRight<Protocol>());
        final protocol = result.getOrElse(
          (l) => throw Exception('Failed to create protocol: $l'),
        );
        expect(protocol.description, description);
      });

      // INV-P1: Must have citation
      test('create_withNoCitations_returnsNoCitations', () {
        // Act
        final result = ProtocolFactory.create(citations: []);

        // Assert
        expect(result, isLeftWith(ProtocolFailures.noCitations));
      });

      test('create_withMultipleCitations_succeeds', () {
        // Arrange
        final citations = [
          ResearchCitationFactory.valid(),
          ResearchCitationFactory.create(
            authors: 'Smith J, Doe A',
            year: 2020,
            title: 'Another study',
            journal: 'Science',
          ).getOrElse((l) => throw Exception('Failed to create citation: $l')),
        ];

        // Act
        final result = ProtocolFactory.create(citations: citations);

        // Assert
        expect(result, isRight<Protocol>());
        final protocol = result.getOrElse(
          (l) => throw Exception('Failed to create protocol: $l'),
        );
        expect(protocol.citations.length, 2);
      });
    });

    group('reconstitute', () {
      test('reconstitute_createsProtocolWithoutValidation', () {
        // Act
        final protocol = ProtocolFactory.reconstitute(
          id: 'protocol-123',
          citations: [], // Would fail validation in create()
        );

        // Assert
        expect(protocol.id, 'protocol-123');
        expect(protocol.citations, isEmpty);
      });
    });

    group('softDelete', () {
      // INV-P4: Preserve history
      test('softDelete_whenActive_succeeds', () {
        // Arrange
        final protocol = ProtocolFactory.valid();
        final deleteTime = DateTime(2025, 1, 15);

        // Act
        final result = protocol.softDelete(currentTime: deleteTime);

        // Assert
        expect(result, isRight<Protocol>());
        final deleted = result.getOrElse(
          (l) => throw Exception('Failed to soft delete: $l'),
        );
        expect(deleted.deletedAt, deleteTime);
        expect(deleted.isActive, false);
      });

      test('softDelete_whenAlreadyDeleted_returnsAlreadyDeleted', () {
        // Arrange
        final protocol = ProtocolFactory.reconstitute(
          deletedAt: DateTime(2025, 1, 10),
        );
        final deleteTime = DateTime(2025, 1, 15);

        // Act
        final result = protocol.softDelete(currentTime: deleteTime);

        // Assert
        expect(result, isLeftWith(ProtocolFailures.alreadyDeleted));
      });
    });

    group('domain events', () {
      test('create_raisesProtocolCreatedEvent', () {
        // Arrange
        const id = 'protocol-123';

        // Act
        final result = ProtocolFactory.create(id: id);

        // Assert
        final protocol = result.getOrElse(
          (l) => throw Exception('Failed to create protocol: $l'),
        );
        expect(protocol.hasDomainEvents, true);
        expect(protocol.domainEvents.length, 1);
        expect(
          protocol.domainEvents.first,
          isA<ProtocolCreatedEvent>().having(
            (e) => e.protocolId,
            'protocolId',
            id,
          ),
        );
      });

      test('softDelete_raisesProtocolDeletedEvent', () {
        // Arrange
        final protocol = ProtocolFactory.valid();
        protocol.clearDomainEvents(); // Clear creation event
        final deleteTime = DateTime(2025, 1, 15);

        // Act
        final result = protocol.softDelete(currentTime: deleteTime);

        // Assert
        final deleted = result.getOrElse(
          (l) => throw Exception('Failed to soft delete: $l'),
        );
        expect(deleted.hasDomainEvents, true);
        expect(deleted.domainEvents.length, 1);
        expect(
          deleted.domainEvents.first,
          isA<ProtocolDeletedEvent>().having(
            (e) => e.protocolId,
            'protocolId',
            protocol.id,
          ),
        );
      });
    });

    group('citations', () {
      test('citations_returnsImmutableList', () {
        // Arrange
        final protocol = ProtocolFactory.valid();

        // Act
        final citations = protocol.citations;

        // Assert - attempting to modify should throw
        expect(
          () => citations.add(ResearchCitationFactory.valid()),
          throwsUnsupportedError,
        );
      });
    });
  });
}
