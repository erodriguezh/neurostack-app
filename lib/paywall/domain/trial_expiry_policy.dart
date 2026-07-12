import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

/// Pure policy for trial-expiry surface decisions.
class TrialExpiryPolicy {
  const TrialExpiryPolicy();

  bool shouldShowReminder({
    required EntitlementSnapshot? snapshot,
    required DateTime now,
  }) {
    if (snapshot == null ||
        !snapshot.hasProEntitlement ||
        !snapshot.isTrialPeriod) {
      return false;
    }

    final expirationDate = snapshot.expirationDate;
    if (expirationDate == null) return false;

    final timeUntilExpiration = expirationDate.difference(now);
    return !timeUntilExpiration.isNegative &&
        timeUntilExpiration <= const Duration(hours: 24);
  }

  bool shouldShowExpiredModal({
    required SubscriptionStatus effectiveStatus,
    required SubscriptionStatus? lastSeen,
    required EntitlementSnapshot? snapshot,
  }) {
    if (lastSeen == SubscriptionStatus.trial &&
        (effectiveStatus == SubscriptionStatus.free ||
            effectiveStatus == SubscriptionStatus.expired)) {
      return true;
    }

    return lastSeen == null && snapshot?.wasTrialThatExpired == true;
  }
}
