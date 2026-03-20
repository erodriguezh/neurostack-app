import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/config/locator_config.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart' as auth_state;
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/session/data/services/session_sync_service.dart';
import 'package:neurostack/core/utils/userorient/userorient_service.dart';
import 'package:neurostack/core/utils/in_app_review/in_app_review_service.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    required PackageInfo packageInfo,
    LoggingAbstraction? loggingAbstraction,
  }) : _sharedPreferences = sharedPreferences,
       _packageInfo = packageInfo,
       _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction();

  final appStateNotifier = ValueNotifier<AppState>(const InitializingApp());

  final SharedPreferences _sharedPreferences;
  final PackageInfo _packageInfo;
  final LoggingAbstraction _loggingAbstraction;
  StreamSubscription<LogRecord>? loggingSubscription;

  final Logger _logger = Logger('StartupViewModel');

  Future<void> initializeApp() async {
    appStateNotifier.value = const InitializingApp();
    try {
      locator.registerMany(
        buildModules(
          sharedPreferences: _sharedPreferences,
          packageInfo: _packageInfo,
        ),
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

      // CRITICAL: Init RevenueCat FIRST (before auth rehydration triggers identify)
      // Auth rehydration may call identify() - SDK must be configured first.
      // If init() fails, identify() will gracefully degrade (log and return).
      final revenueCatService = locator<RevenueCatService>();
      try {
        await revenueCatService.init();
      } catch (e, st) {
        _logger.warning('RevenueCat init failed', e, st);
        // Continue - app works without RC, just can't show paywall
        // identify() calls will gracefully degrade (log and return)
      }

      // Init UserOrient (synchronous, best-effort — app works without it)
      try {
        locator<UserOrientService>().init();
      } catch (e, st) {
        _logger.warning('UserOrient init failed', e, st);
      }

      // Init InAppReview (synchronous, best-effort — app works without it)
      try {
        locator<InAppReviewService>().init();
      } catch (e, st) {
        _logger.warning('InAppReview init failed', e, st);
      }

      final authService = locator<AuthService>();
      await authService.init(); // This may trigger identify() via rehydration

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
    // Set state to initializing BEFORE disposing to prevent widgets from
    // reading disposed notifiers/services during the transition window
    appStateNotifier.value = const InitializingApp();
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
    try {
      locator<RevenueCatService>().dispose();
    } catch (_) {}
  }
}
