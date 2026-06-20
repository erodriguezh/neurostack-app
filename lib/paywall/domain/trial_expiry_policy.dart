import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

/// Pure policy for trial-expiry surface decisions.
///
/// For this strangler slice it delegates to [SubscriptionStatusResolver] so
/// the existing behavior is preserved while consumers move to this seam.
class TrialExpiryPolicy {
  const TrialExpiryPolicy({
    required SubscriptionStatusResolver resolver,
  }) : _resolver = resolver;

  final SubscriptionStatusResolver _resolver;

  bool shouldShowReminder({
    required EntitlementSnapshot? snapshot,
    required DateTime now,
  }) {
    return _resolver.shouldShowTrialReminder(
      snapshot: snapshot,
      now: now,
    );
  }

  bool shouldShowExpiredModal({
    required SubscriptionStatus effectiveStatus,
    required SubscriptionStatus? lastSeen,
    required EntitlementSnapshot? snapshot,
  }) {
    return _resolver.shouldShowTrialExpiredModal(
      currentEffectiveStatus: effectiveStatus,
      lastSeenStatus: lastSeen,
      snapshot: snapshot,
    );
  }
}
