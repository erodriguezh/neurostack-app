import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';

void main() {
  group('AppLifecycleService', () {
    late AppLifecycleService service;
    late bool disposed;

    setUp(() {
      service = AppLifecycleService();
      disposed = false;
    });

    tearDown(() {
      if (!disposed) {
        service.dispose();
      }
    });

    group('lifecycle ValueNotifier', () {
      test('initial value is null', () {
        expect(service.lifecycle.value, isNull);
      });

      test('setLifecycleState updates lifecycle value', () {
        service.setLifecycleState(AppLifecycleState.resumed);

        expect(service.lifecycle.value, AppLifecycleState.resumed);
      });

      test('setLifecycleState notifies listeners', () {
        final states = <AppLifecycleState?>[];
        service.lifecycle.addListener(() {
          states.add(service.lifecycle.value);
        });

        service.setLifecycleState(AppLifecycleState.paused);
        service.setLifecycleState(AppLifecycleState.resumed);
        service.setLifecycleState(AppLifecycleState.inactive);

        expect(states, [
          AppLifecycleState.paused,
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
        ]);
      });

      test('setLifecycleState handles all AppLifecycleState values', () {
        for (final state in AppLifecycleState.values) {
          service.setLifecycleState(state);
          expect(service.lifecycle.value, state);
        }
      });
    });

    group('dispose', () {
      test('disposes the lifecycle ValueNotifier', () {
        disposed = true;
        service.dispose();

        // Attempting to add listener after dispose should throw
        expect(
          () => service.lifecycle.addListener(() {}),
          throwsA(isA<FlutterError>()),
        );
      });
    });
  });
}
