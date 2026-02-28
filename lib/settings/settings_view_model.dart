import 'package:flutter/foundation.dart';
import 'package:neurostack/core/abstractions/entitlement_listener_mixin.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for SettingsView.
///
/// Manages subscription awareness (via [EntitlementListenerMixin]),
/// tab coordination, and navigation to paywall, contact, and
/// subscription management screens.
class SettingsViewModel with EntitlementListenerMixin {
  SettingsViewModel({
    required RouterService routerService,
    required AuthService authService,
    required SubscriptionStatusResolver subscriptionStatusResolver,
    required RevenueCatService revenueCatService,
    CachedUserStore? cachedUserStore,
    HomeBottomTabCoordinator? tabCoordinator,
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  }) : _routerService = routerService,
       _authService = authService,
       _resolver = subscriptionStatusResolver,
       _revenueCatService = revenueCatService,
       _tabCoordinator =
           tabCoordinator ??
           HomeBottomTabCoordinator(routerService: routerService),
       _launch = launch ?? launchUrl,
       isPremium = ValueNotifier<bool>(_computeInitialIsPremium(
         authService: authService,
         resolver: subscriptionStatusResolver,
         revenueCatService: revenueCatService,
       ));

  final RouterService _routerService;
  final AuthService _authService;
  final SubscriptionStatusResolver _resolver;
  final RevenueCatService _revenueCatService;
  final HomeBottomTabCoordinator _tabCoordinator;
  final Future<bool> Function(Uri, {LaunchMode mode}) _launch;

  /// Whether the current user has a premium subscription.
  ///
  /// Computed synchronously on construction to avoid flicker, then kept
  /// up-to-date via [EntitlementListenerMixin].
  final ValueNotifier<bool> isPremium;

  // --- Mixin wiring ---

  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;

  @override
  void onEntitlementChanged() {
    final user = _resolveUser();
    if (user == null) return;

    final snapshot = _revenueCatService.entitlementSnapshot.value;
    final status = _resolver.resolveEffectiveStatus(
      user: user,
      snapshot: snapshot,
    );
    isPremium.value = status.isPremium;
  }

  // --- Public API ---

  /// Initializes the entitlement listener for live subscription updates.
  ///
  /// Must be called from the view's `initState()`.
  void init() {
    initEntitlementListener();
  }

  /// Navigates to a different bottom tab.
  void onSelectBottomTab(HomeBottomTab tab) {
    _tabCoordinator.onSelect(tab, currentTab: HomeBottomTab.settings);
  }

  /// Navigates to the paywall screen.
  void goToPaywall() {
    _routerService.goTo(Path(name: '/paywall'));
  }

  /// Navigates to the contact screen.
  void goToContact() {
    _routerService.goTo(Path(name: '/settings/contact'));
  }

  /// Opens the platform-specific subscription management page.
  ///
  /// On iOS, opens the App Store subscriptions page.
  /// On Android, opens the Play Store subscriptions page.
  /// On web, falls back to `LaunchMode.platformDefault`.
  Future<void> openSubscriptionManagement() async {
    final uri = defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse('https://play.google.com/store/account/subscriptions')
        : Uri.parse('https://apps.apple.com/account/subscriptions');

    const mode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    await _launch(uri, mode: mode);
  }

  void dispose() {
    disposeEntitlementListener();
    isPremium.dispose();
  }

  // --- Private helpers ---

  /// Resolves the current user synchronously from [AuthService.authState].
  ///
  /// Returns `null` if the auth state is not authenticated.
  /// Falls back to [CachedUserStore] only if authState is unexpectedly
  /// unauthenticated (defensive, since the settings route requires auth).
  User? _resolveUser() {
    final authState = _authService.authState.value;
    return switch (authState) {
      AuthenticatedOnline(:final user) => user,
      AuthenticatedOffline(:final user) => user,
      _ => null,
    };
  }

  /// Computes the initial isPremium value synchronously to avoid flicker.
  ///
  /// Static so it can be called during field initialization (before `this`
  /// is available).
  static bool _computeInitialIsPremium({
    required AuthService authService,
    required SubscriptionStatusResolver resolver,
    required RevenueCatService revenueCatService,
  }) {
    final authState = authService.authState.value;
    final user = switch (authState) {
      AuthenticatedOnline(:final user) => user,
      AuthenticatedOffline(:final user) => user,
      _ => null,
    };

    if (user == null) return false;

    final snapshot = revenueCatService.entitlementSnapshot.value;
    final status = resolver.resolveEffectiveStatus(
      user: user,
      snapshot: snapshot,
    );
    return status.isPremium;
  }
}
