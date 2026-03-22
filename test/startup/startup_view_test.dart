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
        // Arrange: dataSource never completes so we stay in InitializingApp.
        final dataSourceCompleter = Completer<void>();
        final vm = createVm(
          dataSourceInitializer: () => dataSourceCompleter.future,
        );

        await tester.pumpWidget(StartupView(viewModel: vm));

        // The SplashScreen should be rendered immediately (InitializingApp
        // is the initial state). The post-frame callback also fires during
        // pumpWidget's warm-up frame.
        expect(find.byType(SplashScreen), findsOneWidget);

        // Clean up: complete to avoid dangling future. Then pump to settle.
        dataSourceCompleter.completeError(Exception('teardown'));
        await tester.pump(const Duration(milliseconds: 50));
        // Widget tree disposes vm -- do NOT call vm.dispose().
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
        // Pump past splash timer so the error state is emitted.
        await tester.pump(const Duration(milliseconds: 50));
        // Pump to rebuild after state change.
        await tester.pump();

        // Should show error icon.
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        // Should show retry button.
        expect(find.byIcon(Icons.refresh), findsOneWidget);
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

        // pumpWidget fires the warm-up frame which includes the post-frame
        // callback, so initializeApp is called during pumpWidget itself.
        await tester.pumpWidget(StartupView(viewModel: vm));

        // The post-frame callback fires during the warm-up frame in pumpWidget.
        expect(initCallCount, 1);

        // Another pump should NOT re-schedule (guard prevents it).
        await tester.pump();
        expect(initCallCount, 1);

        // Clean up.
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
        // Let bootstrap fail + splash timer elapse.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        // Verify we're in error state.
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(callCount, 1);

        // Tap retry button.
        await tester.tap(find.byIcon(Icons.refresh));
        // Pump to process the tap (retryInitialization sets InitializingApp).
        await tester.pump();

        // After retry, we should be back to splash (InitializingApp).
        expect(find.byType(SplashScreen), findsOneWidget);

        // Pump to fire the post-frame callback (re-schedules initializeApp).
        await tester.pump();
        // Pump past splash timer.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        // Should fail again and show error.
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(callCount, 2);
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

        // In error state.
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Retry -- triggers InitializingApp which clears _routerConfig.
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Should show splash again (routerConfig was cleared).
        expect(find.byType(SplashScreen), findsOneWidget);

        // Let second attempt fail.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();

        expect(callCount, 2);
      },
    );
  });
}
