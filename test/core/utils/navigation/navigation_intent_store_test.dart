import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationIntentStore', () {
    late NavigationIntentStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = NavigationIntentStore(prefs);
    });

    test('isEligibleIntendedRoute_withBlockedPaths_returnsFalse', () {
      expect(store.isEligibleIntendedRoute('/auth'), isFalse);
      expect(store.isEligibleIntendedRoute('/auth?foo=bar'), isFalse);
      expect(store.isEligibleIntendedRoute('/auth/callback'), isFalse);
      expect(store.isEligibleIntendedRoute('/auth/check-email'), isFalse);
      expect(store.isEligibleIntendedRoute('/onboarding'), isFalse);
      expect(store.isEligibleIntendedRoute('/offline'), isFalse);
      expect(store.isEligibleIntendedRoute('/404'), isFalse);
    });

    test('isEligibleIntendedRoute_withOtherPath_returnsTrue', () {
      expect(store.isEligibleIntendedRoute('/details?foo=bar'), isTrue);
    });

    test(
      'saveIntendedRouteIfEligible_withIneligibleRoute_doesNotOverwrite',
      () async {
        await store.saveIntendedRoute('/details?prev=true');
        await store.saveIntendedRouteIfEligible('/auth');

        expect(store.getIntendedRoute(), '/details?prev=true');
      },
    );

    test(
      'saveIntendedRouteIfEligible_withOverwriteFalse_keepsExisting',
      () async {
        await store.saveIntendedRoute('/details?prev=true');
        await store.saveIntendedRouteIfEligible(
          '/details?new=true',
          overwrite: false,
        );

        expect(store.getIntendedRoute(), '/details?prev=true');
      },
    );

    test('consumeIntendedRoute_withExisting_clearsAndReturns', () async {
      await store.saveIntendedRoute('/details?from=link');

      final route = await store.consumeIntendedRoute();

      expect(route, '/details?from=link');
      expect(store.getIntendedRoute(), isNull);
    });
  });
}
