import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/config/locator_config.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_init.dart';
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

/// Typed result of the bootstrap sequence, used to decide routing after
/// the minimum splash display time elapses.
///
/// Visible for testing so unit tests can inject a fake bootstrap function
/// that returns a known result without needing the full DI chain.
@visibleForTesting
enum BootstrapResult {
  /// All services initialized successfully and user is reachable.
  initialized,

  /// Device is offline and no cached user session exists.
  offlineNoUser,
}

/// ViewModel responsible for handling app startup and initialization
class StartupViewModel {
  StartupViewModel({
    LoggingAbstraction? loggingAbstraction,
    @visibleForTesting Future<void> Function()? dataSourceInitializer,
    @visibleForTesting Future<SharedPreferences> Function()?
        sharedPreferencesLoader,
    @visibleForTesting Future<PackageInfo> Function()? packageInfoLoader,
    @visibleForTesting Future<BootstrapResult> Function()? bootstrapOverride,
  }) : _loggingAbstraction = loggingAbstraction ?? LoggingAbstraction(),
       _initDataSource = dataSourceInitializer ?? initDataSource,
       _getSharedPreferences =
           sharedPreferencesLoader ?? SharedPreferences.getInstance,
       _getPackageInfo = packageInfoLoader ?? PackageInfo.fromPlatform,
       _bootstrapOverride = bootstrapOverride;

  final appStateNotifier = ValueNotifier<AppState>(const InitializingApp());

  final LoggingAbstraction _loggingAbstraction;
  final Future<void> Function() _initDataSource;
  final Future<SharedPreferences> Function() _getSharedPreferences;
  final Future<PackageInfo> Function() _getPackageInfo;
  final Future<BootstrapResult> Function()? _bootstrapOverride;

  StreamSubscription<LogRecord>? loggingSubscription;

  final Logger _logger = Logger('StartupViewModel');

  /// Reentrancy guard: if `initializeApp()` is already running, concurrent
  /// callers share the same future instead of racing through registration.
  /// Without this, two post-frame callbacks could fire `initializeApp()`
  /// concurrently and `ModuleLocator.registerMany()` would throw
  /// `ModuleAlreadyRegisteredException` on duplicate types.
  Future<void>? _bootstrapFuture;

  Future<void> initializeApp() {
    _bootstrapFuture ??= _doInitializeApp().whenComplete(() {
      _bootstrapFuture = null;
    });
    return _bootstrapFuture!;
  }

  /// Minimum time the splash screen is displayed. Ensures the entrance
  /// animation (500ms) completes and the breathing glow is briefly visible
  /// before any state transition. Exposed as a field for test overrides.
  @visibleForTesting
  static Duration minSplashDuration = const Duration(milliseconds: 1000);

  Future<void> _doInitializeApp() async {
    appStateNotifier.value = const InitializingApp();

    // Start the minimum splash timer immediately — it runs in parallel with
    // _bootstrap() so the entrance animation (500ms) and breathing glow
    // (remaining ~500ms) always complete before any state transition.
    // Both success and error paths await this timer.
    final splashTimer = Future<void>.delayed(minSplashDuration);

    try {
      final results = await Future.wait<Object?>([
        _bootstrapOverride?.call() ?? _bootstrap(),
        splashTimer,
      ]);

      final result = results[0] as BootstrapResult;

      if (result == BootstrapResult.offlineNoUser) {
        appStateNotifier.value = const OfflineNoUserState();
        return;
      }

      // BootstrapResult.initialized — finish routing.
      // When bootstrapOverride is set, skip service calls (tests handle
      // their own locator state). In production, _bootstrap() has already
      // registered all modules.
      if (_bootstrapOverride == null) {
        final syncService = locator<SessionSyncService>();
        syncService.init();
        unawaited(syncService.sync());
      }

      appStateNotifier.value = const AppInitialized();

      if (_bootstrapOverride == null) {
        final routerService = locator<RouterService>();
        final authService = locator<AuthService>();
        if (routerService.shouldShowOnboarding()) {
          routerService.replaceAll([Path(name: '/onboarding')]);
        } else if (authService.authState.value is auth_state.Unauthenticated) {
          routerService.replaceAll([Path(name: '/auth')]);
        }
      }
    } catch (e, st) {
      // Ensure the splash is visible for the minimum duration even on errors.
      // Future.wait collects all errors by default (eagerError: false), but
      // since only _bootstrap() can throw, the catch fires after the timer
      // completes anyway. We still await splashTimer explicitly as a safety
      // net in case the timer future hasn't resolved yet.
      await splashTimer;
      appStateNotifier.value = AppInitializationError(e, st);
    }
  }

  /// Core bootstrap sequence: initializes all services and returns a typed
  /// result indicating whether the app is ready or offline without a user.
  Future<BootstrapResult> _bootstrap() async {
    // Phase 1: Initialize data source (Supabase) — idempotent via completer.
    await _initDataSource();

    // Phase 2: Get SharedPreferences instance.
    final sharedPreferences = await _getSharedPreferences();

    // Phase 3: Register core modules. RouterService and other
    // startup-critical modules are available immediately after this call.
    locator.registerMany(
      buildModules(sharedPreferences: sharedPreferences),
    );

    // Phase 4: Fetch PackageInfo asynchronously and register it.
    final packageInfo = await _getPackageInfo();
    locator.registerMany([
      Module<PackageInfo>(builder: () => packageInfo, lazy: false),
    ]);

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
      return BootstrapResult.offlineNoUser;
    }

    return BootstrapResult.initialized;
  }

  Future<void> retryInitialization() async {
    // Set state to InitializingApp BEFORE disposing to prevent widgets from
    // reading disposed notifiers/services during the transition window.
    // (Preserves the existing safety guard from the current code.)
    appStateNotifier.value = const InitializingApp();
    _disposeServices();
    locator.reset();
    // initializeApp() is NOT called here — the view schedules it
    // from a post-frame callback when it sees InitializingApp state.
    // This future completes immediately after cleanup. Callers like
    // AppLifecycleService.restartApp() await this to ensure cleanup
    // finishes before returning, but bootstrap runs asynchronously
    // after the next frame.
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
