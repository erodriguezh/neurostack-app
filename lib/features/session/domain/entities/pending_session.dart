import 'session_draft.dart';

/// Offline queue entity for sessions awaiting remote sync.
///
/// Wraps a validated [SessionDraft] with metadata needed for offline-first
/// persistence and sync retry logic.
///
/// This is NOT an aggregate root - it's a local storage wrapper that exists
/// only until the session is successfully synced to the server.
class PendingSession {
  const PendingSession._({
    required this.localId,
    required this.userId,
    required this.draft,
    required this.createdAt,
    required this.retryCount,
  });

  /// Client-generated UUID for local deduplication.
  final String localId;

  /// User ID for multi-account safety.
  /// Ensures pending sessions are only synced for the correct user.
  final String userId;

  /// The validated session draft to be persisted.
  final SessionDraft draft;

  /// When this pending session was created locally.
  final DateTime createdAt;

  /// Number of failed sync attempts.
  /// Used for exponential backoff or giving up after max retries.
  final int retryCount;

  /// Creates a new pending session for the offline queue.
  ///
  /// - [localId]: Client-generated UUID (use `uuid.v4()`)
  /// - [userId]: Current authenticated user's ID
  /// - [draft]: Already validated [SessionDraft]
  /// - [createdAt]: When this was queued locally
  factory PendingSession.create({
    required String localId,
    required String userId,
    required SessionDraft draft,
    required DateTime createdAt,
  }) {
    return PendingSession._(
      localId: localId,
      userId: userId,
      draft: draft,
      createdAt: createdAt,
      retryCount: 0,
    );
  }

  /// Reconstitutes from persistence (no validation, preserves retry count).
  ///
  /// Throws [StateError] if [retryCount] < 0 to detect corrupted persisted state.
  /// Runtime check (not assert) because asserts are stripped in release builds.
  factory PendingSession.reconstitute({
    required String localId,
    required String userId,
    required SessionDraft draft,
    required DateTime createdAt,
    required int retryCount,
  }) {
    if (retryCount < 0) {
      throw StateError(
        'Corrupted pending session data: negative retryCount $retryCount',
      );
    }
    return PendingSession._(
      localId: localId,
      userId: userId,
      draft: draft,
      createdAt: createdAt,
      retryCount: retryCount,
    );
  }

  /// Returns a copy with incremented retry count.
  PendingSession incrementRetry() {
    return PendingSession._(
      localId: localId,
      userId: userId,
      draft: draft,
      createdAt: createdAt,
      retryCount: retryCount + 1,
    );
  }

  /// Equality includes both [localId] and [userId] to prevent cross-user
  /// collisions if pending sessions are ever combined in memory.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingSession &&
        other.localId == localId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(localId, userId);
}
