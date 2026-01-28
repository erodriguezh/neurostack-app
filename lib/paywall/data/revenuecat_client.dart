import '../domain/entitlement_snapshot.dart';

/// Abstract interface for RevenueCat SDK operations.
///
/// This interface provides testability by allowing tests to use a fake
/// implementation while production code uses the real SDK.
///
/// ## Nullability Contract (Design Principle #9: Unknown vs None)
///
/// The return type of [getEntitlementSnapshot] is deliberately nullable to
/// distinguish between:
///
/// - `null` = RC unavailable (web stub, not configured, hard SDK failure)
///   The resolver should fallback to DB status. NOTE: Mobile SDK provides
///   cached CustomerInfo offline, so offline != null on mobile platforms.
///
/// - `EntitlementSnapshot` = RC responded (may be `.none()` = no entitlement)
///   This is authoritative - user genuinely has no entitlement.
///
/// ## Platform Implementations
///
/// - **Mobile (iOS/Android):** Uses `purchases_flutter` SDK via
///   `RevenueCatClientMobile`. Full functionality.
/// - **macOS:** Uses `purchases_flutter` SDK. Paywall UI may need verification.
/// - **Web:** Returns stub implementation (`RevenueCatClientStub`) that
///   returns `null` from [getEntitlementSnapshot] to trigger DB fallback.
abstract interface class RevenueCatClient {
  /// Configures the RevenueCat SDK with the given API key.
  ///
  /// **MUST be called before:** [logIn], [logOut], [getEntitlementSnapshot],
  /// [presentPaywall], [restorePurchases], and [entitlementChanges].
  ///
  /// Safe to call multiple times - SDK handles idempotency.
  ///
  /// [apiKey] is the platform-specific RevenueCat public API key.
  Future<void> configure(String apiKey);

  /// Identifies the user with RevenueCat.
  ///
  /// Must be called after the user authenticates. The [userId] should match
  /// the Supabase `auth.uid` to ensure consistency (INV-P5).
  ///
  /// This associates the device's anonymous RevenueCat user with the
  /// authenticated user, enabling:
  /// - Cross-device entitlement sync
  /// - Subscription restoration after reinstall
  /// - Correct `appUserId` in [EntitlementSnapshot]
  Future<void> logIn(String userId);

  /// Logs out the current user from RevenueCat.
  ///
  /// Resets the SDK to anonymous mode. Call this when the user logs out
  /// of the app.
  Future<void> logOut();

  /// Returns the current entitlement snapshot for the identified user.
  ///
  /// Returns `null` if:
  /// - RC is unavailable (web stub, not configured, hard SDK failure)
  /// - RC has not been configured yet
  ///
  /// Returns [EntitlementSnapshot] if RC responded:
  /// - `.none()` = user has no entitlement (authoritative)
  /// - Active snapshot = user has entitlement with details
  ///
  /// NOTE: Mobile SDK provides cached CustomerInfo even when offline.
  /// Only return `null` for true unavailability, not transient network issues.
  Future<EntitlementSnapshot?> getEntitlementSnapshot();

  /// Presents the RevenueCat paywall UI.
  ///
  /// Returns [PaywallOutcome.purchased] if the user completed a purchase,
  /// [PaywallOutcome.cancelled] if the user dismissed without purchasing,
  /// or [PaywallOutcome.error] if presentation failed.
  ///
  /// CRITICAL: Must be called only after [logIn] completes successfully.
  /// Purchasing as an anonymous user can cause entitlement ownership issues.
  Future<PaywallOutcome> presentPaywall();

  /// Restores purchases from the App Store / Play Store.
  ///
  /// CRITICAL for subscription correctness after:
  /// - Device change
  /// - App reinstall
  /// - Family sharing setup
  ///
  /// This is the #1 subscription correctness issue after launch.
  /// Must be exposed in Settings UI as "Restore Purchases" action.
  Future<void> restorePurchases();

  /// Stream of entitlement changes for real-time UI updates.
  ///
  /// Emits an [EntitlementSnapshot] whenever the user's entitlement state
  /// changes (e.g., after purchase, renewal, expiration, or billing issue).
  ///
  /// Only emits for the identified user (snapshots have `appUserId` set).
  /// Pre-identification emissions are ignored.
  ///
  /// **Web stub:** Returns an empty stream (never emits) since RC is
  /// unavailable on web.
  Stream<EntitlementSnapshot> get entitlementChanges;
}
