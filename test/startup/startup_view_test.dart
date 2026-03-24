import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/config/route_config.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';

import '../mocks/mock_services.dart';
import 'package:neurostack/startup/splash_screen.dart';
import 'package:neurostack/startup/startup_view.dart';
import 'package:neurostack/startup/startup_view_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLoggingAbstraction extends Mock implements LoggingAbstraction {}

void main() {
  late _MockLoggingAbstraction mockLogging;

  final fakePackageInfo = PackageInfo(
    appName: 'test',
    packageName: 'com.test',
    version: '1.0.0',
    buildNumber: '1',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockLogging = _MockLoggingAbstraction();
    when(() => mockLogging.initializeLogging(onLogs: any(named: 'onLogs')))
        .thenAnswer((_) => const Stream<Never>.empty().listen((_) {}));
    StartupViewModel.minSplashDuration = const Duration(milliseconds: 10);
  });

  tearDown(() {
    locator.reset();
    StartupViewModel.minSplashDuration = const Duration(milliseconds: 1000);
  });

  /// Creates a StartupViewModel with the given dataSourceInitializer.
  /// The widget tree owns disposal -- do NOT call vm.dispose() manually.
  StartupViewModel createVm({
    required Future<void> Function() dataSourceInitializer,
  }) {
    return StartupViewModel(
      loggingAbstraction: mockLogging,
      dataSourceInitializer: dataSourceInitializer,
      sharedPreferencesLoader: () async => SharedPreferences.getInstance(),
      packageInfoLoader: () async => fakePackageInfo,
    );
  }

  group('StartupView', () {
    testWidgets(
      'renders SplashScreen in InitializingApp state',
      (tester) async {
        final dataSourceCompleter = Completer<void>();
        final vm = createVm(
          dataSourceInitializer: () => dataSourceCompleter.future,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));

        expect(find.byType(SplashScreen), findsOneWidget);

        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'renders error view in AppInitializationError state',
      (tester) async {
        final vm = createVm(
          dataSourceInitializer: () async {
            throw Exception('init failed');
          },
        );

        await tester.pumpWidget(StartupView(viewModel: vm));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'renders offline-no-user view in OfflineNoUserState',
      (tester) async {
        final dataSourceCompleter = Completer<void>();
        final vm = createVm(
          dataSourceInitializer: () => dataSourceCompleter.future,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));
        expect(find.byType(SplashScreen), findsOneWidget);

        // Directly set the state to OfflineNoUserState.
        vm.appStateNotifier.value = const OfflineNoUserState();
        await tester.pump();

        // Should show wifi_off icon (from _OfflineNoUserView).
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        // Should have a retry button.
        expect(find.byIcon(Icons.refresh), findsOneWidget);

        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'lazy router handoff: no router during splash, router created on AppInitialized, fresh after retry',
      (tester) async {
        void registerRouterServices() {
          locator.registerMany([
            Module<RouterService>(
              builder: () => RouterService(supportedRoutes: routes),
              lazy: false,
            ),
            Module<NotifyService>(
              builder: () => NotifyService(),
              lazy: false,
            ),
            Module<ConnectivityService>(
              builder: () => MockConnectivityService(),
              lazy: false,
            ),
            Module<AuthService>(
              builder: () => MockAuthService(),
              lazy: false,
            ),
          ]);
        }

        registerRouterServices();

        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          bootstrapOverride: () async => BootstrapResult.initialized,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));

        // Phase 1: InitializingApp -- splash rendered, no routerConfig.
        expect(find.byType(SplashScreen), findsOneWidget);
        // During InitializingApp, the non-router MaterialApp is used.
        final shellApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(shellApp.routerConfig, isNull,
            reason: 'Shell app should not have routerConfig');

        // Suppress downstream errors from route widgets needing more services.
        final originalOnError = FlutterError.onError;
        addTearDown(() => FlutterError.onError = originalOnError);
        FlutterError.onError = (d) {};

        // Phase 2: AppInitialized -- router branch with lazy BestRouterConfig.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        // The MaterialApp now has a routerConfig (MaterialApp.router was used).
        final routerApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        final firstRouterConfig = routerApp.routerConfig;
        expect(firstRouterConfig, isNotNull,
            reason: 'Router app should have routerConfig (lazy creation)');

        // Phase 3: Retry -- routerConfig is invalidated and re-created.
        // retryInitialization sets InitializingApp -> view clears _routerConfig.
        await vm.retryInitialization();
        await tester.pump();

        // Back to splash -- routerConfig is null again (cleared on retry).
        expect(find.byType(SplashScreen), findsOneWidget);
        final retryShellApp =
            tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(retryShellApp.routerConfig, isNull,
            reason: 'Shell app after retry should not have routerConfig');

        // Re-register services (locator was reset by retryInitialization).
        registerRouterServices();

        // Post-frame callback re-schedules initializeApp.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        // Fresh router created with a NEW RouterService instance.
        final freshRouterApp =
            tester.widget<MaterialApp>(find.byType(MaterialApp));
        final freshRouterConfig = freshRouterApp.routerConfig;
        expect(freshRouterConfig, isNotNull,
            reason: 'Fresh router app after retry should have routerConfig');
        // Verify it's a different instance (not the stale cached one).
        expect(freshRouterConfig, isNot(same(firstRouterConfig)),
            reason: 'Router config after retry must be a fresh instance');
      },
    );

    testWidgets(
      'schedules initializeApp via post-frame callback (bootstrapScheduled guard)',
      (tester) async {
        var initCallCount = 0;
        final dataSourceCompleter = Completer<void>();

        final vm = createVm(
          dataSourceInitializer: () {
            initCallCount++;
            return dataSourceCompleter.future;
          },
        );

        await tester.pumpWidget(StartupView(viewModel: vm));

        // Post-frame callback fires during the warm-up frame in pumpWidget.
        expect(initCallCount, 1);

        // Another pump should NOT re-schedule (guard prevents it).
        await tester.pump();
        expect(initCallCount, 1);

        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'retry from error view resets to InitializingApp then re-bootstraps',
      (tester) async {
        var callCount = 0;

        final vm = createVm(
          dataSourceInitializer: () async {
            callCount++;
            throw Exception('fail #$callCount');
          },
        );

        await tester.pumpWidget(StartupView(viewModel: vm));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(callCount, 1);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(callCount, 2);
      },
    );

    testWidgets(
      'retry from offline-no-user view resets to InitializingApp',
      (tester) async {
        final dataSourceCompleter = Completer<void>();
        final vm = createVm(
          dataSourceInitializer: () => dataSourceCompleter.future,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));

        vm.appStateNotifier.value = const OfflineNoUserState();
        await tester.pump();

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);

        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'routerConfig is cleared on retry (fresh state after InitializingApp)',
      (tester) async {
        var callCount = 0;

        final vm = createVm(
          dataSourceInitializer: () async {
            callCount++;
            throw Exception('fail');
          },
        );

        await tester.pumpWidget(StartupView(viewModel: vm));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(find.byType(SplashScreen), findsOneWidget);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(callCount, 2);
      },
    );
  });
}
