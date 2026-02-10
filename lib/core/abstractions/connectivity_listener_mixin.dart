import 'package:flutter/foundation.dart';

import '../utils/connectivity/connectivity_service.dart';

/// Mixin that manages connectivity listener setup and teardown.
///
/// Both HomeViewModel and LibraryViewModel follow the identical pattern of:
/// 1. Lazily initializing a listener callback
/// 2. Removing any existing listener (idempotent init)
/// 3. Adding the listener
/// 4. Removing the listener on dispose
///
/// Subclasses implement [onConnectivityChanged] to define their specific
/// response to connectivity changes (e.g., toggling offline state).
mixin ConnectivityListenerMixin {
  ConnectivityService get connectivityListenerService;

  VoidCallback? _connectivityListener;

  /// Sets up the connectivity listener. Safe to call multiple times.
  void initConnectivityListener() {
    _connectivityListener ??= onConnectivityChanged;
    connectivityListenerService.status.removeListener(_connectivityListener!);
    connectivityListenerService.status.addListener(_connectivityListener!);
  }

  /// Removes the connectivity listener. Safe to call if not initialized.
  void disposeConnectivityListener() {
    if (_connectivityListener != null) {
      connectivityListenerService.status.removeListener(_connectivityListener!);
    }
  }

  /// Called when the network status changes.
  ///
  /// Subclasses must implement this to define their response
  /// (e.g., toggling offline mode, reloading data).
  void onConnectivityChanged();
}
