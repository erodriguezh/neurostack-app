import 'package:flutter/foundation.dart';

import '../../paywall/data/revenuecat_service.dart';

/// Mixin that manages RevenueCat entitlement listener setup and teardown.
///
/// Both HomeViewModel and LibraryViewModel follow the identical pattern of:
/// 1. Lazily initializing a listener callback
/// 2. Removing any existing listener (idempotent init)
/// 3. Adding the listener
/// 4. Removing the listener on dispose
///
/// Subclasses implement [onEntitlementChanged] to define their specific
/// response to entitlement changes (e.g., refreshing the view).
mixin EntitlementListenerMixin {
  RevenueCatService get entitlementListenerService;

  VoidCallback? _entitlementListener;

  /// Sets up the entitlement listener. Safe to call multiple times.
  void initEntitlementListener() {
    _entitlementListener ??= onEntitlementChanged;
    entitlementListenerService.entitlementSnapshot
        .removeListener(_entitlementListener!);
    entitlementListenerService.entitlementSnapshot
        .addListener(_entitlementListener!);
  }

  /// Removes the entitlement listener. Safe to call if not initialized.
  void disposeEntitlementListener() {
    if (_entitlementListener != null) {
      entitlementListenerService.entitlementSnapshot
          .removeListener(_entitlementListener!);
      _entitlementListener = null;
    }
  }

  /// Called when the entitlement snapshot changes.
  ///
  /// Subclasses must implement this to define their response
  /// (e.g., triggering a non-loading refresh).
  void onEntitlementChanged();
}
