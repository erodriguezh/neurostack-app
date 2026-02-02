import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../domain/entitlement_snapshot.dart';
import 'revenuecat_client.dart';

/// High-level wrapper around [RevenueCatClient] that manages SDK initialization,
/// user identification, entitlement state, and paywall presentation.
///
/// ## Design Principles
///
/// - **Constructor injection:** Receives [RevenueCatClient] via constructor (not locator<>)
/// - **Unknown vs None:** Uses nullable [ValueNotifier<EntitlementSnapshot?>] to distinguish:
///   - `null` = RC unavailable (web stub, not yet initialized)
///   - `EntitlementSnapshot` = known state (may be `.none()` = no entitlement)
/// - **Idempotent init:** Safe to call multiple times, subsequent calls return same future
/// - **Never clobber known state:** Don't overwrite known entitlement with transient null/error
///
/// ## Init Flow
///
/// 1. [init] must complete before [identify], [logout], [presentPaywall], [refreshEntitlement]
/// 2. [init] uses `_initStarted` guard + [Completer<void>] pattern for idempotency
/// 3. SDK listener subscription happens during [init]
///
/// ## Identify/Logout
///
/// - [identify] queues until [init] completes (prevents race conditions)
/// - Seeds initial snapshot via [refreshEntitlement] after identify
/// - [logout] clears `_identifiedUserId` and sets snapshot to `null`
///
/// ## Paywall Presentation
///
/// - [presentPaywall] gates on: init completion, user identification, not already presenting
/// - Refreshes entitlement after paywall closes
class RevenueCatService {
  RevenueCatService(this._client)
      : entitlementSnapshot = ValueNotifier<EntitlementSnapshot?>(null);

  final RevenueCatClient _client;

  /// Current entitlement state.
  ///
  /// - `null` = unknown (RC unavailable, not yet initialized, or logged out)
  /// - [EntitlementSnapshot] = known state (may be `.none()` = no entitlement)
  final ValueNotifier<EntitlementSnapshot?> entitlementSnapshot;

  /// Logger for debugging.
  final Logger _logger = Logger('RevenueCatService');

  /// Guard against concurrent paywall presentations.
  bool _isPresenting = false;

  /// Idempotency guard for [init].
  bool _initStarted = false;

  /// Completer for [init] to allow other methods to wait for initialization.
  final Completer<void> _initCompleter = Completer<void>();

  /// Currently identified user ID. Used to filter listener emissions.
  String? _identifiedUserId;

  /// Subscription to client's entitlement changes stream.
  StreamSubscription<EntitlementSnapshot>? _entitlementSubscription;

  /// Ensures init() has been called. Throws [StateError] if not.
  ///
  /// This prevents silent deadlocks when callers forget to call init().
  void _ensureInitStarted() {
    if (!_initStarted) {
      throw StateError(
        'RevenueCatService.init() must be called before using this method. '
        'Ensure init() is called during app startup.',
      );
    }
  }

  /// Initializes the RevenueCat SDK.
  ///
  /// Safe to call multiple times - subsequent calls return the same future.
  /// This method:
  /// 1. Selects platform-appropriate API key
  /// 2. Configures the SDK
  /// 3. Subscribes to entitlement changes
  ///
  /// CRITICAL: Must complete before [identify], [logout], [presentPaywall], or
  /// [refreshEntitlement] can succeed.
  Future<void> init() async {
    // CRITICAL: Idempotency - don't double-subscribe or double-complete
    if (_initStarted) {
      return _initCompleter.future;
    }
    _initStarted = true;

    try {
      // 1. Select platform-appropriate API key
      final apiKey = _selectPlatformKey();

      // 2. Configure SDK (MUST complete before anything else)
      await _client.configure(apiKey);

      // 3. Subscribe to entitlement changes for real-time UI updates
      // CRITICAL: Only update if for identified user (ignore anonymous emissions)
      _entitlementSubscription = _client.entitlementChanges.listen((snapshot) {
        if (_identifiedUserId != null &&
            snapshot.appUserId == _identifiedUserId) {
          _updateSnapshotIfBetter(snapshot);
        }
      });

      // 4. ONLY complete after configure() succeeds
      _initCompleter.complete();
      _logger.info('RevenueCatService initialized');
    } catch (e, st) {
      _logger.severe('RevenueCatService init failed', e, st);
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, st);
        // Prevent "unhandled error" reports by attaching an empty error handler.
        // Actual errors are propagated via rethrow below.
        // ignore: unawaited_futures
        _initCompleter.future.catchError((_) {});
      }
      rethrow;
    }
  }

  /// Selects the platform-appropriate RevenueCat API key.
  ///
  /// API keys are configured per-platform in env.json:
  /// - iOS: REVENUECAT_API_KEY (or REVENUECAT_IOS_KEY if available)
  /// - Android: REVENUECAT_API_KEY (or REVENUECAT_ANDROID_KEY if available)
  /// - macOS: REVENUECAT_API_KEY (or REVENUECAT_MACOS_KEY if available)
  ///
  /// For now, uses the single REVENUECAT_API_KEY. Per-platform keys can be
  /// added later if needed.
  String _selectPlatformKey() {
    // NOTE: The env.json currently has a single REVENUECAT_API_KEY.
    // When per-platform keys are needed, update env.json and this method:
    //
    // if (Platform.isIOS) {
    //   return const String.fromEnvironment('REVENUECAT_IOS_KEY',
    //       defaultValue: String.fromEnvironment('REVENUECAT_API_KEY'));
    // }
    // if (Platform.isAndroid) {
    //   return const String.fromEnvironment('REVENUECAT_ANDROID_KEY',
    //       defaultValue: String.fromEnvironment('REVENUECAT_API_KEY'));
    // }
    // if (Platform.isMacOS) {
    //   return const String.fromEnvironment('REVENUECAT_MACOS_KEY',
    //       defaultValue: String.fromEnvironment('REVENUECAT_API_KEY'));
    // }

    const apiKey = String.fromEnvironment('REVENUECAT_API_KEY');
    if (apiKey.isEmpty) {
      _logger.warning(
        'REVENUECAT_API_KEY not set. Running on $_platformName.',
      );
    }
    return apiKey;
  }

  /// Returns the current platform name for logging.
  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// Identifies the user with RevenueCat.
  ///
  /// This method is fully non-fatal - it logs and returns on any failure,
  /// allowing the app to continue without RevenueCat functionality.
  ///
  /// If [init] was never called, throws [StateError].
  /// All other failures (init failed, SDK errors, network errors) are logged
  /// and the method returns gracefully.
  ///
  /// CRITICAL: Must be called after user authenticates. The [userId] should
  /// match the Supabase `auth.uid` to ensure consistency (INV-P5).
  Future<void> identify(String userId) async {
    _ensureInitStarted();

    // Wait for SDK to be configured, but gracefully degrade if init failed
    try {
      await _initCompleter.future;
    } catch (e, st) {
      _logger.warning('identify skipped: SDK init failed', e, st);
      return;
    }

    // Best-effort identify - log and return on any failure
    try {
      await _client.logIn(userId);
      _identifiedUserId = userId;
      _logger.fine('Identified user: $userId');

      // Seed initial snapshot after identify (don't rely on stream)
      await refreshEntitlement();
    } catch (e, st) {
      _logger.warning('identify failed', e, st);
      // Don't rethrow - RC is optional, app should continue
    }
  }

  /// Logs out the current user from RevenueCat.
  ///
  /// Always clears local state (snapshot, identified user) regardless of SDK state.
  /// SDK logout is best-effort - app sign-out should not be blocked by SDK issues.
  ///
  /// Throws [StateError] if [init] has not been called.
  Future<void> logout() async {
    _ensureInitStarted();

    // CRITICAL: Always clear local state first, regardless of SDK state
    // This ensures app-level sign-out is never blocked by SDK issues
    _identifiedUserId = null;
    entitlementSnapshot.value = null;

    // SDK logout is best-effort - don't block app sign-out flow
    try {
      await _initCompleter.future;
      await _client.logOut();
      _logger.fine('Logged out');
    } catch (e) {
      _logger.warning('SDK logout failed (state already cleared): $e');
    }
  }

  /// Presents the RevenueCat paywall UI.
  ///
  /// Gates on:
  /// 1. Init started and completed (SDK must be configured)
  /// 2. User identification (purchasing as anonymous can cause issues)
  /// 3. Not already presenting (prevent duplicate paywall UI)
  ///
  /// Refreshes entitlement after paywall closes.
  ///
  /// Returns:
  /// - [PaywallOutcome.purchased] if user completed a purchase
  /// - [PaywallOutcome.cancelled] if user dismissed without purchasing
  /// - [PaywallOutcome.error] if presentation failed (not initialized, not identified, SDK error, etc.)
  Future<PaywallOutcome> presentPaywall() async {
    // Fail fast if init() was never called
    if (!_initStarted) {
      _logger.warning('presentPaywall called but init() was never called');
      return PaywallOutcome.error;
    }

    // Wait for init (or fail if init failed)
    try {
      await _initCompleter.future;
    } catch (_) {
      _logger.warning('presentPaywall called but SDK configuration failed');
      return PaywallOutcome.error; // SDK not configured
    }

    // CRITICAL: Must be identified before purchasing
    if (_identifiedUserId == null) {
      _logger.warning('presentPaywall called but no user identified');
      return PaywallOutcome.error; // Not identified, can't purchase safely
    }

    // Guard against multiple presentations
    if (_isPresenting) {
      _logger.fine('Paywall already presenting, returning cancelled');
      return PaywallOutcome.cancelled;
    }

    _isPresenting = true;
    try {
      final result = await _client.presentPaywall();
      _logger.fine('Paywall result: $result');

      // Refresh entitlement after paywall closes
      await refreshEntitlement();
      return result;
    } catch (e, st) {
      _logger.warning('presentPaywall failed', e, st);
      return PaywallOutcome.error;
    } finally {
      _isPresenting = false;
    }
  }

  /// Refreshes the entitlement snapshot from RevenueCat.
  ///
  /// Gates on init. Swallows all exceptions - safe for lifecycle callbacks.
  /// Never clobbers known state with null (transient failures).
  ///
  /// Note: Unlike other methods, this does NOT throw if init() hasn't been called.
  /// It silently returns to remain safe for lifecycle callbacks (e.g., app resume).
  Future<void> refreshEntitlement() async {
    if (!_initStarted) {
      _logger.fine('refreshEntitlement called before init(), ignoring');
      return;
    }
    try {
      await _initCompleter.future;
      final newSnapshot = await _client.getEntitlementSnapshot();
      _updateSnapshotIfBetter(newSnapshot); // Only update if non-null
    } catch (e) {
      // Swallow exceptions - lifecycle refresh must never crash/spam errors
      _logger.fine('refreshEntitlement failed: $e');
    }
  }

  /// Restores purchases from the App Store / Play Store.
  ///
  /// CRITICAL for subscription correctness after:
  /// - Device change
  /// - App reinstall
  /// - Family sharing setup
  ///
  /// This is the #1 subscription correctness issue after launch.
  /// Must be exposed in Settings UI as "Restore Purchases" action.
  ///
  /// Returns `true` if restore completed successfully, `false` otherwise.
  /// Common failure reasons:
  /// - init() was never called (throws [StateError])
  /// - SDK configuration failed
  /// - User not identified
  /// - SDK restore operation failed
  ///
  /// Throws [StateError] if [init] has not been called.
  Future<bool> restorePurchases() async {
    _ensureInitStarted();
    try {
      await _initCompleter.future;
    } catch (_) {
      _logger.warning('restorePurchases called but SDK configuration failed');
      return false; // SDK not configured
    }

    if (_identifiedUserId == null) {
      _logger.warning('restorePurchases called but no user identified');
      return false; // Must be identified
    }

    try {
      await _client.restorePurchases();
      await refreshEntitlement();
      _logger.fine('Purchases restored');
      return true;
    } catch (e, st) {
      _logger.warning('restorePurchases failed', e, st);
      return false;
    }
  }

  /// Disposes the service and cleans up resources.
  ///
  /// Call on app shutdown or when the service is no longer needed.
  void dispose() {
    _entitlementSubscription?.cancel();
    _entitlementSubscription = null;
    entitlementSnapshot.dispose();
    _logger.info('RevenueCatService disposed');
  }

  /// Updates the snapshot only if the new value is non-null.
  ///
  /// CRITICAL: Never clobber known state with null/error.
  /// If [newSnapshot] is null, keep existing (don't downgrade known -> unknown).
  void _updateSnapshotIfBetter(EntitlementSnapshot? newSnapshot) {
    if (newSnapshot != null) {
      entitlementSnapshot.value = newSnapshot;
    }
    // If newSnapshot is null, keep existing (don't downgrade known -> unknown)
  }
}
