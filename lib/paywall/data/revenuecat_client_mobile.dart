import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../domain/entitlement_snapshot.dart';
import '../paywall_constants.dart';
import 'revenuecat_client.dart';

/// Mobile implementation of [RevenueCatClient] using purchases_flutter SDK.
///
/// This implementation provides full RevenueCat functionality for iOS, Android,
/// and macOS platforms.
///
/// ## Listener Setup
///
/// The SDK listener is registered exactly once during [configure]. The listener
/// only emits [EntitlementSnapshot] events when a user is identified (i.e.,
/// after [logIn] and before [logOut]).
///
/// ## User Tracking
///
/// The [_currentUserId] field tracks the currently logged-in user:
/// - Set AFTER successful [logIn] (not before, to prevent emissions for failed logins)
/// - Cleared BEFORE [logOut] (to prevent emissions for the logging-out user)
class RevenueCatClientMobile implements RevenueCatClient {
  /// Tracks the currently logged-in user ID for listener callbacks.
  /// Only emit snapshots when this is non-null.
  String? _currentUserId;

  /// Stream controller for entitlement changes.
  final _entitlementController =
      StreamController<EntitlementSnapshot>.broadcast();

  /// Guard to ensure listener is setup exactly once.
  bool _listenerSetup = false;

  @override
  Future<void> configure(String apiKey) async {
    await Purchases.configure(PurchasesConfiguration(apiKey));

    // CRITICAL: Setup listener exactly once during configure.
    // Set flag BEFORE calling _setupListener() to prevent concurrent
    // configure() calls from registering multiple listeners.
    if (!_listenerSetup) {
      _listenerSetup = true;
      _setupListener();
    }
  }

  @override
  Future<void> logIn(String userId) async {
    // CRITICAL: Clear _currentUserId BEFORE logIn to prevent old-user
    // emissions during the async SDK call. This handles account switches
    // (logIn as A, then logIn as B without explicit logOut).
    final previousUserId = _currentUserId;
    _currentUserId = null;

    try {
      await Purchases.logIn(userId);
      _currentUserId = userId;

      // Emit an immediate snapshot for the new user so UI updates promptly
      final info = await Purchases.getCustomerInfo();
      final snapshot = _mapCustomerInfo(info, userId);
      if (snapshot != null) {
        _entitlementController.add(snapshot);
      }
    } catch (e) {
      // Restore previous user ID on failure (rollback)
      _currentUserId = previousUserId;
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    // CRITICAL: Clear _currentUserId BEFORE logOut to prevent
    // listener from emitting snapshots for the logging-out user
    _currentUserId = null;
    await Purchases.logOut();
  }

  @override
  Future<EntitlementSnapshot?> getEntitlementSnapshot() async {
    // CRITICAL: Return null if not logged in. Returning a snapshot with
    // appUserId == null could be mistakenly treated as authoritative.
    final userId = _currentUserId;
    if (userId == null) {
      return null;
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _mapCustomerInfo(customerInfo, userId);
    } catch (e) {
      // Hard SDK failure - return null to indicate unavailable
      // The resolver will fallback to DB status
      return null;
    }
  }

  @override
  Future<PaywallOutcome> presentPaywall() async {
    // CRITICAL: Must be logged in before presenting paywall.
    // Purchasing as anonymous user can cause entitlement ownership issues.
    if (_currentUserId == null) {
      return PaywallOutcome.error;
    }

    try {
      final result = await RevenueCatUI.presentPaywall();

      switch (result) {
        case PaywallResult.purchased:
        case PaywallResult.restored:
          return PaywallOutcome.purchased;
        case PaywallResult.cancelled:
        case PaywallResult.notPresented:
          return PaywallOutcome.cancelled;
        case PaywallResult.error:
          return PaywallOutcome.error;
      }
    } catch (e) {
      return PaywallOutcome.error;
    }
  }

  @override
  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }

  @override
  Stream<EntitlementSnapshot> get entitlementChanges =>
      _entitlementController.stream;

  /// Sets up the customer info update listener.
  ///
  /// CRITICAL: Only emit if we have an identified user. Pre-identification
  /// emissions are ignored.
  void _setupListener() {
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      // CRITICAL: Only emit if we have an identified user
      final userId = _currentUserId;
      if (userId != null) {
        final snapshot = _mapCustomerInfo(customerInfo, userId);
        if (snapshot != null) {
          _entitlementController.add(snapshot);
        }
      }
    });
  }

  /// Maps RevenueCat CustomerInfo to our domain EntitlementSnapshot.
  ///
  /// CRITICAL: Read BOTH active AND all entitlements to detect "trial ended" state.
  /// The `all` collection includes expired entitlements with their lastPeriodType.
  ///
  /// Returns null if identifiedUserId is null to prevent returning snapshots
  /// with appUserId == null that could be mistakenly treated as authoritative.
  EntitlementSnapshot? _mapCustomerInfo(
    CustomerInfo info,
    String? identifiedUserId,
  ) {
    // CRITICAL: Return null if no identified user. Returning a snapshot with
    // appUserId == null could be mistakenly treated as authoritative elsewhere.
    if (identifiedUserId == null) {
      return null;
    }

    // Use the identified user ID we passed to logIn(), NOT originalAppUserId
    // originalAppUserId is the anonymous/original ID, not the current logged-in user
    final appUserId = identifiedUserId;

    // Check active entitlements first
    final active = info.entitlements.active[kNeurostackProEntitlementId];
    if (active != null) {
      final periodType = _mapPeriodType(active.periodType);
      // billingIssueDetectedAt indicates a grace period (payment retry in progress)
      final isGrace = active.billingIssueDetectedAt != null;

      return EntitlementSnapshot(
        appUserId: appUserId,
        hasProEntitlement: true,
        isTrialPeriod: periodType == EntitlementPeriodType.trial,
        isInGracePeriod: isGrace,
        productId: active.productIdentifier,
        expirationDate: _parseDate(active.expirationDate),
        // NOTE: The SDK provides originalPurchaseDate but not a stable transaction ID
        // that survives renewals. We leave this null and use expirationDate-based
        // fallback key in the decision store (Phase 7.1).
        originalTransactionId: null,
        latestPurchaseDate: _parseDate(active.latestPurchaseDate),
        lastPeriodType: periodType,
      );
    }

    // No active entitlement - check if they HAD one (for expired modal detection)
    // The `all` collection includes both active and expired entitlements
    final all = info.entitlements.all[kNeurostackProEntitlementId];
    if (all != null) {
      // CRITICAL: Preserve lastPeriodType for "trial expired vs paid expired"
      final lastPeriodType = _mapPeriodType(all.periodType);

      return EntitlementSnapshot(
        appUserId: appUserId,
        hasProEntitlement: false,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: all.productIdentifier,
        expirationDate: _parseDate(all.expirationDate),
        originalTransactionId: null,
        latestPurchaseDate: _parseDate(all.latestPurchaseDate),
        lastPeriodType: lastPeriodType, // CRITICAL for UX decision
      );
    }

    // User has never had this entitlement - return authoritative "none"
    // (identifiedUserId is guaranteed non-null by early return above)
    return EntitlementSnapshot.none(appUserId: appUserId);
  }

  /// Maps SDK PeriodType to our domain EntitlementPeriodType.
  ///
  /// CRITICAL: Returns null for unknown types - don't guess.
  /// Downstream logic must treat null as "don't know if trial or paid".
  EntitlementPeriodType? _mapPeriodType(PeriodType? sdkPeriodType) {
    if (sdkPeriodType == null) return null;

    switch (sdkPeriodType) {
      case PeriodType.trial:
        return EntitlementPeriodType.trial;
      case PeriodType.intro:
        return EntitlementPeriodType.intro;
      case PeriodType.normal:
        return EntitlementPeriodType.normal;
      case PeriodType.prepaid:
        // Prepaid is a paid period, treat like normal
        return EntitlementPeriodType.normal;
      case PeriodType.unknown:
        // CRITICAL: Return null for unknown types, don't guess
        return null;
    }
  }

  /// Parses a date string from the SDK to DateTime.
  ///
  /// The SDK returns dates as ISO 8601 strings.
  /// Returns null if the string is null or parsing fails.
  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }
}
