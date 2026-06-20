import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entitlement_snapshot.dart';
import '../domain/trial_expiry_policy.dart';

/// Throttles trial reminder display to once per 24 hours per user (INV-P4).
///
/// Wraps [TrialExpiryPolicy.shouldShowReminder] with user-scoped
/// SharedPreferences persistence. The policy checks whether
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
    required TrialExpiryPolicy trialExpiryPolicy,
  }) : _prefs = sharedPreferences,
       _trialExpiryPolicy = trialExpiryPolicy;

  final SharedPreferences _prefs;
  final TrialExpiryPolicy _trialExpiryPolicy;

  static const _keyPrefix = 'trialReminder:lastShownAt';
  static const _throttleWindow = Duration(hours: 24);

  /// Returns the SharedPreferences key for a given user.
  String _key(String userId) => '$_keyPrefix:$userId';

  /// Whether the trial reminder should be displayed.
  ///
  /// Returns `true` only when **both** conditions hold:
  /// 1. The policy says the user is in the 24h-before-expiration window.
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

    final inExpirationWindow = _trialExpiryPolicy.shouldShowReminder(
      snapshot: snapshot,
      now: now,
    );
    if (!inExpirationWindow) return false;

    final lastShownIso = _prefs.getString(_key(userId));
    if (lastShownIso != null) {
      final lastShown = DateTime.tryParse(lastShownIso);
      if (lastShown != null && _wasShownRecently(lastShown, now)) {
        return false;
      }
    }

    return true;
  }

  bool _wasShownRecently(DateTime lastShown, DateTime now) {
    return now.difference(lastShown) < _throttleWindow;
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
