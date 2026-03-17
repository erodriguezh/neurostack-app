import 'package:logging/logging.dart';

import '../../../features/session/data/data_sources/session_local_data_source.dart';
import 'in_app_review_service.dart';

/// Shared helper for the post-session programmatic review trigger.
///
/// Used by both HomeView and ProgressView to eliminate duplicated logic.
/// Captures the session count snapshot (synced + pending) and triggers
/// the review prompt after a delay.
class ReviewTriggerHelper {
  ReviewTriggerHelper({
    required SessionLocalDataSource sessionLocalDataSource,
    required InAppReviewService inAppReviewService,
  })  : _sessionLocalDataSource = sessionLocalDataSource,
        _inAppReviewService = inAppReviewService;

  final SessionLocalDataSource _sessionLocalDataSource;
  final InAppReviewService _inAppReviewService;
  final Logger _logger = Logger('ReviewTriggerHelper');

  /// Captures the total session count from local stores.
  ///
  /// Call from `onSessionLogged` (before sync moves data between stores)
  /// to get an accurate snapshot. Returns a `Future<int>` -- the caller
  /// stores it and awaits after modal dismiss.
  Future<int> captureSessionCount(String userId) async {
    try {
      final results = await Future.wait([
        _sessionLocalDataSource.getSyncedSessions(userId),
        _sessionLocalDataSource.getPendingSessions(userId),
      ]);
      return results[0].length + results[1].length;
    } catch (e, st) {
      _logger.warning('Failed to capture session count', e, st);
      return 0;
    }
  }

  /// Triggers the review prompt after a 2-second delay.
  ///
  /// The delay ensures the success toast from session logging is visible
  /// before the review dialog appears. Call after modal dismiss with the
  /// count from [captureSessionCount].
  Future<void> triggerReviewIfNeeded(
    int sessionCount,
    String userId,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _inAppReviewService.requestReviewIfNeeded(sessionCount, userId);
    } catch (e, st) {
      _logger.warning('triggerReviewIfNeeded failed', e, st);
    }
  }
}
