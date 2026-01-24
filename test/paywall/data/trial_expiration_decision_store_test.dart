import 'package:flutter_test/flutter_test.dart';
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
    test('isResolved returns false initially', () async {
      final result = await store.isResolved(
        userId: 'user-123',
        trialStartDate: DateTime(2024, 1, 1),
      );

      expect(result, isFalse);
    });

    test('markResolved then isResolved returns true', () async {
      const userId = 'user-456';
      final trialStartDate = DateTime(2024, 2, 15, 10, 30);

      // Initially not resolved
      var result = await store.isResolved(
        userId: userId,
        trialStartDate: trialStartDate,
      );
      expect(result, isFalse);

      // Mark as resolved
      await store.markResolved(
        userId: userId,
        trialStartDate: trialStartDate,
      );

      // Now should be resolved
      result = await store.isResolved(
        userId: userId,
        trialStartDate: trialStartDate,
      );
      expect(result, isTrue);
    });

    test('different trial instances are independent', () async {
      const userId = 'user-789';
      final trialStartDate1 = DateTime(2024, 1, 1);
      final trialStartDate2 = DateTime(2024, 6, 1);

      // Mark first trial as resolved
      await store.markResolved(
        userId: userId,
        trialStartDate: trialStartDate1,
      );

      // First trial should be resolved
      final result1 = await store.isResolved(
        userId: userId,
        trialStartDate: trialStartDate1,
      );
      expect(result1, isTrue);

      // Second trial should NOT be resolved (different start date = different trial)
      final result2 = await store.isResolved(
        userId: userId,
        trialStartDate: trialStartDate2,
      );
      expect(result2, isFalse);
    });

    test('different users are independent', () async {
      final trialStartDate = DateTime(2024, 3, 1);

      // Mark user-1's decision as resolved
      await store.markResolved(
        userId: 'user-1',
        trialStartDate: trialStartDate,
      );

      // User-1 should be resolved
      final result1 = await store.isResolved(
        userId: 'user-1',
        trialStartDate: trialStartDate,
      );
      expect(result1, isTrue);

      // User-2 should NOT be resolved (different user)
      final result2 = await store.isResolved(
        userId: 'user-2',
        trialStartDate: trialStartDate,
      );
      expect(result2, isFalse);
    });

    test('key format uses UTC ISO8601 date string', () async {
      const userId = 'user-abc';
      final trialStartDate = DateTime(2024, 5, 15, 14, 30, 45);

      await store.markResolved(
        userId: userId,
        trialStartDate: trialStartDate,
      );

      // Verify the key format uses UTC by checking the underlying SharedPreferences
      final expectedKey =
          'trial_expired_resolved:$userId:${trialStartDate.toUtc().toIso8601String()}';
      expect(prefs.getBool(expectedKey), isTrue);
    });

    test('local and UTC DateTimes with same instant produce same key', () async {
      const userId = 'user-tz';
      // Create a local DateTime
      final localTime = DateTime(2024, 5, 15, 14, 30, 45);
      // Convert to UTC (same instant, different representation)
      final utcTime = localTime.toUtc();

      // Mark resolved with local time
      await store.markResolved(
        userId: userId,
        trialStartDate: localTime,
      );

      // Should be resolved when checking with UTC time (same instant)
      final result = await store.isResolved(
        userId: userId,
        trialStartDate: utcTime,
      );
      expect(result, isTrue);
    });
  });
}
