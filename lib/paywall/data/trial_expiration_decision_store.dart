import 'package:shared_preferences/shared_preferences.dart';

import '../../features/user/domain/enums/subscription_status.dart';
import '../domain/entitlement_snapshot.dart';

/// The user's decision when their subscription expires.
enum ExpirationDecision {
  /// User chose to upgrade / resubscribe.
  upgrade,

  /// User chose to continue with the free tier.
  useFreeTier,
}

/// Persists trial expiration decision state to prevent repeated modal display.
///
/// Key format (legacy): `trial_expired_resolved:<userId>:<trialStartDate.toUtc().toIso8601String()>`
/// Key format (new): `sub_exp_resolved:<userId>:<entitlementId>:<stableId>`
///
/// Also provides status transition tracking for modal detection (Phase 7.0):
/// - `saveLastSeenStatus` / `getLastSeenStatus` for status transition detection
abstract interface class TrialExpirationDecisionStore {
  /// Returns true if the user has already resolved the trial expiration decision
  /// for this specific trial instance.
  ///
  /// Legacy method keyed by trialStartDate. Kept for backward compatibility.
  /// Callers will be migrated to [isSubscriptionExpirationResolved] in later phases.
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  });

  /// Marks the trial expiration decision as resolved for this trial instance.
  ///
  /// Legacy method keyed by trialStartDate. Kept for backward compatibility.
  /// Callers will be migrated to [markSubscriptionExpirationResolved] in later phases.
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  });

  /// Check if expiration has been resolved for this subscription period.
  ///
  /// Uses RevenueCat-stable identifiers with fallback hierarchy:
  /// 1. originalTransactionId (most stable, survives renewals)
  /// 2. latestPurchaseDate (fallback if #1 unavailable)
  /// 3. expirationDate (last resort)
  ///
  /// Returns false if key can't be computed (fail safe -- show modal).
  Future<bool> isSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
  });

  /// Mark expiration as resolved with the user's decision.
  ///
  /// Uses RevenueCat-stable identifiers with fallback hierarchy.
  /// Does nothing if key can't be computed (non-cacheable).
  Future<void> markSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
    required ExpirationDecision decision,
  });

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

  static const _keyPrefix = 'trial_expired_resolved';
  static const _subExpKeyPrefix = 'sub_exp_resolved';
  static const _statusKeyPrefix = 'lastSeenEffectiveStatus';

  // -- Legacy key (trialStartDate-based) --

  String _key(String userId, DateTime trialStartDate) =>
      '$_keyPrefix:$userId:${trialStartDate.toUtc().toIso8601String()}';

  // -- New key (RevenueCat-stable identifiers) --

  /// Stable key for decision persistence.
  ///
  /// Fallback hierarchy (use first available):
  /// 1. originalTransactionId (most stable, survives renewals)
  /// 2. latestPurchaseDate ISO 8601 (fallback if #1 unavailable)
  /// 3. expirationDate ISO 8601 (last resort)
  ///
  /// Returns null if no stable identifier is available (non-cacheable).
  /// This prevents incorrectly suppressing future legitimate modals.
  String? _buildDecisionKey({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
  }) {
    final txnId = snapshot.originalTransactionId;
    if (txnId != null) {
      return '$_subExpKeyPrefix:$userId:$entitlementId:$txnId';
    }

    final purchaseDate = snapshot.latestPurchaseDate;
    if (purchaseDate != null) {
      return '$_subExpKeyPrefix:$userId:$entitlementId:purchase:${purchaseDate.toUtc().toIso8601String()}';
    }

    final expDate = snapshot.expirationDate;
    if (expDate != null) {
      return '$_subExpKeyPrefix:$userId:$entitlementId:exp:${expDate.toUtc().toIso8601String()}';
    }

    // Can't compute stable key - return null to indicate non-cacheable.
    return null;
  }

  String _statusKey(String userId) => '$_statusKeyPrefix:$userId';

  // -- Legacy methods (backward compatible) --

  @override
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    return _prefs.getBool(_key(userId, trialStartDate)) ?? false;
  }

  @override
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    await _prefs.setBool(_key(userId, trialStartDate), true);
  }

  // -- New snapshot-based methods --

  @override
  Future<bool> isSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
  }) async {
    final key = _buildDecisionKey(
      userId: userId,
      entitlementId: entitlementId,
      snapshot: snapshot,
    );
    if (key == null) return false; // Non-cacheable, always show modal
    return _prefs.getString(key) != null;
  }

  @override
  Future<void> markSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
    required ExpirationDecision decision,
  }) async {
    final key = _buildDecisionKey(
      userId: userId,
      entitlementId: entitlementId,
      snapshot: snapshot,
    );
    if (key == null) return; // Non-cacheable, can't persist
    await _prefs.setString(key, decision.name);
  }

  // -- Status transition tracking --

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
