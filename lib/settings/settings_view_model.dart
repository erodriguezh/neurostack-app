import 'package:flutter/foundation.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';

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
  /// Returns true if restore completed without errors, false otherwise.
  /// The caller should show appropriate feedback via SnackBar.
  Future<bool> restorePurchases() async {
    if (isRestoring.value) return false;

    isRestoring.value = true;
    try {
      await _revenueCatService.restorePurchases();
      return true;
    } catch (e) {
      return false;
    } finally {
      isRestoring.value = false;
    }
  }

  void dispose() {
    isRestoring.dispose();
  }
}
