import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entitlement_snapshot.dart';
import '../domain/subscription_status_resolver.dart';

/// Throttles trial reminder display to once per 24 hours per user (INV-P4).
///
/// Wraps [SubscriptionStatusResolver.shouldShowTrialReminder] with
/// user-scoped SharedPreferences persistence. The resolver checks whether
/// the user is within the 24h-before-expiration window; this service adds
/// the "don't show again for 24h" throttle on top.
///
/// ## Key format
///
/// `trialReminder:lastShownAt:<userId>` -> ISO 8601 UTC timestamp
///
/// ## Usage
///
/// ```dart
/// final show = await service.shouldShowTrialReminder(
///   userId: 'user-123',
///   snapshot: revenueCatSnapshot,
///   now: DateTime.now(),
/// );
/// if (show) {
///   // display reminder
///   await service.markReminderShown(userId: 'user-123', now: DateTime.now());
/// }
/// ```
class TrialReminderService {
  TrialReminderService({
    required SharedPreferences sharedPreferences,
    required SubscriptionStatusResolver resolver,
  }) : _prefs = sharedPreferences,
       _resolver = resolver;

  final SharedPreferences _prefs;
  final SubscriptionStatusResolver _resolver;

  static const _keyPrefix = 'trialReminder:lastShownAt';

  /// Returns the SharedPreferences key for a given user.
  String _key(String userId) => '$_keyPrefix:$userId';

  /// Whether the trial reminder should be displayed.
  ///
  /// Returns `true` only when **both** conditions hold:
  /// 1. The resolver says the user is in the 24h-before-expiration window.
  /// 2. The reminder has **not** been shown within the last 24 hours.
  ///
  /// Callers must pass [now] for testability (Design Principle #8).
  Future<bool> shouldShowTrialReminder({
    required String userId,
    required EntitlementSnapshot? snapshot,
    required DateTime now,
  }) async {
    // Guard: snapshot must belong to current user (Design Principle #10)
    if (snapshot == null || !snapshot.isForUser(userId)) return false;

    // Delegate to resolver for the expiration-window check
    final inExpirationWindow = _resolver.shouldShowTrialReminder(
      snapshot: snapshot,
      now: now,
    );
    if (!inExpirationWindow) return false;

    // Apply once-per-day throttle
    final lastShownIso = _prefs.getString(_key(userId));
    if (lastShownIso != null) {
      final lastShown = DateTime.tryParse(lastShownIso);
      if (lastShown != null) {
        final elapsed = now.difference(lastShown);
        if (elapsed < const Duration(hours: 24)) {
          return false; // Shown within last 24h, suppress
        }
      }
    }

    return true;
  }

  /// Persists that the reminder was shown at [now] for [userId].
  ///
  /// Call this after displaying the trial reminder so the 24h throttle
  /// takes effect.
  Future<void> markReminderShown({
    required String userId,
    required DateTime now,
  }) async {
    await _prefs.setString(_key(userId), now.toUtc().toIso8601String());
  }
}
