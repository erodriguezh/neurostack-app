import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:neurostack/core/abstractions/entitlement_listener_mixin.dart';
import 'package:neurostack/core/abstractions/premium_aware_view_model_mixin.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/userorient/userorient_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:url_launcher/url_launcher.dart';

/// ViewModel for SettingsView.
///
/// Manages subscription awareness (via [PremiumAwareViewModelMixin]),
/// tab coordination, and navigation to paywall, contact, and
/// subscription management screens.
class SettingsViewModel
    with EntitlementListenerMixin, PremiumAwareViewModelMixin {
  SettingsViewModel({
    required RouterService routerService,
    required AuthService authService,
    required SubscriptionStatusResolver subscriptionStatusResolver,
    required RevenueCatService revenueCatService,
    required UserOrientService userOrientService,
    CachedUserStore? cachedUserStore,
    HomeBottomTabCoordinator? tabCoordinator,
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  }) : _routerService = routerService,
       _authService = authService,
       _resolver = subscriptionStatusResolver,
       _revenueCatService = revenueCatService,
       _userOrientService = userOrientService,
       _cachedUserStore = cachedUserStore,
       _tabCoordinator =
           tabCoordinator ??
           HomeBottomTabCoordinator(routerService: routerService),
       _launch = launch ?? launchUrl {
    initPremiumAwareness();
  }

  final RouterService _routerService;
  final AuthService _authService;
  final SubscriptionStatusResolver _resolver;
  final RevenueCatService _revenueCatService;
  final UserOrientService _userOrientService;
  final CachedUserStore? _cachedUserStore;
  final HomeBottomTabCoordinator _tabCoordinator;
  final Future<bool> Function(Uri, {LaunchMode mode}) _launch;

  bool _isDisposed = false;

  // --- Mixin wiring ---

  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;

  @override
  AuthService get premiumAuthService => _authService;

  @override
  SubscriptionStatusResolver get premiumResolver => _resolver;

  @override
  CachedUserStore? get premiumCachedUserStore => _cachedUserStore;

  @override
  void onEntitlementChanged() {
    if (_isDisposed) return;
    super.onEntitlementChanged();
  }

  // --- Public API ---

  /// Initializes the entitlement listener for live subscription updates.
  ///
  /// Must be called from the view's `initState()`.
  void init() {
    initEntitlementListener();
    // Sync once after wiring the listener to close the window between
    // construction (which computes isPremium) and listener attachment.
    onEntitlementChanged();
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

  /// Navigates to the Rate App screen.
  void goToRateApp() {
    _routerService.goTo(Path(name: '/settings/rate-app'));
  }

  /// Opens the UserOrient feature-request board.
  ///
  /// Extracts the user ID from the current [AuthState] and derives
  /// `isPaying` from the resolved subscription status. No-ops when the
  /// user is not authenticated.
  void openFeatureRequestBoard(BuildContext context) {
    final state = _authService.authState.value;
    final user = switch (state) {
      AuthenticatedOnline(user: final u) => u,
      AuthenticatedOffline(user: final u) => u,
      _ => null,
    };
    if (user == null) return;

    final isPaying = _resolver
        .resolveEffectiveStatus(
          user: user,
          snapshot: _revenueCatService.entitlementSnapshot.value,
        )
        .isPremium;

    _userOrientService.openBoard(context, userId: user.id, isPaying: isPaying);
  }

  /// Opens the platform-specific subscription management page.
  ///
  /// On iOS/macOS, opens the App Store subscriptions page.
  /// On Android, opens the Play Store subscriptions page.
  /// No-ops on unsupported platforms (Windows, Linux, Fuchsia).
  Future<void> openSubscriptionManagement() async {
    final uri = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        Uri.parse('https://play.google.com/store/account/subscriptions'),
      TargetPlatform.iOS || TargetPlatform.macOS =>
        Uri.parse('https://apps.apple.com/account/subscriptions'),
      _ => null, // Unsupported platform
    };

    if (uri == null) return;

    const mode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    try {
      await _launch(uri, mode: mode);
    } catch (_) {
      // Best-effort: launchUrl can throw on some platforms/embedders.
    }
  }

  void dispose() {
    _isDisposed = true;
    disposeEntitlementListener();
    disposePremiumAwareness();
  }
}
