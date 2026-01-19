import 'package:neurostack/features/session/data/dtos/pending_session_dto.dart';
import '../../constants/test_constants.dart';

/// Factory for creating PendingSessionDto test instances.
///
/// Provides valid DTOs and JSON maps for testing serialization round-trips.
abstract final class PendingSessionDtoFactory {
  // --- Core Factory ---

  /// Creates a valid PendingSessionDto with optional overrides.
  ///
  /// Default: Valid pending session with no duration or notes.
  static PendingSessionDto create({
    String? localId,
    String? userId,
    String? protocolId,
    String? completedAt,
    int? durationSeconds,
    String? notes,
    String? createdAt,
    int retryCount = 0,
  }) {
    return PendingSessionDto(
      localId: localId ?? TestConstants.pendingSession.localId,
      userId: userId ?? TestConstants.user.id,
      protocolId: protocolId ?? TestConstants.session.protocolId,
      completedAt: completedAt ??
          TestConstants.session.validCompletedAt.toIso8601String(),
      durationSeconds: durationSeconds,
      notes: notes,
      createdAt:
          createdAt ?? TestConstants.pendingSession.createdAt.toIso8601String(),
      retryCount: retryCount,
    );
  }

  /// Creates a PendingSessionDto with duration.
  static PendingSessionDto createWithDuration({
    int durationSeconds = 1800, // 30 minutes
  }) {
    return create(durationSeconds: durationSeconds);
  }

  /// Creates a PendingSessionDto with notes.
  static PendingSessionDto createWithNotes({
    String notes = 'Test session notes',
  }) {
    return create(notes: notes);
  }

  /// Creates a PendingSessionDto with all optional fields populated.
  static PendingSessionDto createFull() {
    return create(
      durationSeconds: 2700, // 45 minutes
      notes: 'Full test session with duration and notes',
    );
  }

  /// Creates a PendingSessionDto with retry count.
  static PendingSessionDto createWithRetries({
    int retryCount = 3,
  }) {
    return create(retryCount: retryCount);
  }

  // --- Invalid Variations (toDomain failures) ---

  /// Invalid duration (zero seconds - violates INV-S3).
  /// Triggers StateError in toDomain.
  static PendingSessionDto createWithZeroDuration() {
    return create(durationSeconds: 0);
  }

  /// Invalid duration (negative seconds).
  /// Triggers StateError in toDomain.
  static PendingSessionDto createWithNegativeDuration() {
    return create(durationSeconds: -1);
  }

  /// Invalid completedAt date format.
  /// Triggers FormatException in toDomain.
  static PendingSessionDto createWithInvalidCompletedAt() {
    return create(completedAt: TestConstants.dto.invalidDateTime);
  }

  /// Invalid createdAt date format.
  /// Triggers FormatException in toDomain.
  static PendingSessionDto createWithInvalidCreatedAt() {
    return create(createdAt: TestConstants.dto.invalidDateTime);
  }

  // --- JSON Variations ---

  /// Valid JSON map with snake_case keys.
  static Map<String, dynamic> createValidJson({
    String? localId,
    String? userId,
    int? durationSeconds,
    String? notes,
    int retryCount = 0,
  }) {
    return {
      'local_id': localId ?? TestConstants.pendingSession.localId,
      'user_id': userId ?? TestConstants.user.id,
      'protocol_id': TestConstants.session.protocolId,
      'completed_at':
          TestConstants.session.validCompletedAt.toIso8601String(),
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (notes != null) 'notes': notes,
      'created_at':
          TestConstants.pendingSession.createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  /// JSON missing a required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }

  /// JSON with wrong type for a field.
  static Map<String, dynamic> createJsonWithWrongType(
    String field,
    Object value,
  ) {
    final json = createValidJson();
    json[field] = value;
    return json;
  }
}
