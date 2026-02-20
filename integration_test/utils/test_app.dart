import 'package:flutter/material.dart';
import 'package:neurostack/config/locator_config.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/l10n/app_localizations.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/best_router.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/paywall/data/revenuecat_client.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Module> buildTestModules({
  required SharedPreferences sharedPreferences,
  DataSourceAbstraction? dataSource,
  UserBootstrapService? userBootstrapService,
  ConnectivityService? connectivityService,
  RevenueCatClient? revenueCatClient,
  RevenueCatService? revenueCatService,
  UserRepository? userRepository,
}) {
  final modules = buildModules(sharedPreferences: sharedPreferences);
  final overrides = <Type, Module>{};

  if (dataSource != null) {
    overrides[DataSourceAbstraction] = Module<DataSourceAbstraction>(
      builder: () => dataSource,
      lazy: false,
    );
  }
  if (userBootstrapService != null) {
    overrides[UserBootstrapService] = Module<UserBootstrapService>(
      builder: () => userBootstrapService,
      lazy: true,
    );
  }
  if (connectivityService != null) {
    overrides[ConnectivityService] = Module<ConnectivityService>(
      builder: () => connectivityService,
      lazy: false,
    );
  }
  if (revenueCatClient != null) {
    overrides[RevenueCatClient] = Module<RevenueCatClient>(
      builder: () => revenueCatClient,
      lazy: true,
    );
  }
  if (revenueCatService != null) {
    overrides[RevenueCatService] = Module<RevenueCatService>(
      builder: () => revenueCatService,
      lazy: true,
    );
  }
  if (userRepository != null) {
    overrides[UserRepository] = Module<UserRepository>(
      builder: () => userRepository,
      lazy: true,
    );
  }

  return modules
      .map((module) => overrides[module.type] ?? module)
      .toList();
}

Future<Widget> createTestApp({
  required SharedPreferences sharedPreferences,
  DataSourceAbstraction? dataSource,
  UserBootstrapService? userBootstrapService,
  ConnectivityService? connectivityService,
  RevenueCatClient? revenueCatClient,
  RevenueCatService? revenueCatService,
  UserRepository? userRepository,
}) async {
  locator.reset();
  locator.registerMany(
    buildTestModules(
      sharedPreferences: sharedPreferences,
      dataSource: dataSource,
      userBootstrapService: userBootstrapService,
      connectivityService: connectivityService,
      revenueCatClient: revenueCatClient,
      revenueCatService: revenueCatService,
      userRepository: userRepository,
    ),
  );

  return MaterialApp.router(
    routerConfig: BestRouterConfig(routerService: locator<RouterService>()),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.buildTheme(Brightness.light),
    builder: (context, child) {
      Translate.init(context);
      return child ?? const SizedBox();
    },
  );
}
