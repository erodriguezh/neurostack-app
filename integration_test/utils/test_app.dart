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
import 'package:shared_preferences/shared_preferences.dart';

List<Module> buildTestModules({
  required SharedPreferences sharedPreferences,
  DataSourceAbstraction? dataSource,
  UserBootstrapService? userBootstrapService,
  ConnectivityService? connectivityService,
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

  return modules
      .map((module) => overrides[module.type] ?? module)
      .toList();
}

Future<Widget> createTestApp({
  required SharedPreferences sharedPreferences,
  DataSourceAbstraction? dataSource,
  UserBootstrapService? userBootstrapService,
  ConnectivityService? connectivityService,
}) async {
  locator.reset();
  locator.registerMany(
    buildTestModules(
      sharedPreferences: sharedPreferences,
      dataSource: dataSource,
      userBootstrapService: userBootstrapService,
      connectivityService: connectivityService,
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
