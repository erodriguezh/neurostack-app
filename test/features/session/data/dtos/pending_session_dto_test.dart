import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/session/data/dtos/pending_session_dto.dart';
import 'package:neurostack/features/session/domain/entities/pending_session.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/dtos/pending_session_dto_factory.dart';
import '../../../../factories/pending_session_factory.dart';
import '../../../../factories/session_draft_factory.dart';
import '../../../../factories/value_objects/session_duration_factory.dart';

void main() {
  group('PendingSessionDto', () {
    group('toDomain', () {
      test('toDomain_whenValid_returnsPendingSession', () {
        // Arrange
        final dto = PendingSessionDtoFactory.create();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isA<PendingSession>());
        expect(result.localId, TestConstants.pendingSession.localId);
        expect(result.userId, TestConstants.user.id);
        expect(result.draft.protocolId, TestConstants.session.protocolId);
        expect(result.retryCount, 0);
      });

      test('toDomain_withDuration_preservesDuration', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithDuration(
          durationSeconds: 1800,
        );

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result.draft.duration, isNotNull);
        expect(result.draft.duration!.inSeconds, 1800);
      });

      test('toDomain_withNotes_preservesNotes', () {
        // Arrange
        const testNotes = 'My test notes';
        final dto = PendingSessionDtoFactory.createWithNotes(notes: testNotes);

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result.draft.notes, testNotes);
      });

      test('toDomain_withRetryCount_preservesRetryCount', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithRetries(retryCount: 5);

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result.retryCount, 5);
      });

      test('toDomain_whenZeroDuration_throwsStateError', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithZeroDuration();

        // Act & Assert
        expect(() => dto.toDomain(), throwsStateError);
      });

      test('toDomain_whenNegativeDuration_throwsStateError', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithNegativeDuration();

        // Act & Assert
        expect(() => dto.toDomain(), throwsStateError);
      });

      test('toDomain_whenInvalidCompletedAt_throwsFormatException', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithInvalidCompletedAt();

        // Act & Assert
        expect(() => dto.toDomain(), throwsFormatException);
      });

      test('toDomain_whenInvalidCreatedAt_throwsFormatException', () {
        // Arrange
        final dto = PendingSessionDtoFactory.createWithInvalidCreatedAt();

        // Act & Assert
        expect(() => dto.toDomain(), throwsFormatException);
      });

      test('toDomain_bypassesTimestampValidation_withFutureDate', () {
        // Arrange - future date would fail SessionDraft.create (INV-S2)
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final dto = PendingSessionDtoFactory.create(
          completedAt: futureDate.toIso8601String(),
        );

        // Act - toDomain uses reconstitute, bypassing validation
        final result = dto.toDomain();

        // Assert - succeeds even though date is in the future
        expect(result.draft.completedAt, futureDate);
      });

      test('toDomain_bypassesTimestampValidation_withTooOldDate', () {
        // Arrange - date > 7 days old would fail SessionDraft.create (INV-S4)
        final tooOldDate = DateTime.now().subtract(const Duration(days: 30));
        final dto = PendingSessionDtoFactory.create(
          completedAt: tooOldDate.toIso8601String(),
        );

        // Act - toDomain uses reconstitute, bypassing validation
        final result = dto.toDomain();

        // Assert - succeeds even though date is too old
        expect(result.draft.completedAt, tooOldDate);
      });
    });

    group('fromJson', () {
      final requiredFields = [
        'local_id',
        'user_id',
        'protocol_id',
        'completed_at',
        'created_at',
        'retry_count',
      ];

      for (final field in requiredFields) {
        test('fromJson_whenMissing${_pascalCase(field)}_throws', () {
          // Arrange
          final json = PendingSessionDtoFactory.createJsonMissingField(field);

          // Act & Assert
          // Use broad matcher - json_serializable exception type varies by version
          expect(
            () => PendingSessionDto.fromJson(json),
            throwsA(anything),
          );
        });
      }

      test('fromJson_whenValid_returnsDto', () {
        // Arrange
        final json = PendingSessionDtoFactory.createValidJson();

        // Act
        final dto = PendingSessionDto.fromJson(json);

        // Assert
        expect(dto.localId, TestConstants.pendingSession.localId);
        expect(dto.userId, TestConstants.user.id);
        expect(dto.protocolId, TestConstants.session.protocolId);
        expect(dto.retryCount, 0);
      });

      test('fromJson_withOptionalFields_preservesThem', () {
        // Arrange
        final json = PendingSessionDtoFactory.createValidJson(
          durationSeconds: 2400,
          notes: 'Test notes',
        );

        // Act
        final dto = PendingSessionDto.fromJson(json);

        // Assert
        expect(dto.durationSeconds, 2400);
        expect(dto.notes, 'Test notes');
      });

      test('fromJson_withoutOptionalFields_hasNullValues', () {
        // Arrange
        final json = PendingSessionDtoFactory.createValidJson();

        // Act
        final dto = PendingSessionDto.fromJson(json);

        // Assert
        expect(dto.durationSeconds, isNull);
        expect(dto.notes, isNull);
      });
    });

    group('fromDomain', () {
      test('fromDomain_roundtrip_preservesData', () {
        // Arrange - Create valid domain entity
        final original = PendingSessionFactory.create();

        // Act
        final dto = PendingSessionDto.fromDomain(original);
        final restored = dto.toDomain();

        // Assert
        expect(restored.localId, original.localId);
        expect(restored.userId, original.userId);
        expect(restored.draft.protocolId, original.draft.protocolId);
        expect(restored.draft.completedAt, original.draft.completedAt);
        expect(restored.retryCount, original.retryCount);
        expect(restored.createdAt, original.createdAt);
      });

      test('fromDomain_withDuration_roundtrip_preservesDuration', () {
        // Arrange
        final duration = SessionDurationFactory.valid(); // 22 minutes
        final draft = SessionDraftFactory.valid(duration: duration);
        final original = PendingSessionFactory.create(draft: draft);

        // Act
        final dto = PendingSessionDto.fromDomain(original);
        final restored = dto.toDomain();

        // Assert
        expect(restored.draft.duration, isNotNull);
        expect(restored.draft.duration!.inSeconds, duration.inSeconds);
      });

      test('fromDomain_withNotes_roundtrip_preservesNotes', () {
        // Arrange
        const testNotes = 'Session went well';
        final draft = SessionDraftFactory.valid(notes: testNotes);
        final original = PendingSessionFactory.create(draft: draft);

        // Act
        final dto = PendingSessionDto.fromDomain(original);
        final restored = dto.toDomain();

        // Assert
        expect(restored.draft.notes, testNotes);
      });

      test('fromDomain_withRetryCount_roundtrip_preservesRetryCount', () {
        // Arrange
        final original = PendingSessionFactory.withRetryCount(retryCount: 3);

        // Act
        final dto = PendingSessionDto.fromDomain(original);
        final restored = dto.toDomain();

        // Assert
        expect(restored.retryCount, 3);
      });
    });

    group('toJson/fromJson roundtrip', () {
      test('jsonRoundtrip_preservesAllFields', () {
        // Arrange
        final original = PendingSessionDtoFactory.createFull();

        // Act
        final json = original.toJson();
        final restored = PendingSessionDto.fromJson(json);

        // Assert
        expect(restored.localId, original.localId);
        expect(restored.userId, original.userId);
        expect(restored.protocolId, original.protocolId);
        expect(restored.completedAt, original.completedAt);
        expect(restored.durationSeconds, original.durationSeconds);
        expect(restored.notes, original.notes);
        expect(restored.createdAt, original.createdAt);
        expect(restored.retryCount, original.retryCount);
      });

      test('jsonRoundtrip_withNullOptionalFields_omitsNullKeys', () {
        // Arrange
        final original = PendingSessionDtoFactory.create();

        // Act
        final json = original.toJson();
        final restored = PendingSessionDto.fromJson(json);

        // Assert - null keys are omitted due to includeIfNull: false
        expect(json.containsKey('duration_seconds'), isFalse);
        expect(json.containsKey('notes'), isFalse);
        expect(restored.durationSeconds, isNull);
        expect(restored.notes, isNull);
      });
    });
  });
}

/// Converts snake_case to PascalCase for test naming.
String _pascalCase(String snakeCase) {
  return snakeCase
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join();
}
