import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/http/http_abstraction.dart';
import 'package:neurostack/core/utils/http/http_interceptor.dart';
import 'package:neurostack/config/route_config.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Feature data sources
import 'package:neurostack/features/protocol/data/data_sources/protocol_remote_data_source.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/data/data_sources/session_remote_data_source.dart';
import 'package:neurostack/features/user/data/data_sources/user_remote_data_source.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/protocol/data/cached_protocol_store.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';
import 'package:neurostack/paywall/data/trial_reminder_service.dart';
import 'package:neurostack/progress/data/cached_week_progress_store.dart';

// Repository interfaces
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';

// Repository implementations
import 'package:neurostack/features/protocol/data/repositories/protocol_repository_impl.dart';
import 'package:neurostack/features/session/data/repositories/session_repository_impl.dart';
import 'package:neurostack/features/user/data/repositories/user_repository_impl.dart';

// Services
import 'package:neurostack/features/session/data/services/session_sync_service.dart';

// RevenueCat
import 'package:neurostack/paywall/data/revenuecat_client.dart';
import 'package:neurostack/paywall/data/revenuecat_client_factory.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

// UserOrient
import 'package:neurostack/core/utils/userorient/userorient_service.dart';

// InAppReview
import 'package:neurostack/core/utils/in_app_review/in_app_review_adapter.dart';
import 'package:neurostack/core/utils/in_app_review/in_app_review_service.dart';
import 'package:neurostack/core/utils/in_app_review/review_trigger_helper.dart';

// Use cases
import 'package:neurostack/features/session/domain/use_cases/check_eligibility_use_case.dart';

List<Module> buildModules({
  required SharedPreferences sharedPreferences,
  required PackageInfo packageInfo,
}) => [
  Module<SharedPreferences>(builder: () => sharedPreferences, lazy: false),
  Module<PackageInfo>(builder: () => packageInfo, lazy: false),
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),

  // RevenueCat (SINGLETONS - must be app-lifetime to prevent duplicate SDK listeners)
  // Registered before AppLifecycleService which depends on RevenueCatService.
  Module<RevenueCatClient>(
    builder: () => createRevenueCatClient(),
    lazy: true,
  ),
  Module<RevenueCatService>(
    builder: () => RevenueCatService(locator<RevenueCatClient>()),
    lazy: true,
  ),

  // UserOrient (lazy singleton — no disposable resources)
  Module<UserOrientService>(
    builder: () => UserOrientService(),
    lazy: true,
  ),

  // InAppReview (lazy singleton — no disposable resources)
  Module<InAppReviewService>(
    builder: () => InAppReviewService(
      prefs: locator<SharedPreferences>(),
      notifyService: locator<NotifyService>(),
      adapter: DefaultInAppReviewAdapter(),
    ),
    lazy: true,
  ),
  Module<ReviewTriggerHelper>(
    builder: () => ReviewTriggerHelper(
      sessionLocalDataSource: locator<SessionLocalDataSource>(),
      inAppReviewService: locator<InAppReviewService>(),
    ),
    lazy: true,
  ),

  Module<AppLifecycleService>(
    builder: () => AppLifecycleService(
      revenueCatService: locator<RevenueCatService>(),
    ),
    lazy: false,
  ),
  Module<ConnectivityService>(
    builder: () => ConnectivityService(Connectivity()),
    lazy: false,
  ),
  Module<HttpAbstraction>(
    builder: () => HttpAbstraction(
      interceptors: [
        LoggingInterceptor(
          logBody: !kReleaseMode, // Only log bodies in debug mode
        ),
      ],
    ),
    lazy: true,
  ),
  Module<DataSourceAbstraction>(
    builder: () => DataSourceAbstraction.instance(),
    lazy: true,
  ),
  Module<NavigationIntentStore>(
    builder: () => NavigationIntentStore(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<CachedUserStore>(
    builder: () => CachedUserStore(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<CachedProtocolStore>(
    builder: () => CachedProtocolStore(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<CachedWeekProgressStore>(
    builder: () => CachedWeekProgressStore(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<OnboardingStore>(
    builder: () => OnboardingStore(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<TrialExpirationDecisionStore>(
    builder: () =>
        SharedPrefsTrialExpirationDecisionStore(locator<SharedPreferences>()),
    lazy: true,
  ),

  // Subscription resolver (centralized policy for UI gating)
  Module<SubscriptionStatusResolver>(
    builder: () => const SubscriptionStatusResolver(),
    lazy: true,
  ),

  // Trial reminder throttle (once per 24h per user)
  Module<TrialReminderService>(
    builder: () => TrialReminderService(
      sharedPreferences: locator<SharedPreferences>(),
      resolver: locator<SubscriptionStatusResolver>(),
    ),
    lazy: true,
  ),

  // Feature data sources
  Module<ProtocolRemoteDataSource>(
    builder: () => ProtocolRemoteDataSource(locator<DataSourceAbstraction>()),
    lazy: true,
  ),
  Module<SessionLocalDataSource>(
    builder: () => SessionLocalDataSource(locator<SharedPreferences>()),
    lazy: true,
  ),
  Module<SessionRemoteDataSource>(
    builder: () => SessionRemoteDataSource(locator<DataSourceAbstraction>()),
    lazy: true,
  ),
  Module<UserRemoteDataSource>(
    builder: () => UserRemoteDataSource(locator<DataSourceAbstraction>()),
    lazy: true,
  ),

  // Repositories
  Module<ProtocolRepository>(
    builder: () => ProtocolRepositoryImpl(locator<ProtocolRemoteDataSource>()),
    lazy: true,
  ),
  Module<SessionRepository>(
    builder: () => SessionRepositoryImpl(
      locator<SessionRemoteDataSource>(),
      locator<DataSourceAbstraction>(),
    ),
    lazy: true,
  ),
  Module<UserRepository>(
    builder: () => UserRepositoryImpl(locator<UserRemoteDataSource>()),
    lazy: true,
  ),
  Module<UserBootstrapService>(
    builder: () => UserBootstrapService(
      locator<UserRepository>(),
      locator<UserRemoteDataSource>(),
      locator<DataSourceAbstraction>(),
    ),
    lazy: true,
  ),
  Module<AuthService>(
    builder: () => AuthService(
      dataSource: locator<DataSourceAbstraction>(),
      userBootstrapService: locator<UserBootstrapService>(),
      navigationIntentStore: locator<NavigationIntentStore>(),
      cachedUserStore: locator<CachedUserStore>(),
      routerService: locator<RouterService>(),
      connectivityService: locator<ConnectivityService>(),
      appLifecycleService: locator<AppLifecycleService>(),
      revenueCatService: locator<RevenueCatService>(),
      userOrientService: locator<UserOrientService>(),
    ),
    lazy: true,
  ),

  // Services
  Module<SessionSyncService>(
    builder: () => SessionSyncService(
      local: locator<SessionLocalDataSource>(),
      remote: locator<SessionRemoteDataSource>(),
      connectivity: locator<ConnectivityService>(),
      dataSource: locator<DataSourceAbstraction>(),
      appLifecycle: locator<AppLifecycleService>(),
    ),
    lazy: true,
  ),

  // Use cases
  Module<CheckEligibilityUseCase>(
    builder: () => CheckEligibilityUseCase(
      userRepository: locator<UserRepository>(),
    ),
    lazy: true,
  ),
];
