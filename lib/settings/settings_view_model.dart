import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:neurostack/core/abstractions/entitlement_listener_mixin.dart';
import 'package:neurostack/core/abstractions/premium_aware_view_model_mixin.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/userorient/userorient_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    required RevenueCatService revenueCatService,
    required UserOrientService userOrientService,
    required NotifyService notifyService,
    required PackageInfo packageInfo,
    CachedUserStore? cachedUserStore,
    HomeBottomTabCoordinator? tabCoordinator,
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  }) : _routerService = routerService,
       _authService = authService,
       _revenueCatService = revenueCatService,
       _userOrientService = userOrientService,
       _notifyService = notifyService,
       _packageInfo = packageInfo,
       _cachedUserStore = cachedUserStore,
       _tabCoordinator =
           tabCoordinator ??
           HomeBottomTabCoordinator(routerService: routerService),
       _launch = launch ?? launchUrl {
    initPremiumAwareness();
    canAccessPremium = ValueNotifier<bool>(_computeCanAccessPremium());
  }

  final RouterService _routerService;
  final AuthService _authService;
  final RevenueCatService _revenueCatService;
  final UserOrientService _userOrientService;
  final NotifyService _notifyService;
  final PackageInfo _packageInfo;
  final CachedUserStore? _cachedUserStore;
  final HomeBottomTabCoordinator _tabCoordinator;
  final Future<bool> Function(Uri, {LaunchMode mode}) _launch;

  bool _isDisposed = false;
  bool _isRestoring = false;

  /// Whether the user can access premium features (premium + trial).
  late final ValueNotifier<bool> canAccessPremium;

  // --- Mixin wiring ---

  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;

  @override
  AuthService get premiumAuthService => _authService;

  @override
  CachedUserStore? get premiumCachedUserStore => _cachedUserStore;

  @override
  void onEntitlementChanged() {
    if (_isDisposed) return;
    super.onEntitlementChanged();
    _refreshCanAccessPremium();
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
  /// Extracts the current user and derives
  /// `isPaying` from the resolved subscription status. No-ops when the
  /// user is not authenticated.
  void openFeatureRequestBoard(BuildContext context) {
    final user = resolveAuthUser();
    if (user == null) return;

    final isPaying = _resolveEntitlement(user).isPremium;

    _userOrientService.openBoard(context, userId: user.id, isPaying: isPaying);
  }

  /// Sends feedback by opening the device email client with a pre-filled
  /// mailto link containing diagnostic context.
  ///
  /// No-ops when the user is not authenticated.
  Future<void> sendFeedback() async {
    final user = resolveAuthUser();
    if (user == null) return;

    final effectiveStatus = _resolveEntitlement(user).effectiveStatus;

    final uri = Uri(
      scheme: 'mailto',
      path: 'feedback@getneurostack.app',
      query: _encodeQueryParameters({
        'subject': 'NeuroStack Feedback',
        'body':
            'App Version: ${_packageInfo.version}+${_packageInfo.buildNumber}\n'
            'Platform: ${defaultTargetPlatform.name}\n'
            'Subscription: ${effectiveStatus.name}',
      }),
    );

    const mode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    try {
      await _launch(uri, mode: mode);
    } catch (_) {
      // Best-effort: launchUrl can throw on some platforms/embedders.
    }
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

  /// Restores purchases via RevenueCat.
  ///
  /// Shows a toast based on the outcome:
  /// - Success + entitlement active → success toast
  /// - Success + no entitlement → info toast (no purchases found)
  /// - Failure → error toast
  ///
  /// Guarded by [_isRestoring] to prevent concurrent restore calls.
  Future<void> restorePurchases() async {
    if (_isRestoring) return;
    _isRestoring = true;

    try {
      final success = await _revenueCatService.restorePurchases();
      if (_isDisposed) return;

      if (success) {
        final snapshot = _revenueCatService.entitlementSnapshot.value;
        final user = resolveAuthUser();
        final isEntitled = snapshot != null &&
            user != null &&
            snapshot.isForUser(user.id) &&
            snapshot.hasProEntitlement;
        if (isEntitled) {
          _notifyService.setToastEvent(
            ToastEventSuccess(message: 'Purchases restored successfully'),
          );
        } else {
          _notifyService.setToastEvent(
            ToastEventInfo(message: 'No previous purchases found'),
          );
        }
      } else {
        _notifyService.setToastEvent(
          ToastEventError(
            message: 'Unable to restore purchases. Please try again.',
          ),
        );
      }
    } catch (_) {
      if (_isDisposed) return;
      _notifyService.setToastEvent(
        ToastEventError(
          message: 'Unable to restore purchases. Please try again.',
        ),
      );
    } finally {
      _isRestoring = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    canAccessPremium.dispose();
    disposeEntitlementListener();
    disposePremiumAwareness();
  }

  // --- Private helpers ---

  bool _computeCanAccessPremium() {
    final user = resolveAuthUser();
    if (user == null) return false;

    return _resolveEntitlement(user).canAccessPremium;
  }

  void _refreshCanAccessPremium() {
    final user = resolveAuthUser();
    if (user != null) {
      canAccessPremium.value = _resolveEntitlement(user).canAccessPremium;
    } else {
      premiumCachedUserStore
          ?.loadUser()
          .then((cached) {
            if (cached == null || _isDisposed) return;
            canAccessPremium.value =
                _resolveEntitlement(cached).canAccessPremium;
          })
          .catchError((_) {});
    }
  }

  Entitlement _resolveEntitlement(User user) {
    final snapshot = entitlementListenerService.entitlementSnapshot.value;
    return Entitlement.of(user, snapshot);
  }

  /// Encodes query parameters for a mailto URI using [Uri.encodeComponent]
  /// per value instead of [Uri.queryParameters] which encodes spaces as `+`.
  ///
  /// See: https://github.com/dart-lang/sdk/issues/43838
  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
