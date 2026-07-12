import 'package:logging/logging.dart';

import '../../features/user/domain/entities/user.dart';
import '../../features/user/domain/enums/subscription_status.dart';
import '../paywall_constants.dart';
import 'entitlement_snapshot.dart';

/// Resolved domain answer for what a user can do right now.
class Entitlement {
  const Entitlement._(this.effectiveStatus);

  /// Fallback entitlement used before a user can be resolved.
  static const fallback = Entitlement._(SubscriptionStatus.free);

  /// Resolves entitlement from the persisted user status and nullable
  /// RevenueCat snapshot.
  factory Entitlement.of(User user, EntitlementSnapshot? snapshot) {
    if (snapshot == null || !snapshot.isForUser(user.id)) {
      return Entitlement._(user.subscriptionStatus);
    }

    return Entitlement._(_mapSnapshotToStatus(snapshot));
  }

  static final Logger _logger = Logger('Entitlement');

  /// Subscription Status used for gating after applying snapshot precedence.
  final SubscriptionStatus effectiveStatus;

  /// Maximum active protocols allowed; `null` means unlimited.
  int? get protocolLimit => effectiveStatus.protocolLimit;

  /// True for paid Premium statuses and grace period.
  bool get isPremium => effectiveStatus.isPremium;

  /// True for trial, paid Premium statuses, and grace period.
  bool get canAccessPremium => effectiveStatus.canAccessPremium;

  static SubscriptionStatus _mapSnapshotToStatus(
    EntitlementSnapshot snapshot,
  ) {
    if (!snapshot.hasProEntitlement) {
      if (snapshot.wasTrialThatExpired) return SubscriptionStatus.free;
      if (snapshot.wasPaidThatExpired) return SubscriptionStatus.expired;
      return SubscriptionStatus.free;
    }
    if (snapshot.isInGracePeriod) return SubscriptionStatus.grace;
    if (snapshot.isTrialPeriod) return SubscriptionStatus.trial;
    if (snapshot.productId == kProductMonthly) {
      return SubscriptionStatus.premiumMonthly;
    }
    if (snapshot.productId == kProductYearly) {
      return SubscriptionStatus.premiumAnnual;
    }

    _logger.warning(
      'Unknown productId: ${snapshot.productId} - defaulting to premiumMonthly',
    );
    return SubscriptionStatus.premiumMonthly;
  }
}
