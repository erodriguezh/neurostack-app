import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/startup/startup_view_model.dart';

/// Service for managing app lifecycle state and restart functionality.
///
/// Exposes a [lifecycle] ValueNotifier that other services (e.g., SessionSyncService)
/// can listen to for app lifecycle changes like `resumed`.
///
/// When the app resumes, refreshes the RevenueCat entitlement snapshot to catch
/// subscription changes made outside the app (e.g., via App Store settings).
class AppLifecycleService {
  AppLifecycleService({required RevenueCatService revenueCatService})
    : _revenueCatService = revenueCatService;

  final RevenueCatService _revenueCatService;
  StartupViewModel? _startupViewModel;

  /// Notifies listeners of app lifecycle state changes.
  ///
  /// Initially `null` until the first lifecycle event is observed.
  /// Listen for `AppLifecycleState.resumed` to trigger sync operations.
  final ValueNotifier<AppLifecycleState?> lifecycle = ValueNotifier(null);

  void attachStartupViewModel(StartupViewModel viewModel) {
    _startupViewModel = viewModel;
  }

  /// Updates the lifecycle notifier with the current app state.
  ///
  /// Called by the lifecycle observer widget in main.dart.
  /// Also triggers RevenueCat entitlement refresh on resume to catch
  /// subscription changes made outside the app.
  void setLifecycleState(AppLifecycleState state) {
    lifecycle.value = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_revenueCatService.refreshEntitlement());
    }
  }

  Future<void> restartApp() async {
    await _startupViewModel?.retryInitialization();
  }

  /// Disposes the lifecycle notifier.
  void dispose() {
    lifecycle.dispose();
  }
}
