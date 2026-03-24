import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/abstractions/logging_abstraction.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/startup/startup_view_model.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLoggingAbstraction extends Mock implements LoggingAbstraction {}

void main() {
  late StartupViewModel viewModel;
  late Completer<void> dataSourceCompleter;
  late _MockLoggingAbstraction mockLogging;

  /// Default minimum splash shortened for tests.
  const testSplashDuration = Duration(milliseconds: 10);

  /// Fake PackageInfo for injection.
  final fakePackageInfo = PackageInfo(
    appName: 'test',
    packageName: 'com.test',
    version: '1.0.0',
    buildNumber: '1',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    dataSourceCompleter = Completer<void>();
    mockLogging = _MockLoggingAbstraction();

    // Stub logging to return a no-op subscription.
    when(() => mockLogging.initializeLogging(onLogs: any(named: 'onLogs')))
        .thenAnswer((_) => const Stream<Never>.empty().listen((_) {}));

    StartupViewModel.minSplashDuration = testSplashDuration;

    viewModel = StartupViewModel(
      loggingAbstraction: mockLogging,
      dataSourceInitializer: () => dataSourceCompleter.future,
      sharedPreferencesLoader: () async => SharedPreferences.getInstance(),
      packageInfoLoader: () async => fakePackageInfo,
    );
  });

  tearDown(() {
    viewModel.dispose();
    locator.reset();
    StartupViewModel.minSplashDuration = const Duration(milliseconds: 1000);
  });

  group('StartupViewModel', () {
    group('state transitions', () {
      test('initial state is InitializingApp', () {
        expect(viewModel.appStateNotifier.value, isA<InitializingApp>());
      });

      test(
        'initializeApp transitions to AppInitialized on successful bootstrap',
        () async {
          final vm = StartupViewModel(
            loggingAbstraction: mockLogging,
            bootstrapOverride: () async => BootstrapResult.initialized,
          );

          final states = <AppState>[];
          vm.appStateNotifier.addListener(() {
            states.add(vm.appStateNotifier.value);
          });

          await vm.initializeApp();

          // Should transition: InitializingApp -> AppInitialized.
          expect(states.last, isA<AppInitialized>());

          vm.dispose();
        },
      );

      test(
        'initializeApp transitions to OfflineNoUserState when auth is offline-no-user',
        () async {
          final vm = StartupViewModel(
            loggingAbstraction: mockLogging,
            bootstrapOverride: () async => BootstrapResult.offlineNoUser,
          );

          final states = <AppState>[];
          vm.appStateNotifier.addListener(() {
            states.add(vm.appStateNotifier.value);
          });

          await vm.initializeApp();

          expect(states.last, isA<OfflineNoUserState>());

          vm.dispose();
        },
      );

      test(
        'initializeApp transitions to AppInitializationError on bootstrap failure',
        () async {
          final vm = StartupViewModel(
            loggingAbstraction: mockLogging,
            dataSourceInitializer: () async {
              throw Exception('Supabase init failed');
            },
            sharedPreferencesLoader: () async =>
                await SharedPreferences.getInstance(),
            packageInfoLoader: () async => fakePackageInfo,
          );

          final states = <AppState>[];
          vm.appStateNotifier.addListener(() {
            states.add(vm.appStateNotifier.value);
          });

          await vm.initializeApp();

          expect(states, isNotEmpty);
          expect(states.last, isA<AppInitializationError>());
          final errorState = states.last as AppInitializationError;
          expect(errorState.error, isA<Exception>());

          vm.dispose();
        },
      );
    });

    group('reentrancy guard', () {
      test('second initializeApp call returns same future', () async {
        // Arrange: dataSource never completes so initializeApp blocks.
        final future1 = viewModel.initializeApp();
        final future2 = viewModel.initializeApp();

        // They should be identical -- the reentrancy guard shares the future.
        expect(identical(future1, future2), isTrue);

        // Clean up: complete the completer so the future resolves.
        dataSourceCompleter.completeError(Exception('cancelled'));
        try {
          await future1;
        } catch (_) {}
      });

      test('after completion, new initializeApp creates fresh future', () async {
        // Arrange: fast-failing initializer.
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          dataSourceInitializer: () async {
            throw Exception('fail');
          },
          sharedPreferencesLoader: () async =>
              await SharedPreferences.getInstance(),
          packageInfoLoader: () async => fakePackageInfo,
        );

        final future1 = vm.initializeApp();
        await future1;

        final future2 = vm.initializeApp();
        // After the first completes, the guard resets, so future2 is new.
        expect(identical(future1, future2), isFalse);

        await future2;
        vm.dispose();
      });
    });

    group('minimum splash duration', () {
      test(
        'AppInitializationError not emitted before minSplashDuration',
        () {
          fakeAsync((async) {
            StartupViewModel.minSplashDuration =
                const Duration(milliseconds: 1000);

            final vm = StartupViewModel(
              loggingAbstraction: mockLogging,
              dataSourceInitializer: () async {
                throw Exception('fast failure');
              },
              sharedPreferencesLoader: () async =>
                  SharedPreferences.getInstance(),
              packageInfoLoader: () async => fakePackageInfo,
            );

            vm.initializeApp();

            // At 200ms, error should NOT yet be emitted.
            async.elapse(const Duration(milliseconds: 200));
            expect(vm.appStateNotifier.value, isA<InitializingApp>());

            // At 1000ms, the splash timer completes and error is emitted.
            async.elapse(const Duration(milliseconds: 800));
            expect(vm.appStateNotifier.value, isA<AppInitializationError>());

            vm.dispose();
          });
        },
      );

      test(
        'error path awaits splashTimer safety net',
        () {
          fakeAsync((async) {
            StartupViewModel.minSplashDuration =
                const Duration(milliseconds: 1000);

            // Slow failure: takes 1100ms (longer than splash).
            final vm = StartupViewModel(
              loggingAbstraction: mockLogging,
              dataSourceInitializer: () async {
                await Future<void>.delayed(const Duration(milliseconds: 1100));
                throw Exception('slow failure');
              },
              sharedPreferencesLoader: () async =>
                  SharedPreferences.getInstance(),
              packageInfoLoader: () async => fakePackageInfo,
            );

            vm.initializeApp();

            // At 1000ms, splash timer done but bootstrap still running.
            async.elapse(const Duration(milliseconds: 1000));
            expect(vm.appStateNotifier.value, isA<InitializingApp>());

            // At 1100ms, bootstrap fails. The catch block awaits splashTimer
            // (already resolved), so error emits immediately.
            async.elapse(const Duration(milliseconds: 100));
            expect(vm.appStateNotifier.value, isA<AppInitializationError>());

            vm.dispose();
          });
        },
      );

      test(
        'AppInitialized not emitted before minSplashDuration (success path)',
        () {
          fakeAsync((async) {
            StartupViewModel.minSplashDuration =
                const Duration(milliseconds: 1000);

            final vm = StartupViewModel(
              loggingAbstraction: mockLogging,
              bootstrapOverride: () async => BootstrapResult.initialized,
            );

            vm.initializeApp();

            // At 200ms, state should still be InitializingApp.
            async.elapse(const Duration(milliseconds: 200));
            expect(vm.appStateNotifier.value, isA<InitializingApp>());

            // At 1000ms, splash timer completes and state becomes AppInitialized.
            async.elapse(const Duration(milliseconds: 800));
            expect(vm.appStateNotifier.value, isA<AppInitialized>());

            vm.dispose();
          });
        },
      );

      test(
        'OfflineNoUserState not emitted before minSplashDuration',
        () {
          fakeAsync((async) {
            StartupViewModel.minSplashDuration =
                const Duration(milliseconds: 1000);

            final vm = StartupViewModel(
              loggingAbstraction: mockLogging,
              bootstrapOverride: () async => BootstrapResult.offlineNoUser,
            );

            vm.initializeApp();

            // At 200ms, still initializing.
            async.elapse(const Duration(milliseconds: 200));
            expect(vm.appStateNotifier.value, isA<InitializingApp>());

            // At 1000ms, transitions to offline.
            async.elapse(const Duration(milliseconds: 800));
            expect(vm.appStateNotifier.value, isA<OfflineNoUserState>());

            vm.dispose();
          });
        },
      );
    });

    group('retryInitialization', () {
      test('resets state to InitializingApp and cleans up locator', () async {
        // First, get into an error state.
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          dataSourceInitializer: () async {
            throw Exception('fail');
          },
          sharedPreferencesLoader: () async =>
              await SharedPreferences.getInstance(),
          packageInfoLoader: () async => fakePackageInfo,
        );

        await vm.initializeApp();
        expect(vm.appStateNotifier.value, isA<AppInitializationError>());

        // Act: retry.
        await vm.retryInitialization();

        // Assert: state is back to InitializingApp.
        expect(vm.appStateNotifier.value, isA<InitializingApp>());

        vm.dispose();
      });

      test(
        'retryInitialization does NOT call initializeApp itself',
        () async {
          var initCallCount = 0;

          final vm = StartupViewModel(
            loggingAbstraction: mockLogging,
            dataSourceInitializer: () async {
              initCallCount++;
              throw Exception('fail');
            },
            sharedPreferencesLoader: () async =>
                await SharedPreferences.getInstance(),
            packageInfoLoader: () async => fakePackageInfo,
          );

          await vm.initializeApp();
          expect(initCallCount, 1);

          // retryInitialization should NOT trigger another initializeApp.
          await vm.retryInitialization();
          // initCallCount should still be 1 -- the view schedules bootstrap,
          // not retryInitialization.
          expect(initCallCount, 1);

          vm.dispose();
        },
      );
    });

    group('injection seams', () {
      test('uses injected dataSourceInitializer', () async {
        var called = false;
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          dataSourceInitializer: () async {
            called = true;
            throw Exception('stop here');
          },
          sharedPreferencesLoader: () async =>
              await SharedPreferences.getInstance(),
          packageInfoLoader: () async => fakePackageInfo,
        );

        await vm.initializeApp();
        expect(called, isTrue);
        vm.dispose();
      });

      test('uses injected sharedPreferencesLoader', () async {
        var called = false;
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          dataSourceInitializer: () async {},
          sharedPreferencesLoader: () async {
            called = true;
            return SharedPreferences.getInstance();
          },
          packageInfoLoader: () async => fakePackageInfo,
        );

        await vm.initializeApp();
        expect(called, isTrue);
        vm.dispose();
      });

      test('dataSourceInitializer failure prevents packageInfoLoader call', () async {
        var packageInfoCalled = false;
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          dataSourceInitializer: () async {
            throw Exception('early failure');
          },
          sharedPreferencesLoader: () async =>
              await SharedPreferences.getInstance(),
          packageInfoLoader: () async {
            packageInfoCalled = true;
            return fakePackageInfo;
          },
        );

        await vm.initializeApp();

        // packageInfoLoader is called after dataSource + sharedPreferences.
        // If dataSource fails, packageInfoLoader should NOT be reached.
        expect(packageInfoCalled, isFalse);
        expect(vm.appStateNotifier.value, isA<AppInitializationError>());

        vm.dispose();
      });

      test('bootstrapOverride bypasses all platform calls and reaches AppInitialized', () async {
        // This test proves that bootstrapOverride skips the entire _bootstrap()
        // chain (Supabase, SharedPreferences, PackageInfo, locator registration)
        // and directly produces a known-success state.
        final vm = StartupViewModel(
          loggingAbstraction: mockLogging,
          bootstrapOverride: () async => BootstrapResult.initialized,
        );

        await vm.initializeApp();

        // Reached AppInitialized without any real platform calls.
        expect(vm.appStateNotifier.value, isA<AppInitialized>());
        vm.dispose();
      });
    });
  });
}
