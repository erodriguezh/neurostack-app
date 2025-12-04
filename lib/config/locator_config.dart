import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/http/http_abstraction.dart';
import 'package:neurostack/core/utils/http/http_interceptor.dart';
import 'package:neurostack/config/route_config.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';

// Feature data sources
import 'package:neurostack/features/protocol/data/data_sources/protocol_remote_data_source.dart';
import 'package:neurostack/features/session/data/data_sources/session_remote_data_source.dart';
import 'package:neurostack/features/user/data/data_sources/user_remote_data_source.dart';

// Repository interfaces
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';

// Repository implementations
import 'package:neurostack/features/protocol/data/repositories/protocol_repository_impl.dart';
import 'package:neurostack/features/session/data/repositories/session_repository_impl.dart';
import 'package:neurostack/features/user/data/repositories/user_repository_impl.dart';

final modules = [
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),
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
];
