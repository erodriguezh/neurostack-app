import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/cached_user_store.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/user/domain/entities/user.dart';
import '../../paywall/domain/entitlement.dart';
import '../../paywall/domain/subscription_status_resolver.dart';
import 'entitlement_listener_mixin.dart';

/// Mixin that provides a reactive [entitlement] notifier backed by
/// [EntitlementListenerMixin].
///
/// Eliminates the ~40 lines of boilerplate that every ViewModel needs when it
/// must track what the current user can do:
///
/// - Synchronous initial computation (no flicker on screen load)
/// - Live updates via [EntitlementListenerMixin]
/// - Fallback to [CachedUserStore] when auth state is unexpectedly
///   non-authenticated
///
/// ## Usage
///
/// ```dart
/// class MyViewModel with EntitlementListenerMixin, PremiumAwareViewModelMixin {
///   MyViewModel({
///     required AuthService authService,
///     required SubscriptionStatusResolver subscriptionStatusResolver,
///     required RevenueCatService revenueCatService,
///     CachedUserStore? cachedUserStore,
///   }) : _authService = authService,
///        _resolver = subscriptionStatusResolver,
///        _revenueCatService = revenueCatService,
///        _cachedUserStore = cachedUserStore;
///
///   // Wire the abstract getters to your private fields:
///   @override
///   AuthService get premiumAuthService => _authService;
///   @override
///   SubscriptionStatusResolver get premiumResolver => _resolver;
///   @override
///   RevenueCatService get entitlementListenerService => _revenueCatService;
///   @override
///   CachedUserStore? get premiumCachedUserStore => _cachedUserStore;
///   // ...
/// }
/// ```
///
/// Then in your init: `initPremiumAwareness(); initEntitlementListener();`
/// And in dispose: `disposePremiumAwareness(); disposeEntitlementListener();`
mixin PremiumAwareViewModelMixin on EntitlementListenerMixin {
  // ---------------------------------------------------------------------------
  // Abstract contract — the consuming class wires these to its private fields
  // ---------------------------------------------------------------------------

  /// The auth service used to resolve the current user synchronously.
  AuthService get premiumAuthService;

  /// The resolver that combines DB subscription status with the RevenueCat
  /// entitlement snapshot to determine effective status.
  SubscriptionStatusResolver get premiumResolver;

  /// Optional cached-user store for defensive fallback when auth state is
  /// unexpectedly non-authenticated on an auth-required route.
  CachedUserStore? get premiumCachedUserStore;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Resolved entitlement for the current user.
  ///
  /// Computed synchronously on [initPremiumAwareness] to avoid flicker, then
  /// kept up-to-date via [EntitlementListenerMixin].
  late final ValueNotifier<Entitlement> entitlement;

  /// Whether the current user has a premium subscription.
  bool get isPremium => entitlement.value.isPremium;

  bool _premiumDisposed = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initializes the [entitlement] notifier with a synchronous computation.
  ///
  /// Must be called **before** the first frame that reads [entitlement].
  /// Typically called during construction or in an `init()` method.
  void initPremiumAwareness() {
    entitlement = ValueNotifier<Entitlement>(_computeEntitlement());
  }

  /// Disposes the [entitlement] notifier. Safe to call multiple times.
  void disposePremiumAwareness() {
    if (_premiumDisposed) return;
    _premiumDisposed = true;
    entitlement.dispose();
  }

  // ---------------------------------------------------------------------------
  // EntitlementListenerMixin callback
  // ---------------------------------------------------------------------------

  /// Default implementation of [onEntitlementChanged] that re-computes
  /// [entitlement] from the current auth state and entitlement snapshot.
  ///
  /// If the auth state is unexpectedly non-authenticated, falls back to
  /// [premiumCachedUserStore] (async, best-effort).
  ///
  /// Subclasses that need additional behaviour (e.g., refreshing a list)
  /// should override this and call `super.onEntitlementChanged()` first.
  @override
  void onEntitlementChanged() {
    if (_premiumDisposed) return;

    final user = resolveAuthUser();
    if (user != null) {
      _updateEntitlement(user);
      return;
    }

    // Defensive fallback: auth state is unexpectedly non-authenticated on an
    // auth-required route. Try CachedUserStore (async, best-effort).
    premiumCachedUserStore
        ?.loadUser()
        .then((cached) {
          if (cached != null && !_premiumDisposed) _updateEntitlement(cached);
        })
        .catchError((_) {});
  }

  // ---------------------------------------------------------------------------
  // Helpers (protected — available to subclasses)
  // ---------------------------------------------------------------------------

  /// Resolves the current user synchronously from [AuthService.authState].
  ///
  /// Returns `null` if the auth state is not authenticated. When `null`,
  /// callers should fall back to [premiumCachedUserStore] if available.
  @protected
  User? resolveAuthUser() {
    final authState = premiumAuthService.authState.value;
    return switch (authState) {
      AuthenticatedOnline(:final user) => user,
      AuthenticatedOffline(:final user) => user,
      _ => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Entitlement _computeEntitlement() {
    final user = resolveAuthUser();
    if (user == null) return Entitlement.fallback;

    final snapshot = entitlementListenerService.entitlementSnapshot.value;
    return Entitlement.of(user, snapshot);
  }

  void _updateEntitlement(User user) {
    if (_premiumDisposed) return;
    final snapshot = entitlementListenerService.entitlementSnapshot.value;
    entitlement.value = Entitlement.of(user, snapshot);
  }
}
