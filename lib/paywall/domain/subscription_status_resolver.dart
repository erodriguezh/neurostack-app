import 'package:logging/logging.dart';

import '../../features/user/domain/entities/user.dart';
import '../../features/user/domain/enums/subscription_status.dart';
import '../paywall_constants.dart';
import 'entitlement_snapshot.dart';

/// Pure resolver for subscription status decisions.
///
/// This class provides the single source of truth for UI gating decisions,
/// preventing duplicate logic across Home/Library views.
///
/// ## Design Principles
///
/// - **Pure functions:** No injected dependencies. Callers supply `DateTime now`
///   for time-based logic (Design Principle #8).
/// - **User-scoped snapshots:** Snapshot is only authoritative when
///   `appUserId == user.id` (Design Principle #10).
/// - **RC authority:** RevenueCat is the authority for entitlement state.
///   DB status is fallback when RC unavailable (Design Principle #1).
///
/// ## Usage
///
/// ```dart
/// final resolver = SubscriptionStatusResolver();
///
/// // Get effective status for UI gating
/// final status = resolver.resolveEffectiveStatus(
///   user: currentUser,
///   snapshot: revenueCatSnapshot,
/// );
///
/// // Check for trial reminder
/// final showReminder = resolver.shouldShowTrialReminder(
///   snapshot: revenueCatSnapshot,
///   now: DateTime.now(),
/// );
/// ```
class SubscriptionStatusResolver {
  /// Creates a [SubscriptionStatusResolver].
  ///
  /// This class has no instance state, so it can be instantiated as const.
  const SubscriptionStatusResolver();

  /// Logger for diagnostic messages.
  static final Logger _logger = Logger('SubscriptionStatusResolver');

  /// Returns the effective subscription status for UI gating.
  ///
  /// Precedence rules:
  /// 1. If snapshot is `null` (RC unavailable) -> fallback to [user.subscriptionStatus]
  /// 2. If snapshot is for wrong user -> fallback to [user.subscriptionStatus]
  /// 3. If snapshot is for correct user -> use RC state (authoritative)
  ///
  /// This ensures:
  /// - Web users (where RC returns null) still see their DB status
  /// - Users during SDK failures don't lose premium access UI
  /// - When RC is working, it's the authority
  SubscriptionStatus resolveEffectiveStatus({
    required User user,
    required EntitlementSnapshot? snapshot,
  }) {
    // CRITICAL: Only treat as authoritative if for current user (Design Principle #10)
    if (snapshot == null || !snapshot.isForUser(user.id)) {
      return user.subscriptionStatus; // Fallback to DB
    }
    return mapSnapshotToStatus(snapshot);
  }

  /// Checks if a trial reminder should be shown (within 24h of expiration).
  ///
  /// Requirements:
  /// - Snapshot is present and has an active entitlement
  /// - User is in trial period
  /// - Expiration is within 24 hours from [now] (but not already expired)
  ///
  /// Callers must pass [now] (e.g., `clock.now()` or `DateTime.now()`) for testability.
  ///
  /// Returns `false` if:
  /// - Snapshot is null (RC unavailable)
  /// - Not in trial period
  /// - No expiration date set
  /// - Already expired (negative duration)
  /// - More than 24 hours until expiration
  bool shouldShowTrialReminder({
    required EntitlementSnapshot? snapshot,
    required DateTime now,
  }) {
    if (snapshot == null) return false;
    if (!snapshot.hasProEntitlement) return false;
    if (!snapshot.isTrialPeriod) return false;

    final expirationDate = snapshot.expirationDate;
    if (expirationDate == null) return false;

    final timeUntilExpiration = expirationDate.difference(now);

    // Return false if already expired (negative duration)
    if (timeUntilExpiration.isNegative) return false;

    // Show reminder if within 24 hours of expiration
    return timeUntilExpiration <= const Duration(hours: 24);
  }

  /// Checks if the trial expired modal should be shown.
  ///
  /// CRITICAL: Uses EFFECTIVE STATUS (resolver output), not raw snapshot.
  /// This handles RC unavailable (web/failure) by falling back to DB status.
  ///
  /// ## Call Order (CRITICAL)
  ///
  /// 1. Load lastSeenStatus from decision store
  /// 2. Compute currentEffectiveStatus via [resolveEffectiveStatus]
  /// 3. Call this method to decide if modal should show
  /// 4. If showing modal, persist currentEffectiveStatus as new lastSeenStatus
  ///
  /// ## Detection Logic
  ///
  /// Primary: Detect status transition from trial -> free/expired.
  /// This works even when RC unavailable (uses effective status which falls back to DB).
  ///
  /// Secondary: RC's `wasTrialThatExpired` (if periodType available and RC working).
  /// This provides additional signal when lastSeenStatus is null (fresh install).
  ///
  /// - [currentEffectiveStatus]: From [resolveEffectiveStatus], NOT raw DB status.
  /// - [lastSeenStatus]: From decision store. Null if never persisted.
  /// - [snapshot]: Optional secondary signal for trial expiration detection.
  ///   Must already be scoped to the current user. Caller is responsible for
  ///   ensuring [snapshot.appUserId] matches the UI user. See
  ///   [RevenueCatService.entitlementSnapshot] invariants.
  bool shouldShowTrialExpiredModal({
    required SubscriptionStatus currentEffectiveStatus,
    required SubscriptionStatus? lastSeenStatus,
    required EntitlementSnapshot? snapshot,
  }) {
    // Primary: Detect status transition trial -> free/expired
    // Works even when RC unavailable (uses effective status which falls back to DB)
    if (lastSeenStatus == SubscriptionStatus.trial &&
        (currentEffectiveStatus == SubscriptionStatus.free ||
            currentEffectiveStatus == SubscriptionStatus.expired)) {
      return true; // Trial ended, show modal
    }

    // Secondary: RC's wasTrialThatExpired (if periodType available and RC working)
    // CRITICAL: Only use this for fresh installs where lastSeenStatus was never persisted.
    // Without this gate, the modal would show repeatedly after trial churn since
    // wasTrialThatExpired remains true across app launches.
    if (lastSeenStatus == null && snapshot?.wasTrialThatExpired == true) {
      return true;
    }

    return false;
  }

  /// Maps an [EntitlementSnapshot] to a [SubscriptionStatus].
  ///
  /// ## Precedence Rules (CRITICAL)
  ///
  /// 1. **No entitlement:** Check if was trial vs paid for expired state distinction
  /// 2. **Has entitlement + grace period:** Return [SubscriptionStatus.grace]
  /// 3. **Has entitlement + trial:** Return [SubscriptionStatus.trial]
  /// 4. **Has entitlement + monthly product:** Return [SubscriptionStatus.premiumMonthly]
  /// 5. **Has entitlement + yearly product:** Return [SubscriptionStatus.premiumAnnual]
  /// 6. **Has entitlement + unknown product:** Log warning, return [SubscriptionStatus.premiumMonthly]
  ///
  /// This explicit ordering ensures consistent behavior across the app.
  SubscriptionStatus mapSnapshotToStatus(EntitlementSnapshot snapshot) {
    // 1. No entitlement at all
    if (!snapshot.hasProEntitlement) {
      // Check if was trial vs paid for expired state distinction
      if (snapshot.wasTrialThatExpired) return SubscriptionStatus.free;
      if (snapshot.wasPaidThatExpired) return SubscriptionStatus.expired;
      return SubscriptionStatus.free; // Never had entitlement
    }

    // 2. Has entitlement - determine type
    // CRITICAL: Grace takes precedence (billing issue during active subscription)
    if (snapshot.isInGracePeriod) return SubscriptionStatus.grace;

    // 3. Active subscription - check if trial or paid
    if (snapshot.isTrialPeriod) return SubscriptionStatus.trial;

    // 4. Paid subscription - determine monthly vs yearly
    if (snapshot.productId == kProductMonthly) {
      return SubscriptionStatus.premiumMonthly;
    }
    if (snapshot.productId == kProductYearly) {
      return SubscriptionStatus.premiumAnnual;
    }

    // 5. Fallback for unknown product - LOG LOUDLY (should never happen in prod)
    // TODO: Add new product IDs here when expanding subscription tiers
    _logger.warning(
      'Unknown productId: ${snapshot.productId} - defaulting to premiumMonthly',
    );
    return SubscriptionStatus.premiumMonthly;
  }
}
