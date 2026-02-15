import 'dart:async';

import 'package:neurostack/paywall/data/revenuecat_client.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

/// A controllable fake [RevenueCatClient] for integration tests.
///
/// Allows tests to:
/// - Simulate purchase completion via [simulatePurchase]
/// - Simulate entitlement changes via [simulateEntitlementChange]
/// - Control paywall outcome via [nextPaywallOutcome]
/// - Track method calls for verification
class FakeRevenueCatClient implements RevenueCatClient {
  FakeRevenueCatClient({
    this.nextPaywallOutcome = PaywallOutcome.cancelled,
    EntitlementSnapshot? initialSnapshot,
  }) : _currentSnapshot = initialSnapshot;

  /// The outcome returned by the next [presentPaywall] call.
  PaywallOutcome nextPaywallOutcome;

  /// Snapshot returned by [getEntitlementSnapshot].
  EntitlementSnapshot? _currentSnapshot;

  /// Whether [configure] has been called.
  bool isConfigured = false;

  /// The user ID passed to [logIn], or null if not logged in.
  String? loggedInUserId;

  /// Number of times [restorePurchases] was called.
  int restorePurchasesCallCount = 0;

  /// Number of times [presentPaywall] was called.
  int presentPaywallCallCount = 0;

  final StreamController<EntitlementSnapshot> _entitlementController =
      StreamController<EntitlementSnapshot>.broadcast();

  @override
  Future<void> configure(String apiKey) async {
    isConfigured = true;
  }

  @override
  Future<void> logIn(String userId) async {
    loggedInUserId = userId;
  }

  @override
  Future<void> logOut() async {
    loggedInUserId = null;
  }

  @override
  Future<EntitlementSnapshot?> getEntitlementSnapshot() async {
    return _currentSnapshot;
  }

  @override
  Future<PaywallOutcome> presentPaywall() async {
    presentPaywallCallCount++;
    final outcome = nextPaywallOutcome;

    // If the outcome is "purchased", the caller (RevenueCatService) will
    // call refreshEntitlement() which calls getEntitlementSnapshot().
    // The test should set the snapshot BEFORE or use simulatePurchase().
    return outcome;
  }

  @override
  Future<void> restorePurchases() async {
    restorePurchasesCallCount++;
  }

  @override
  Stream<EntitlementSnapshot> get entitlementChanges =>
      _entitlementController.stream;

  // ---------------------------------------------------------------------------
  // Test helpers
  // ---------------------------------------------------------------------------

  /// Sets the current entitlement snapshot returned by [getEntitlementSnapshot].
  void setSnapshot(EntitlementSnapshot? snapshot) {
    _currentSnapshot = snapshot;
  }

  /// Simulates a purchase by:
  /// 1. Setting the snapshot to the purchased entitlement
  /// 2. Emitting the snapshot on the entitlement changes stream
  void simulatePurchase(EntitlementSnapshot purchasedSnapshot) {
    _currentSnapshot = purchasedSnapshot;
    _entitlementController.add(purchasedSnapshot);
  }

  /// Simulates an entitlement change (e.g., trial expiration, renewal).
  ///
  /// Updates the internal snapshot and emits on the changes stream.
  void simulateEntitlementChange(EntitlementSnapshot newSnapshot) {
    _currentSnapshot = newSnapshot;
    _entitlementController.add(newSnapshot);
  }

  /// Disposes the stream controller.
  void dispose() {
    _entitlementController.close();
  }
}
