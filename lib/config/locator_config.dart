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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Feature data sources
import 'package:neurostack/features/protocol/data/data_sources/protocol_remote_data_source.dart';
import 'package:neurostack/features/session/data/data_sources/session_remote_data_source.dart';
import 'package:neurostack/features/user/data/data_sources/user_remote_data_source.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';

// Repository interfaces
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';

// Repository implementations
import 'package:neurostack/features/protocol/data/repositories/protocol_repository_impl.dart';
import 'package:neurostack/features/session/data/repositories/session_repository_impl.dart';
import 'package:neurostack/features/user/data/repositories/user_repository_impl.dart';

List<Module> buildModules({required SharedPreferences sharedPreferences}) => [
  Module<SharedPreferences>(builder: () => sharedPreferences, lazy: false),
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),
  Module<AppLifecycleService>(
    builder: () => AppLifecycleService(),
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
  Module<OnboardingStore>(
    builder: () => OnboardingStore(locator<SharedPreferences>()),
    lazy: true,
  ),

  // Feature data sources
  Module<ProtocolRemoteDataSource>(
    builder: () => ProtocolRemoteDataSource(locator<DataSourceAbstraction>()),
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
    ),
    lazy: true,
  ),
];
