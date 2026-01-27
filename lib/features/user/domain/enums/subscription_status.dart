/// User's payment/subscription state.
///
/// Determines protocol limits and feature access.
enum SubscriptionStatus {
  /// 7-day trial with full access. Auto-activates on first launch (INV-U3).
  trial(protocolLimit: null, canAccessPremium: true),

  /// Free tier with 2 protocol limit. No time limit (INV-M1, INV-B5).
  free(protocolLimit: 2, canAccessPremium: false),

  /// Monthly premium subscription ($7.99/month).
  premiumMonthly(protocolLimit: null, canAccessPremium: true),

  /// Annual premium subscription ($59.99/year - 37% off monthly).
  premiumAnnual(protocolLimit: null, canAccessPremium: true),

  /// Subscription expired but not yet downgraded.
  expired(protocolLimit: 2, canAccessPremium: false),

  /// Grace period for failed payment (retrying).
  grace(protocolLimit: null, canAccessPremium: true);

  const SubscriptionStatus({
    required this.protocolLimit,
    required this.canAccessPremium,
  });

  /// Maximum number of protocols that can be activated.
  /// `null` means unlimited.
  final int? protocolLimit;

  /// Whether user can access premium features.
  final bool canAccessPremium;

  /// True if user has unlimited protocol activations.
  bool get hasUnlimitedProtocols => protocolLimit == null;

  /// True if user is on free or expired status (has protocol limit).
  bool get isFreeOrExpired => this == free || this == expired;

  /// True if user has an active premium subscription.
  /// Includes grace period (billing issue, payment retry in progress).
  bool get isPremium =>
      this == premiumMonthly || this == premiumAnnual || this == grace;
}
