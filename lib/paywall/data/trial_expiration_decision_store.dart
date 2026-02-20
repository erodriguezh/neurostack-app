import 'package:shared_preferences/shared_preferences.dart';

import '../../features/user/domain/enums/subscription_status.dart';

/// Persists status transition tracking for modal detection (Phase 7.0):
/// - `saveLastSeenStatus` / `getLastSeenStatus` for status transition detection
abstract interface class TrialExpirationDecisionStore {
  /// Persists the last-seen effective status to detect transitions (survives restarts).
  ///
  /// Key: `lastSeenEffectiveStatus:<userId>`
  ///
  /// Call this after computing the effective status to track transitions.
  /// CALL ORDER: load lastSeen -> compute currentEffective -> decide modal -> persist newLastSeen
  Future<void> saveLastSeenStatus({
    required String userId,
    required SubscriptionStatus status,
  });

  /// Gets the last-seen status (for modal transition detection).
  ///
  /// Returns null if:
  /// - Never persisted for this user
  /// - Stored value doesn't match current enum (old app version, future rename)
  ///
  /// CRITICAL: Handles enum rename/removal gracefully (returns null on failure).
  Future<SubscriptionStatus?> getLastSeenStatus(String userId);
}

class SharedPrefsTrialExpirationDecisionStore
    implements TrialExpirationDecisionStore {
  SharedPrefsTrialExpirationDecisionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _statusKeyPrefix = 'lastSeenEffectiveStatus';

  String _statusKey(String userId) => '$_statusKeyPrefix:$userId';

  @override
  Future<void> saveLastSeenStatus({
    required String userId,
    required SubscriptionStatus status,
  }) async {
    await _prefs.setString(_statusKey(userId), status.name);
  }

  @override
  Future<SubscriptionStatus?> getLastSeenStatus(String userId) async {
    final name = _prefs.getString(_statusKey(userId));
    if (name == null) return null;
    try {
      return SubscriptionStatus.values.byName(name);
    } catch (_) {
      // Stored value doesn't match current enum (old app version, future rename)
      // Fail-safe: return null and let modal show if needed
      return null;
    }
  }
}
