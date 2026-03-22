import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/utils/data_source/data_source_init.dart';

void main() {
  setUp(() {
    resetDataSourceInitGuard();
    testDataSourceInitOverride = null;
  });

  tearDown(() {
    resetDataSourceInitGuard();
    testDataSourceInitOverride = null;
  });

  group('initDataSource', () {
    test('calls the initializer and completes on success', () async {
      var callCount = 0;
      testDataSourceInitOverride = () async {
        callCount++;
      };

      await initDataSource();
      expect(callCount, 1);
    });

    test('second call after success is a no-op (returns same future)', () async {
      var callCount = 0;
      testDataSourceInitOverride = () async {
        callCount++;
      };

      await initDataSource();
      expect(callCount, 1);

      // Second call should return the cached completed future.
      await initDataSource();
      expect(callCount, 1);
    });

    test('second call after failure retries (completer resets)', () async {
      var callCount = 0;
      testDataSourceInitOverride = () async {
        callCount++;
        if (callCount == 1) {
          throw Exception('first call fails');
        }
        // Second call succeeds.
      };

      // First call fails. The completer also receives the error;
      // ignore its unhandled future to prevent zone error.
      Object? caughtError;
      await runZonedGuarded(
        () async {
          try {
            await initDataSource();
          } on Exception catch (e) {
            caughtError = e;
          }
        },
        (_, __) {
          // Ignore unhandled errors from the completer's future.
        },
      );
      expect(caughtError, isA<Exception>());
      expect(callCount, 1);

      // Guard was reset on failure, so second call retries.
      await initDataSource();
      expect(callCount, 2);
    });

    test('concurrent calls share the same future', () async {
      var callCount = 0;
      final completer = Completer<void>();

      testDataSourceInitOverride = () {
        callCount++;
        return completer.future;
      };

      // Launch two concurrent calls.
      final future1 = initDataSource();
      final future2 = initDataSource();

      // Only one initializer call should have been made.
      expect(callCount, 1);

      // Complete the shared future.
      completer.complete();
      await future1;
      await future2;

      // Still only one call.
      expect(callCount, 1);
    });

    test('concurrent calls all fail if initializer fails', () async {
      final completer = Completer<void>();

      testDataSourceInitOverride = () => completer.future;

      final future1 = initDataSource();
      final future2 = initDataSource();

      completer.completeError(Exception('shared failure'));

      await expectLater(future1, throwsA(isA<Exception>()));
      await expectLater(future2, throwsA(isA<Exception>()));
    });

    test('resetDataSourceInitGuard allows fresh init attempt', () async {
      var callCount = 0;
      testDataSourceInitOverride = () async {
        callCount++;
      };

      await initDataSource();
      expect(callCount, 1);

      // After success, second call is a no-op.
      await initDataSource();
      expect(callCount, 1);

      // Reset the guard.
      resetDataSourceInitGuard();

      // Now a fresh call should run the initializer again.
      await initDataSource();
      expect(callCount, 2);
    });
  });
}
