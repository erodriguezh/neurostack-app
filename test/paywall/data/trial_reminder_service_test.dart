import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/paywall/data/trial_reminder_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/paywall/domain/trial_expiry_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../factories/entitlement_snapshot_factory.dart';

void main() {
  late SharedPreferences prefs;
  late SubscriptionStatusResolver resolver;
  late TrialExpiryPolicy trialExpiryPolicy;
  late TrialReminderService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    resolver = const SubscriptionStatusResolver();
    trialExpiryPolicy = TrialExpiryPolicy(resolver: resolver);
    service = TrialReminderService(
      sharedPreferences: prefs,
      trialExpiryPolicy: trialExpiryPolicy,
    );
  });

  /// Creates a snapshot that looks like an active trial expiring at
  /// [expiresAt].
  EntitlementSnapshot trialSnapshot({
    required DateTime expiresAt,
    String userId = 'user-1',
  }) {
    return EntitlementSnapshotFactory.activeTrial(
      userId: userId,
      expirationDate: expiresAt,
    );
  }

  group('TrialReminderService', () {
    group('shouldShowTrialReminder', () {
      test(
        'returns true when in expiration window and never shown before',
        () async {
          final now = DateTime(2025, 6, 15, 12, 0, 0);
          final expiresAt = now.add(const Duration(hours: 12));
          final snapshot = trialSnapshot(expiresAt: expiresAt);

          final result = await service.shouldShowTrialReminder(
            userId: 'user-1',
            snapshot: snapshot,
            now: now,
          );

          expect(result, isTrue);
        },
      );

      test('returns false when not in expiration window (>24h away)', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 48));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });

      test('returns false when snapshot is null', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: null,
          now: now,
        );

        expect(result, isFalse);
      });

      test('returns false when shown within last 24 hours', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        // Mark as shown 6 hours ago
        final shownAt = now.subtract(const Duration(hours: 6));
        await service.markReminderShown(userId: 'user-1', now: shownAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });

      test('returns true when shown more than 24 hours ago', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        // Mark as shown 25 hours ago
        final shownAt = now.subtract(const Duration(hours: 25));
        await service.markReminderShown(userId: 'user-1', now: shownAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isTrue);
      });

      test('returns true when shown exactly 24 hours ago', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        // Mark as shown exactly 24 hours ago
        final shownAt = now.subtract(const Duration(hours: 24));
        await service.markReminderShown(userId: 'user-1', now: shownAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        // 24h has elapsed, so it should show again
        expect(result, isTrue);
      });

      test('returns false when trial already expired', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.subtract(const Duration(hours: 1));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });

      test('returns false when snapshot belongs to a different user', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        // Snapshot belongs to user-other, but we query for user-1
        final snapshot = trialSnapshot(
          expiresAt: expiresAt,
          userId: 'user-other',
        );

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });

      test('returns false when not in trial period', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));

        // Active paid subscription, not trial
        final snapshot = EntitlementSnapshotFactory.activePaidMonthly(
          userId: 'user-1',
          expirationDate: expiresAt,
        );

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isFalse);
      });
    });

    group('user isolation', () {
      test('throttle is per-user', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        final snapshot1 = trialSnapshot(expiresAt: expiresAt, userId: 'user-A');
        final snapshot2 = trialSnapshot(expiresAt: expiresAt, userId: 'user-B');

        // Mark user-A as shown recently
        await service.markReminderShown(userId: 'user-A', now: now);

        // user-A should be throttled
        final resultA = await service.shouldShowTrialReminder(
          userId: 'user-A',
          snapshot: snapshot1,
          now: now,
        );
        expect(resultA, isFalse);

        // user-B should NOT be throttled
        final resultB = await service.shouldShowTrialReminder(
          userId: 'user-B',
          snapshot: snapshot2,
          now: now,
        );
        expect(resultB, isTrue);
      });
    });

    group('markReminderShown', () {
      test('persists ISO 8601 UTC timestamp', () async {
        final now = DateTime(2025, 6, 15, 14, 30, 0);

        await service.markReminderShown(userId: 'user-ts', now: now);

        final stored = prefs.getString('trialReminder:lastShownAt:user-ts');
        expect(stored, equals(now.toUtc().toIso8601String()));
      });

      test('overwrites previous timestamp', () async {
        final first = DateTime(2025, 6, 14, 10, 0, 0);
        final second = DateTime(2025, 6, 15, 10, 0, 0);

        await service.markReminderShown(userId: 'user-ow', now: first);
        await service.markReminderShown(userId: 'user-ow', now: second);

        final stored = prefs.getString('trialReminder:lastShownAt:user-ow');
        expect(stored, equals(second.toUtc().toIso8601String()));
      });
    });

    group('edge cases', () {
      test('handles corrupted stored timestamp gracefully', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 12));
        final snapshot = trialSnapshot(
          expiresAt: expiresAt,
          userId: 'user-corrupt',
        );

        // Manually corrupt the stored value
        await prefs.setString(
          'trialReminder:lastShownAt:user-corrupt',
          'not-a-date',
        );

        // Should still show (corrupt data treated as "never shown")
        final result = await service.shouldShowTrialReminder(
          userId: 'user-corrupt',
          snapshot: snapshot,
          now: now,
        );

        expect(result, isTrue);
      });

      test('trial expiring in exactly 24 hours shows reminder', () async {
        final now = DateTime(2025, 6, 15, 12, 0, 0);
        final expiresAt = now.add(const Duration(hours: 24));
        final snapshot = trialSnapshot(expiresAt: expiresAt);

        final result = await service.shouldShowTrialReminder(
          userId: 'user-1',
          snapshot: snapshot,
          now: now,
        );

        // Resolver considers <= 24h as within window
        expect(result, isTrue);
      });
    });
  });
}
