import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:neurostack/config/locator_config.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart' as auth_state;
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/session/data/services/session_sync_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents different states of app initialization
sealed class AppState {
  const AppState();
}

class InitializingApp extends AppState {
  const InitializingApp();
}

class AppInitialized extends AppState {
  const AppInitialized();
}

class OfflineNoUserState extends AppState {
  const OfflineNoUserState();
}

class AppInitializationError extends AppState {
  final Object error;
  final StackTrace stackTrace;
  const AppInitializationError(this.error, this.stackTrace);
}

/// ViewModel responsible for handling app startup and initialization
class StartupViewModel {
  StartupViewModel({
    required SharedPreferences sharedPreferences,
    LoggingAbstraction? loggingAbstraction,
  }) : _sharedPreferences = sharedPreferences,
       _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction();

  final appStateNotifier = ValueNotifier<AppState>(const InitializingApp());

  final SharedPreferences _sharedPreferences;
  final LoggingAbstraction _loggingAbstraction;
  StreamSubscription<LogRecord>? loggingSubscription;

  Future<void> initializeApp() async {
    appStateNotifier.value = const InitializingApp();
    try {
      locator.registerMany(
        buildModules(sharedPreferences: _sharedPreferences),
      );
      loggingSubscription?.cancel();
      loggingSubscription = _loggingAbstraction.initializeLogging();
      locator<AppLifecycleService>().attachStartupViewModel(this);

      // Initialize onboarding store (runs async migration)
      final onboardingStore = locator<OnboardingStore>();
      await onboardingStore.init();

      // Set up onboarding guard for post-auth navigation
      final routerService = locator<RouterService>();
      routerService.setOnboardingGuard(() => !onboardingStore.isCompleted);

      final authService = locator<AuthService>();
      await authService.init();

      if (authService.authState.value is auth_state.OfflineNoUser) {
        appStateNotifier.value = const OfflineNoUserState();
        return;
      }

      // Initialize session sync service and trigger startup sync
      final syncService = locator<SessionSyncService>();
      syncService.init();
      unawaited(syncService.sync());

      appStateNotifier.value = const AppInitialized();

      if (routerService.shouldShowOnboarding()) {
        routerService.replaceAll([Path(name: '/onboarding')]);
      } else if (authService.authState.value is auth_state.Unauthenticated) {
        routerService.replaceAll([Path(name: '/auth')]);
      }
    } catch (e, st) {
      appStateNotifier.value = AppInitializationError(e, st);
    }
  }

  Future<void> retryInitialization() async {
    _disposeServices();
    locator.reset();
    await initializeApp();
  }

  void dispose() {
    appStateNotifier.dispose();
    loggingSubscription?.cancel();
  }

  void _disposeServices() {
    try {
      locator<SessionSyncService>().dispose();
    } catch (_) {}
    try {
      locator<AuthService>().dispose();
    } catch (_) {}
    try {
      locator<ConnectivityService>().dispose();
    } catch (_) {}
  }
}
