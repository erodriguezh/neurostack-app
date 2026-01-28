/// Internal representation of RevenueCat entitlement state.
///
/// Keeps SDK types at the adapter boundary (Design Principle #6).
///
/// IMPORTANT: Use nullable `EntitlementSnapshot?` to distinguish:
/// - `null` = RC unavailable (web stub, not configured, hard SDK failure) -> fallback to DB
///   NOTE: Mobile SDK provides cached CustomerInfo offline, so offline != null
/// - `EntitlementSnapshot.none()` = RC says user has no entitlement -> authoritative
class EntitlementSnapshot {
  /// CRITICAL: Track which user this snapshot belongs to.
  /// Only authoritative when `appUserId == currentUser.id` (Design Principle #10).
  final String? appUserId;

  /// Whether user has an active entitlement.
  final bool hasProEntitlement;

  /// Whether currently in trial period.
  final bool isTrialPeriod;

  /// Billing issue detected, payment retry in progress.
  final bool isInGracePeriod;

  /// Product identifier (e.g., 'neurostack_monthly', 'neurostack_yearly').
  final String? productId;

  /// When entitlement expires.
  final DateTime? expirationDate;

  /// Stable transaction ID (survives renewals).
  final String? originalTransactionId;

  /// Most recent purchase date.
  final DateTime? latestPurchaseDate;

  /// CRITICAL: Track last period type even when expired.
  /// Needed to distinguish "trial expired -> free" vs "paid expired -> expired".
  final EntitlementPeriodType? lastPeriodType;

  const EntitlementSnapshot({
    required this.appUserId,
    required this.hasProEntitlement,
    required this.isTrialPeriod,
    required this.isInGracePeriod,
    required this.productId,
    required this.expirationDate,
    required this.originalTransactionId,
    required this.latestPurchaseDate,
    required this.lastPeriodType,
  })  : assert(
          // If user has entitlement, at least one state flag should be true
          !hasProEntitlement || isTrialPeriod || isInGracePeriod || productId != null,
          'Active entitlement should have trial, grace, or productId set',
        ),
        assert(
          // If in trial or grace period, must have entitlement
          (!isTrialPeriod && !isInGracePeriod) || hasProEntitlement,
          'Trial or grace period requires hasProEntitlement to be true',
        );

  /// Known state: user has NEVER had entitlement.
  ///
  /// Use this when RevenueCat returns no entitlement for the user.
  /// [appUserId] should be set to the current user's ID when constructing.
  factory EntitlementSnapshot.none({required String appUserId}) =>
      EntitlementSnapshot(
        appUserId: appUserId,
        hasProEntitlement: false,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: null,
        expirationDate: null,
        originalTransactionId: null,
        latestPurchaseDate: null,
        lastPeriodType: null,
      );

  /// Check if this snapshot belongs to the given user.
  ///
  /// Returns `true` if `appUserId` matches [userId].
  /// Use this to verify the snapshot is authoritative for the current user
  /// (Design Principle #10: User-scoped snapshots).
  bool isForUser(String userId) => appUserId == userId;

  /// Was this a trial that expired? (for trial-expired modal)
  ///
  /// Returns `true` if:
  /// - User no longer has entitlement (`hasProEntitlement == false`)
  /// - AND the last period type was a trial
  bool get wasTrialThatExpired =>
      !hasProEntitlement && lastPeriodType == EntitlementPeriodType.trial;

  /// Was this a paid subscription that expired? (for "resubscribe" UX)
  ///
  /// NOTE: "intro" is treated as paid (discounted paid period, not free trial).
  /// This maps churned intro users to "expired" status for "resubscribe" messaging.
  ///
  /// Returns `true` if:
  /// - User no longer has entitlement (`hasProEntitlement == false`)
  /// - AND the last period type was normal OR intro (both are paid periods)
  bool get wasPaidThatExpired =>
      !hasProEntitlement &&
      (lastPeriodType == EntitlementPeriodType.normal ||
          lastPeriodType == EntitlementPeriodType.intro);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntitlementSnapshot &&
          runtimeType == other.runtimeType &&
          appUserId == other.appUserId &&
          hasProEntitlement == other.hasProEntitlement &&
          isTrialPeriod == other.isTrialPeriod &&
          isInGracePeriod == other.isInGracePeriod &&
          productId == other.productId &&
          expirationDate == other.expirationDate &&
          originalTransactionId == other.originalTransactionId &&
          latestPurchaseDate == other.latestPurchaseDate &&
          lastPeriodType == other.lastPeriodType;

  @override
  int get hashCode => Object.hash(
        appUserId,
        hasProEntitlement,
        isTrialPeriod,
        isInGracePeriod,
        productId,
        expirationDate,
        originalTransactionId,
        latestPurchaseDate,
        lastPeriodType,
      );

  @override
  String toString() => 'EntitlementSnapshot('
      'appUserId: $appUserId, '
      'hasProEntitlement: $hasProEntitlement, '
      'isTrialPeriod: $isTrialPeriod, '
      'isInGracePeriod: $isInGracePeriod, '
      'productId: $productId, '
      'expirationDate: $expirationDate, '
      'originalTransactionId: $originalTransactionId, '
      'latestPurchaseDate: $latestPurchaseDate, '
      'lastPeriodType: $lastPeriodType)';
}

/// Period types from RevenueCat.
///
/// Used to distinguish between trial, intro offer, and normal billing periods.
enum EntitlementPeriodType {
  /// Free trial period (no charge).
  trial,

  /// Intro offer (discounted paid period - treated as "paid" for churn UX).
  intro,

  /// Regular billing period.
  normal,
}

/// Result of paywall presentation.
///
/// Used to communicate the outcome of presenting the RevenueCat paywall
/// back to the caller.
enum PaywallOutcome {
  /// User completed a purchase.
  purchased,

  /// User dismissed the paywall without purchasing.
  cancelled,

  /// An error occurred (SDK not ready, not identified, etc.).
  error,
}
