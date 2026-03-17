import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../internal_notification/notify_service.dart';
import '../internal_notification/toast/toast_event.dart';
import 'in_app_review_adapter.dart';

/// Wrapper around the `in_app_review` plugin for programmatic and manual
/// review flows.
///
/// ## Design
///
/// - **Synchronous init:** `init()` is synchronous -- no async race conditions.
///   All public methods guard on `_isInitialized`.
/// - **Platform guard:** `init()` is a no-op on web and non-mobile platforms.
///   `_isInitialized` stays `false`, making the entire service inert.
/// - **Platform-specific config:** iOS requires `APP_STORE_ID`. Android needs
///   nothing for service init (plugin auto-detects from manifest).
/// - **Test seam:** [InAppReviewAdapter] enables full mocking in unit tests.
///
/// Follows the same service-wrapper pattern as `UserOrientService`.
class InAppReviewService {
  InAppReviewService({
    required SharedPreferences prefs,
    required NotifyService notifyService,
    required InAppReviewAdapter adapter,
    this.appStoreId = const String.fromEnvironment('APP_STORE_ID'),
    this.playStorePackageName =
        const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
  })  : _prefs = prefs,
        _notifyService = notifyService,
        _adapter = adapter;

  final Logger _logger = Logger('InAppReviewService');
  final SharedPreferences _prefs;
  final NotifyService _notifyService;
  final InAppReviewAdapter _adapter;

  /// App Store ID for iOS `openStoreListing()`. Read via
  /// `const String.fromEnvironment('APP_STORE_ID')`.
  @visibleForTesting
  final String appStoreId;

  /// Play Store package name. Used only by `RateAppViewModel` for fallback
  /// URL construction -- NOT by this service.
  @visibleForTesting
  final String playStorePackageName;

  bool _isInitialized = false;

  /// Whether the service was successfully initialized.
  ///
  /// Exposed for `RateAppViewModel` conditional UI and testing.
  bool get isInitialized => _isInitialized;

  /// Thresholds at which the review prompt fires (session count).
  static const thresholds = [5, 15, 35];

  /// SharedPreferences key prefix for review-request index.
  static const _indexKeyPrefix = 'review_request_index_';

  /// Configures the service.
  ///
  /// On unsupported platforms (`kIsWeb` or non-iOS/Android) it logs and
  /// returns immediately. On iOS, requires `APP_STORE_ID` -- if empty, logs
  /// a warning and keeps `_isInitialized = false`. On Android, no env config
  /// is required.
  void init() {
    // Platform guard -- in_app_review only supports iOS and Android.
    if (kIsWeb) {
      _logger.fine('InAppReview: skipping init on web');
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      _logger.fine(
        'InAppReview: skipping init on ${defaultTargetPlatform.name}',
      );
      return;
    }

    // Platform-specific config validation.
    if (defaultTargetPlatform == TargetPlatform.iOS && appStoreId.isEmpty) {
      _logger.warning('APP_STORE_ID not set -- InAppReview disabled on iOS');
      return;
    }

    _isInitialized = true;
    _logger.info('InAppReview initialized');
  }

  /// Programmatic review prompt: checks session count against thresholds,
  /// fires `requestReview()` if eligible, and increments the index.
  ///
  /// Silent on failure -- non-critical. No-op when `!isInitialized`.
  Future<void> requestReviewIfNeeded(
    int sessionCount,
    String userId,
  ) async {
    if (!_isInitialized) return;

    try {
      final indexKey = '$_indexKeyPrefix$userId';
      final currentIndex = _prefs.getInt(indexKey) ?? 0;

      // All thresholds exhausted.
      if (currentIndex >= thresholds.length) return;

      // Check if session count matches the next threshold.
      if (sessionCount < thresholds[currentIndex]) return;

      // Check availability before requesting review.
      final available = await _adapter.isAvailable();
      if (!available) {
        _logger.fine('InAppReview: not available on this device');
        return;
      }

      // TODO(analytics): track review prompt event
      await _adapter.requestReview();
      await _prefs.setInt(indexKey, currentIndex + 1);
      _logger.info(
        'Review requested at threshold ${thresholds[currentIndex]} '
        '(index $currentIndex → ${currentIndex + 1})',
      );
    } catch (e, st) {
      _logger.warning('requestReviewIfNeeded failed', e, st);
    }
  }

  /// Manual review prompt (Rate App screen): try `requestReview()`, on
  /// failure fallback to `openStoreListing()`.
  ///
  /// No-op when `!isInitialized`.
  Future<void> requestReviewForScreen() async {
    if (!_isInitialized) return;

    try {
      final available = await _adapter.isAvailable();
      if (!available) {
        await openStoreListing();
        return;
      }

      // TODO(analytics): track review prompt event
      await _adapter.requestReview();
    } catch (e, st) {
      _logger.warning('requestReviewForScreen failed, falling back', e, st);
      await openStoreListing();
    }
  }

  /// Opens the platform store listing. Passes `appStoreId` on iOS; Android
  /// auto-detected by plugin.
  ///
  /// Shows an error toast via [NotifyService] on failure.
  /// No-op when `!isInitialized`.
  Future<void> openStoreListing() async {
    if (!_isInitialized) return;

    try {
      // TODO(analytics): track store listing opened event
      final storeId =
          defaultTargetPlatform == TargetPlatform.iOS ? appStoreId : null;
      await _adapter.openStoreListing(appStoreId: storeId);
    } catch (e, st) {
      _logger.warning('openStoreListing failed', e, st);
      _notifyService.setToastEvent(
        ToastEventError(message: 'Could not open store listing'),
      );
    }
  }
}
