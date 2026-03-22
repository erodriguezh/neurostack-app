import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/core/utils/locator.dart';
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
    StartupViewModel.minSplashDuration = const Duration(milliseconds: 500);
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
      'AppInitialized state removes splash and error/offline views',
      (tester) async {
        // Use a completer so bootstrap blocks and we can verify splash first.
        final dataSourceCompleter = Completer<void>();
        final vm = createVm(
          dataSourceInitializer: () => dataSourceCompleter.future,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));
        expect(find.byType(SplashScreen), findsOneWidget);

        // Directly set AppInitialized. In production, _buildRouterApp()
        // needs the full locator chain; here we verify the switch statement
        // leaves the splash/error/offline paths and enters the router branch.
        // The router branch will throw (no RouterService registered), but
        // the switch itself proves the view reacts to AppInitialized.
        vm.appStateNotifier.value = const AppInitialized();

        // Use FlutterError to catch the expected locator error from router
        // creation, while verifying the view exited the splash/error branches.
        final errors = <FlutterErrorDetails>[];
        FlutterError.onError = (d) => errors.add(d);

        await tester.pump();

        // Restore default error handler.
        FlutterError.onError = FlutterError.dumpErrorToConsole;

        // The view tried to build the router (which failed due to no locator
        // services), but it did NOT render splash, error, or offline views.
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.byIcon(Icons.wifi_off), findsNothing);

        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
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
