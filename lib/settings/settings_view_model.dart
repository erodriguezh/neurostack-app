import 'package:flutter/foundation.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';

/// Result of a restore purchases operation.
enum RestoreResult {
  /// Restore completed successfully.
  success,

  /// Restore failed (SDK error, not configured, not identified, etc.).
  failure,

  /// Restore is already in progress - request was ignored.
  alreadyInProgress,
}

/// ViewModel for SettingsView.
///
/// Handles restore purchases functionality by delegating to [RevenueCatService].
class SettingsViewModel {
  SettingsViewModel({required RevenueCatService revenueCatService})
      : _revenueCatService = revenueCatService;

  final RevenueCatService _revenueCatService;

  final ValueNotifier<bool> isRestoring = ValueNotifier<bool>(false);

  /// Restores purchases from the App Store / Play Store.
  ///
  /// This is critical for subscription correctness after:
  /// - Device change
  /// - App reinstall
  /// - Family sharing setup
  ///
  /// Returns [RestoreResult] indicating the outcome:
  /// - [RestoreResult.success] - restore completed successfully
  /// - [RestoreResult.failure] - restore failed (show error message)
  /// - [RestoreResult.alreadyInProgress] - ignore (no feedback needed)
  Future<RestoreResult> restorePurchases() async {
    // If already restoring, return "in progress" so caller can ignore
    // (no SnackBar needed since first request will complete and show feedback)
    if (isRestoring.value) return RestoreResult.alreadyInProgress;

    isRestoring.value = true;
    try {
      final success = await _revenueCatService.restorePurchases();
      return success ? RestoreResult.success : RestoreResult.failure;
    } catch (e) {
      // StateError from _ensureInitStarted() or other unexpected errors
      return RestoreResult.failure;
    } finally {
      isRestoring.value = false;
    }
  }

  void dispose() {
    isRestoring.dispose();
  }
}
