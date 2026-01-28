import 'dart:async';

import '../domain/entitlement_snapshot.dart';
import 'revenuecat_client.dart';

/// Stub implementation of [RevenueCatClient] for web platform.
///
/// RevenueCat SDK does not support web, so this provides a no-op implementation
/// that indicates "RC unavailable" through its return values.
///
/// ## Nullability Contract
///
/// [getEntitlementSnapshot] returns `null` (NOT `.none()`) to indicate
/// "RC unavailable". This is critical because:
///
/// - `null` = RC unavailable -> resolver falls back to DB status
/// - `.none()` = RC says user has no entitlement -> authoritative
///
/// Returning `.none()` on web would incorrectly downgrade premium users who
/// happen to access the web version.
class RevenueCatClientStub implements RevenueCatClient {
  /// Empty stream that never emits.
  final _emptyController = StreamController<EntitlementSnapshot>.broadcast();

  @override
  Future<void> configure(String apiKey) async {
    // No-op: RC not available on web
  }

  @override
  Future<void> logIn(String userId) async {
    // No-op: RC not available on web
  }

  @override
  Future<void> logOut() async {
    // No-op: RC not available on web
  }

  @override
  Future<EntitlementSnapshot?> getEntitlementSnapshot() async {
    // CRITICAL: Return null (NOT .none()) to indicate "unknown"
    // The resolver will fallback to DB status
    return null;
  }

  @override
  Future<PaywallOutcome> presentPaywall() async {
    // Cannot present paywall on web - return error
    return PaywallOutcome.error;
  }

  @override
  Future<void> restorePurchases() async {
    // No-op: RC not available on web
  }

  @override
  Stream<EntitlementSnapshot> get entitlementChanges => _emptyController.stream;
}
