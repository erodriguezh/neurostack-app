import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:userorient_flutter/userorient_flutter.dart';

import '../../ui/constants/kit_colors.dart';

/// Thin wrapper around the UserOrient SDK.
///
/// ## Design
///
/// - **Synchronous init:** `init()` is synchronous -- no `Completer`, no async
///   race conditions. Both `openBoard()` and `clearCache()` guard on
///   `_isInitialized`.
/// - **Platform guard:** `init()` is a no-op on web and non-mobile platforms.
///   `_isInitialized` stays `false`, making the entire service inert.
/// - **Empty API key guard:** logs a warning and returns without crashing.
///
/// Follows the same service-wrapper pattern as `RevenueCatService`.
class UserOrientService {
  final Logger _logger = Logger('UserOrientService');

  bool _isInitialized = false;

  /// Whether the SDK was successfully initialized.
  ///
  /// Exposed for testing only -- prefer calling public methods which guard
  /// on this flag internally.
  @visibleForTesting
  bool get isInitialized => _isInitialized;

  /// Configures the UserOrient SDK.
  ///
  /// This is synchronous. On unsupported platforms (`kIsWeb` or
  /// non-iOS/Android) it logs and returns immediately. An empty API key is
  /// treated as a configuration error (warning log, early return).
  void init() {
    // Platform guard -- UserOrient only supports iOS and Android.
    if (kIsWeb) {
      _logger.fine('UserOrient: skipping init on web');
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      _logger.fine(
        'UserOrient: skipping init on ${defaultTargetPlatform.name}',
      );
      return;
    }

    // API key guard.
    const apiKey = String.fromEnvironment('USERORIENT_API_KEY');
    if (apiKey.isEmpty) {
      _logger.warning('USERORIENT_API_KEY not set -- UserOrient disabled');
      return;
    }

    // Configure SDK.
    UserOrient.configure(apiKey: apiKey);

    // Language -- must be set via setLanguage (v2.1.0 breaking change).
    UserOrient.setLanguage(Language.en);

    // Theme -- map from app palette.
    const kitColors = KitColorsExtension();
    UserOrient.setTheme(
      light: UserOrientColors(
        backgroundColor: kitColors.neutral100,
        accentColor: kitColors.neutral950,
      ),
      dark: UserOrientColors(
        backgroundColor: kitColors.background,
        accentColor: kitColors.brandSky,
      ),
    );

    _isInitialized = true;
    _logger.info('UserOrient initialized');
  }

  /// Opens the UserOrient feature-request board.
  ///
  /// No-op when the service was not initialized (e.g. web, missing key).
  void openBoard(
    BuildContext context, {
    required String userId,
    required bool isPaying,
  }) {
    if (!_isInitialized) return;

    UserOrient.setUser(uniqueIdentifier: userId, isPaying: isPaying);
    UserOrient.openBoard(context);
  }

  /// Clears all locally cached UserOrient data.
  ///
  /// Returns immediately (resolved future) when the service is not
  /// initialized, matching the fire-and-forget pattern used in `AuthService`.
  Future<void> clearCache() {
    if (!_isInitialized) return Future<void>.value();
    return UserOrient.clearCache();
  }
}
