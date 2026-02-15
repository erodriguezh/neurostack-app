import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPrefsTrialExpirationDecisionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = SharedPrefsTrialExpirationDecisionStore(prefs);
  });

  group('SharedPrefsTrialExpirationDecisionStore', () {
    group('saveLastSeenStatus / getLastSeenStatus', () {
      test('getLastSeenStatus returns null initially', () async {
        final result = await store.getLastSeenStatus('user-new');
        expect(result, isNull);
      });

      test('round-trips subscription status', () async {
        await store.saveLastSeenStatus(
          userId: 'user-status',
          status: SubscriptionStatus.trial,
        );

        final result = await store.getLastSeenStatus('user-status');
        expect(result, equals(SubscriptionStatus.trial));
      });

      test('overwrites previous status', () async {
        await store.saveLastSeenStatus(
          userId: 'user-transition',
          status: SubscriptionStatus.trial,
        );
        await store.saveLastSeenStatus(
          userId: 'user-transition',
          status: SubscriptionStatus.free,
        );

        final result = await store.getLastSeenStatus('user-transition');
        expect(result, equals(SubscriptionStatus.free));
      });

      test('different users are independent', () async {
        await store.saveLastSeenStatus(
          userId: 'user-X',
          status: SubscriptionStatus.premiumMonthly,
        );
        await store.saveLastSeenStatus(
          userId: 'user-Y',
          status: SubscriptionStatus.free,
        );

        expect(
          await store.getLastSeenStatus('user-X'),
          equals(SubscriptionStatus.premiumMonthly),
        );
        expect(
          await store.getLastSeenStatus('user-Y'),
          equals(SubscriptionStatus.free),
        );
      });

      test('returns null for unrecognized enum value', () async {
        // Simulate an old app version storing a value that no longer exists
        await prefs.setString('lastSeenEffectiveStatus:user-old', 'bogusValue');

        final result = await store.getLastSeenStatus('user-old');
        expect(result, isNull);
      });
    });
  });
}
