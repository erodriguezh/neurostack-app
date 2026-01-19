import 'package:neurostack/features/session/domain/entities/pending_session.dart';
import 'package:neurostack/features/session/domain/entities/session_draft.dart';
import '../constants/test_constants.dart';
import 'session_draft_factory.dart';

abstract final class PendingSessionFactory {
  /// Creates a valid PendingSession with default test values.
  static PendingSession create({
    String? localId,
    String? userId,
    SessionDraft? draft,
    DateTime? createdAt,
  }) {
    return PendingSession.create(
      localId: localId ?? TestConstants.pendingSession.localId,
      userId: userId ?? TestConstants.user.id,
      draft: draft ?? SessionDraftFactory.valid(),
      createdAt: createdAt ?? TestConstants.pendingSession.createdAt,
    );
  }

  /// Reconstitutes a PendingSession with retry count (for testing sync retry).
  static PendingSession withRetryCount({
    String? localId,
    String? userId,
    SessionDraft? draft,
    DateTime? createdAt,
    required int retryCount,
  }) {
    return PendingSession.reconstitute(
      localId: localId ?? TestConstants.pendingSession.localId,
      userId: userId ?? TestConstants.user.id,
      draft: draft ?? SessionDraftFactory.valid(),
      createdAt: createdAt ?? TestConstants.pendingSession.createdAt,
      retryCount: retryCount,
    );
  }

  /// Creates multiple pending sessions for testing batch operations.
  static List<PendingSession> createBatch({
    required int count,
    String? userId,
  }) {
    return List.generate(
      count,
      (index) => create(
        localId: 'local-$index',
        userId: userId,
      ),
    );
  }
}
