import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';

import '../../mocks/mock_services.dart';

void main() {
  group('AppLifecycleService', () {
    late AppLifecycleService service;
    late MockRevenueCatService mockRevenueCatService;
    late bool disposed;

    setUp(() {
      mockRevenueCatService = MockRevenueCatService();
      when(
        () => mockRevenueCatService.refreshEntitlement(),
      ).thenAnswer((_) async {});
      service = AppLifecycleService(
        revenueCatService: mockRevenueCatService,
      );
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

    group('RevenueCat refresh on resume', () {
      test('calls refreshEntitlement when lifecycle changes to resumed', () {
        service.setLifecycleState(AppLifecycleState.resumed);

        verify(() => mockRevenueCatService.refreshEntitlement()).called(1);
      });

      test('does not call refreshEntitlement for non-resumed states', () {
        service.setLifecycleState(AppLifecycleState.paused);
        service.setLifecycleState(AppLifecycleState.inactive);
        service.setLifecycleState(AppLifecycleState.detached);

        verifyNever(() => mockRevenueCatService.refreshEntitlement());
      });

      test('calls refreshEntitlement each time app resumes', () {
        service.setLifecycleState(AppLifecycleState.paused);
        service.setLifecycleState(AppLifecycleState.resumed);
        service.setLifecycleState(AppLifecycleState.paused);
        service.setLifecycleState(AppLifecycleState.resumed);

        verify(() => mockRevenueCatService.refreshEntitlement()).called(2);
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

      test('does not call refreshEntitlement after dispose', () {
        disposed = true;
        service.dispose();

        // After dispose, the lifecycle notifier is disposed so we can't
        // set state on it. The listener was removed before dispose.
        // This test verifies no refresh calls happened during dispose.
        verifyNever(() => mockRevenueCatService.refreshEntitlement());
      });
    });
  });
}
