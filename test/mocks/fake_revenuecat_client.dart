import 'dart:async';

import 'package:neurostack/paywall/data/revenuecat_client.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

/// Fake implementation of [RevenueCatClient] for unit testing.
///
/// Provides fine-grained control for testing [RevenueCatService]:
/// - `configureDelay` / `configureThrows` for init timing and error paths
/// - `logInThrows` / `getSnapshotThrows` for error simulation
/// - `getSnapshotCompleter` for in-flight race condition testing
/// - `paywallCompleter` for concurrent access testing
///
/// Note: A separate `FakeRevenueCatClient` exists in
/// `integration_test/mocks/fake_revenuecat_client.dart` for integration tests.
/// That implementation has different helpers (simulatePurchase, setSnapshot,
/// call counting) suited to end-to-end flows. The two are intentionally
/// separate due to different testing needs.
class FakeRevenueCatClient implements RevenueCatClient {
  int configureCallCount = 0;
  bool get configureWasCalled => configureCallCount > 0;
  String? configuredApiKey;
  String? loggedInUserId;
  bool logOutWasCalled = false;
  bool restorePurchasesWasCalled = false;
  EntitlementSnapshot? snapshotToReturn;
  PaywallOutcome paywallOutcome = PaywallOutcome.cancelled;

  final _entitlementController =
      StreamController<EntitlementSnapshot>.broadcast();

  /// Simulates an entitlement change event from the SDK.
  void simulateEntitlementChange(EntitlementSnapshot snapshot) {
    _entitlementController.add(snapshot);
  }

  /// Delay for configure to simulate async behavior.
  Duration? configureDelay;

  /// Whether configure should throw an error.
  bool configureThrows = false;

  /// Whether logIn should throw an error.
  bool logInThrows = false;

  /// Whether getEntitlementSnapshot should throw an error.
  bool getSnapshotThrows = false;

  /// Call counter for getEntitlementSnapshot.
  int getEntitlementSnapshotCallCount = 0;

  /// Completer to block getEntitlementSnapshot (for testing in-flight races).
  Completer<EntitlementSnapshot?>? getSnapshotCompleter;

  /// Completer to block paywall presentation (for testing concurrent access).
  Completer<PaywallOutcome>? paywallCompleter;

  @override
  Future<void> configure(String apiKey) async {
    if (configureDelay != null) {
      await Future<void>.delayed(configureDelay!);
    }
    if (configureThrows) {
      throw Exception('Configure failed');
    }
    configuredApiKey = apiKey;
    configureCallCount++;
  }

  @override
  Future<void> logIn(String userId) async {
    if (logInThrows) {
      throw Exception('LogIn failed');
    }
    loggedInUserId = userId;
  }

  @override
  Future<void> logOut() async {
    logOutWasCalled = true;
    loggedInUserId = null;
  }

  @override
  Future<EntitlementSnapshot?> getEntitlementSnapshot() async {
    getEntitlementSnapshotCallCount++;
    if (getSnapshotThrows) {
      throw Exception('getEntitlementSnapshot failed');
    }
    if (getSnapshotCompleter != null) {
      return getSnapshotCompleter!.future;
    }
    return snapshotToReturn;
  }

  @override
  Future<PaywallOutcome> presentPaywall() async {
    // If a completer is set, wait for it (for testing concurrent access)
    if (paywallCompleter != null) {
      return paywallCompleter!.future;
    }
    return paywallOutcome;
  }

  @override
  Future<void> restorePurchases() async {
    restorePurchasesWasCalled = true;
  }

  @override
  Stream<EntitlementSnapshot> get entitlementChanges =>
      _entitlementController.stream;

  void dispose() {
    _entitlementController.close();
  }
}
