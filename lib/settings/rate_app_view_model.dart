import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/core/utils/in_app_review/in_app_review_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for the Rate App screen.
///
/// Exposes CTA state for the view and dispatches review/store-listing actions.
/// Fallback URL construction lives here (not in [InAppReviewService]) to keep
/// the service platform-agnostic.
class RateAppViewModel {
  RateAppViewModel({
    required InAppReviewService inAppReviewService,
    required NotifyService notifyService,
    String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
    String playStorePackageName =
        const String.fromEnvironment('PLAY_STORE_PACKAGE_NAME'),
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  })  : _inAppReviewService = inAppReviewService,
        _notifyService = notifyService,
        _launch = launch ?? launchUrl,
        _resolvedStoreUrl = _buildStoreUrl(appStoreId, playStorePackageName);

  final Logger _logger = Logger('RateAppViewModel');
  final InAppReviewService _inAppReviewService;
  final NotifyService _notifyService;
  final Future<bool> Function(Uri, {LaunchMode mode}) _launch;
  final Uri? _resolvedStoreUrl;

  // ---------------------------------------------------------------------------
  // CTA state model
  // ---------------------------------------------------------------------------

  /// Native in_app_review service is available (iOS/Android only).
  bool get isServiceInitialized => _inAppReviewService.isInitialized;

  /// Fallback store URL can be constructed from env config for the current
  /// platform.
  bool get hasFallbackStoreConfig => _resolvedStoreUrl != null;

  /// Primary CTA enabled: native path OR fallback URL available.
  bool get canOpenStoreListing => isServiceInitialized || hasFallbackStoreConfig;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Opens the store listing via native service or fallback URL.
  ///
  /// Dispatch order:
  /// 1. If native service is initialized, delegate to it.
  /// 2. Else if a fallback store URL is available, launch it via url_launcher.
  /// 3. Else no-op (CTA should be disabled by the view).
  Future<void> openStoreListing() async {
    if (isServiceInitialized) {
      // TODO(analytics): track store listing opened event
      await _inAppReviewService.openStoreListing();
      return;
    }

    if (hasFallbackStoreConfig) {
      try {
        // TODO(analytics): track store listing opened event (fallback)
        final launched = await _launch(
          _resolvedStoreUrl!,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
        if (!launched) {
          _logger.warning('Fallback store URL launch returned false');
          _notifyService.setToastEvent(
            ToastEventError(message: 'Could not open store listing'),
          );
        }
      } catch (e, st) {
        _logger.warning('Fallback store URL launch failed', e, st);
        _notifyService.setToastEvent(
          ToastEventError(message: 'Could not open store listing'),
        );
      }
      return;
    }

    // No-op — CTA should be disabled.
  }

  /// Delegates to [InAppReviewService.requestReviewForScreen].
  ///
  /// No-op when the service is not initialized (button should be hidden).
  Future<void> requestReviewForScreen() async {
    if (!isServiceInitialized) return;
    // TODO(analytics): track quick rating event
    await _inAppReviewService.requestReviewForScreen();
  }

  // ---------------------------------------------------------------------------
  // Fallback URL resolution
  // ---------------------------------------------------------------------------

  /// Builds the platform-appropriate store URL at construction time.
  ///
  /// - Apple platforms (iOS, macOS): App Store URL requiring [appStoreId].
  /// - All others (Android, web, Windows, Linux, Fuchsia): Play Store URL
  ///   requiring [playStorePackageName].
  ///
  /// Returns `null` when the required config for the current platform is empty.
  static Uri? _buildStoreUrl(
    String appStoreId,
    String playStorePackageName,
  ) {
    // Web always maps to Play Store regardless of host platform, because
    // defaultTargetPlatform on web can reflect the host (e.g. iOS Safari
    // reports TargetPlatform.iOS).
    if (kIsWeb) {
      if (playStorePackageName.isEmpty) return null;
      return Uri.parse(
        'https://play.google.com/store/apps/details?id=$playStorePackageName',
      );
    }

    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (isApple) {
      if (appStoreId.isEmpty) return null;
      return Uri.parse('https://apps.apple.com/app/id$appStoreId');
    }

    // Android, Windows, Linux, Fuchsia → Play Store.
    if (playStorePackageName.isEmpty) return null;
    return Uri.parse(
      'https://play.google.com/store/apps/details?id=$playStorePackageName',
    );
  }
}
