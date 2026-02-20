import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/paywall_constants.dart';

import '../constants/test_constants.dart';

/// Factory for creating [EntitlementSnapshot] instances in tests.
///
/// Follows the existing factory pattern (see [UserFactory], [StackFactory]).
/// All methods use [TestConstants.user.id] as the default userId.
abstract final class EntitlementSnapshotFactory {
  // ---------------------------------------------------------------------------
  // Active entitlements
  // ---------------------------------------------------------------------------

  /// Active trial with optional [expirationDate].
  static EntitlementSnapshot activeTrial({
    String? userId,
    DateTime? expirationDate,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: true,
      isTrialPeriod: true,
      isInGracePeriod: false,
      productId: kProductMonthly,
      expirationDate: expirationDate,
      originalTransactionId: null,
      latestPurchaseDate: null,
      lastPeriodType: EntitlementPeriodType.trial,
    );
  }

  /// Active paid monthly subscription.
  static EntitlementSnapshot activePaidMonthly({
    String? userId,
    DateTime? expirationDate,
    String? originalTransactionId,
    DateTime? latestPurchaseDate,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: true,
      isTrialPeriod: false,
      isInGracePeriod: false,
      productId: kProductMonthly,
      expirationDate: expirationDate ?? DateTime(2025, 7, 15),
      originalTransactionId: originalTransactionId ?? 'txn-001',
      latestPurchaseDate: latestPurchaseDate ?? DateTime(2025, 6, 15),
      lastPeriodType: EntitlementPeriodType.normal,
    );
  }

  /// Active paid yearly subscription.
  static EntitlementSnapshot activePaidYearly({
    String? userId,
    DateTime? expirationDate,
    String? originalTransactionId,
    DateTime? latestPurchaseDate,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: true,
      isTrialPeriod: false,
      isInGracePeriod: false,
      productId: kProductYearly,
      expirationDate: expirationDate ?? DateTime(2026, 6, 15),
      originalTransactionId: originalTransactionId ?? 'txn-002',
      latestPurchaseDate: latestPurchaseDate ?? DateTime(2025, 6, 15),
      lastPeriodType: EntitlementPeriodType.normal,
    );
  }

  /// Grace period (billing issue, payment retry in progress).
  static EntitlementSnapshot gracePeriod({
    String? userId,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: true,
      isTrialPeriod: false,
      isInGracePeriod: true,
      productId: kProductMonthly,
      expirationDate: DateTime(2025, 7, 15),
      originalTransactionId: 'txn-003',
      latestPurchaseDate: DateTime(2025, 6, 15),
      lastPeriodType: EntitlementPeriodType.normal,
    );
  }

  // ---------------------------------------------------------------------------
  // Expired entitlements (no longer active)
  // ---------------------------------------------------------------------------

  /// Trial expired, no conversion (maps to `free` status).
  static EntitlementSnapshot expiredTrial({
    String? userId,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: false,
      isTrialPeriod: false,
      isInGracePeriod: false,
      productId: kProductMonthly,
      expirationDate: DateTime(2025, 6, 8),
      originalTransactionId: null,
      latestPurchaseDate: null,
      lastPeriodType: EntitlementPeriodType.trial,
    );
  }

  /// Paid subscription expired (maps to `expired` status).
  static EntitlementSnapshot expiredPaid({
    String? userId,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: false,
      isTrialPeriod: false,
      isInGracePeriod: false,
      productId: kProductMonthly,
      expirationDate: DateTime(2025, 6, 15),
      originalTransactionId: 'txn-004',
      latestPurchaseDate: DateTime(2025, 5, 15),
      lastPeriodType: EntitlementPeriodType.normal,
    );
  }

  /// Intro offer expired (treated as paid for churn UX, maps to `expired`).
  static EntitlementSnapshot expiredIntro({
    String? userId,
  }) {
    return EntitlementSnapshot(
      appUserId: userId ?? TestConstants.user.id,
      hasProEntitlement: false,
      isTrialPeriod: false,
      isInGracePeriod: false,
      productId: kProductYearly,
      expirationDate: DateTime(2025, 6, 15),
      originalTransactionId: 'txn-005',
      latestPurchaseDate: DateTime(2025, 5, 15),
      lastPeriodType: EntitlementPeriodType.intro,
    );
  }
}
