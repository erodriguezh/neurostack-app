import '../../features/user/domain/entities/user.dart';
import '../../features/user/domain/enums/subscription_status.dart';
import 'entitlement_snapshot.dart';
import 'subscription_status_resolver.dart';

/// Resolved domain answer for what a user can do right now.
///
/// In this migration slice the resolution delegates to
/// [SubscriptionStatusResolver] so behavior stays identical while callers move
/// to the new seam.
class Entitlement {
  const Entitlement._(this.effectiveStatus);

  /// Fallback entitlement used before a user can be resolved.
  static const fallback = Entitlement._(SubscriptionStatus.free);

  /// Resolves entitlement from the persisted user status and nullable
  /// RevenueCat snapshot.
  factory Entitlement.of(User user, EntitlementSnapshot? snapshot) {
    final effectiveStatus = const SubscriptionStatusResolver()
        .resolveEffectiveStatus(user: user, snapshot: snapshot);
    return Entitlement._(effectiveStatus);
  }

  /// Subscription Status used for gating after applying snapshot precedence.
  final SubscriptionStatus effectiveStatus;

  /// Maximum active protocols allowed; `null` means unlimited.
  int? get protocolLimit => effectiveStatus.protocolLimit;

  /// True for paid Premium statuses and grace period.
  bool get isPremium => effectiveStatus.isPremium;

  /// True for trial, paid Premium statuses, and grace period.
  bool get canAccessPremium => effectiveStatus.canAccessPremium;
}
