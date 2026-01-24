import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/date_time_extensions.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';

class HomeViewModel {
  final Logger _logger = Logger('Home');

  HomeViewModel({
    required NotifyService notifyService,
    required RouterService routerService,
    required AuthService authService,
    required UserRepository userRepository,
    required ProtocolRepository protocolRepository,
    required SessionRepository sessionRepository,
    required SessionLocalDataSource sessionLocalDataSource,
    required ConnectivityService connectivityService,
    HomeBottomTabCoordinator? tabCoordinator,
    CachedUserStore? cachedUserStore,
    TrialExpirationDecisionStore? trialExpirationDecisionStore,
  }) : _notifyService = notifyService,
       _routerService = routerService,
       _authService = authService,
       _userRepository = userRepository,
       _protocolRepository = protocolRepository,
       _sessionRepository = sessionRepository,
       _sessionLocalDataSource = sessionLocalDataSource,
       _connectivityService = connectivityService,
       _cachedUserStore = cachedUserStore,
       _trialExpirationDecisionStore = trialExpirationDecisionStore,
       _tabCoordinator =
           tabCoordinator ??
           HomeBottomTabCoordinator(
             routerService: routerService,
           );

  final NotifyService _notifyService;
  final RouterService _routerService;
  final AuthService _authService;
  final UserRepository _userRepository;
  final ProtocolRepository _protocolRepository;
  final SessionRepository _sessionRepository;
  final SessionLocalDataSource _sessionLocalDataSource;
  final ConnectivityService _connectivityService;
  final CachedUserStore? _cachedUserStore;
  final TrialExpirationDecisionStore? _trialExpirationDecisionStore;
  final HomeBottomTabCoordinator _tabCoordinator;

  final ValueNotifier<HomeViewState> state = ValueNotifier(
    const HomeViewState(),
  );

  bool _isLoading = false;
  bool _hasShownExpiredModal = false;
  VoidCallback? _connectivityListener;

  Future<void> init() async {
    _connectivityListener ??= _handleConnectivityChange;
    _connectivityService.status.removeListener(_connectivityListener!);
    _connectivityService.status.addListener(_connectivityListener!);

    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;
    state.value = _applyBanner(state.value.copyWith(isOffline: isOffline));

    await _loadHome(showLoading: true);
  }

  Future<void> refresh() async {
    await _loadHome(showLoading: false);
  }

  void dismissBanner() {
    final current = state.value;
    if (current.banner == null || !(current.banner?.isDismissible ?? false)) {
      return;
    }
    state.value = _applyBanner(
      current.copyWith(bannerDismissed: true, banner: null),
    );
  }

  void onTapBanner() {
    final banner = state.value.banner;
    if (banner == null || !banner.isTappable) {
      return;
    }

    switch (banner.type) {
      case HomeBannerType.trial:
      case HomeBannerType.expired:
        goToPaywall();
        break;
      case HomeBannerType.grace:
        state.value = state.value.copyWith(showGraceModal: true);
        break;
      case HomeBannerType.free:
      case HomeBannerType.offline:
        break;
    }
  }

  void onAddProtocol() {
    _routerService.replaceAll([Path(name: '/library')]);
  }

  void onBrowseLibrary() {
    _routerService.replaceAll([Path(name: '/library')]);
  }

  Future<void> onLogSession(String protocolId) async {
    final user = state.value.user;
    if (user == null) {
      return;
    }

    final now = DateTime.now();
    final result = user.canLogSession(
      protocolId,
      currentTime: now,
    );

    if (result.isLeft()) {
      final failure = result.getLeft().getOrElse(
        () => const DomainFailure(
          code: 'User.UnexpectedError',
          message: 'Unable to log session',
        ),
      );

      if (failure.code == UserFailures.tooManyActiveProtocols.code) {
        state.value = state.value.copyWith(showDeactivationModal: true);
        return;
      }

      _notifyService.setToastEvent(ToastEventError(message: failure.message));
    } else {
      // Resolve protocol to pass in the request
      final protocolResult = await _protocolRepository.getById(protocolId);
      if (protocolResult.isLeft()) {
        final failure = protocolResult.getLeft().getOrElse(
          () => const DomainFailure(
            code: 'Protocol.UnexpectedError',
            message: 'Unable to load protocol',
          ),
        );

        // Show user-friendly message for not-found, real message for other errors
        if (failure.code == 'Protocol.NotFound' ||
            failure.code == 'Protocol.InvalidReference') {
          _notifyService.setToastEvent(
            ToastEventError(message: 'Protocol unavailable'),
          );
          return;
        }

        _notifyService.setToastEvent(ToastEventError(message: failure.message));
        return;
      }

      final protocol = protocolResult.getOrElse(
        (_) => throw StateError('Unreachable'),
      );

      state.value = state.value.copyWith(
        logSessionRequest: LogSessionRequest(
          protocol: protocol,
          initialDate: now,
        ),
      );
    }
  }

  void onSelectBottomTab(HomeBottomTab tab) {
    _tabCoordinator.onSelect(
      tab,
      currentTab: state.value.activeTab,
    );
  }

  /// Attempts to transition the user to free tier.
  /// Returns true if successful, false if deactivation is required or save failed.
  Future<bool> handleUseFreeTier() async {
    final user = state.value.user;
    if (user == null) {
      return false;
    }

    if (user.activeProtocolCount > 2) {
      state.value = state.value.copyWith(showDeactivationModal: true);
      return false;
    }

    // ≤2 protocols: transition to free tier
    final updatedUser = user.updateSubscriptionStatus(SubscriptionStatus.free);

    final saveResult = await _userRepository.save(updatedUser);
    var success = false;
    await saveResult.fold(
      (failure) async {
        _notifyService.setToastEvent(ToastEventError(message: failure.message));
      },
      (_) async {
        success = true;
        try {
          await _cachedUserStore?.saveUser(updatedUser);
        } catch (e) {
          _logger.fine('Cached user save failed: $e');
        }
        await refresh();
      },
    );
    return success;
  }

  void acknowledgeTrialExpiredModal() {
    state.value = state.value.copyWith(showTrialExpiredModal: false);
  }

  void acknowledgeGraceModal() {
    state.value = state.value.copyWith(showGraceModal: false);
  }

  void acknowledgeDeactivationModal() {
    state.value = state.value.copyWith(showDeactivationModal: false);
  }

  void acknowledgeLogSessionRequest() {
    state.value = state.value.copyWith(logSessionRequest: null);
  }

  /// Marks the trial expiration decision as resolved for the current user.
  /// Call this after the user makes a choice (subscribe or use free tier).
  Future<void> markTrialExpiredDecisionResolved() async {
    final user = state.value.user;
    if (user?.trialPeriod == null) return;

    await _trialExpirationDecisionStore?.markResolved(
      userId: user!.id,
      trialStartDate: user.trialPeriod!.startDate,
    );
  }

  /// Checks if the expired modal should be shown for the given user.
  /// Used by both the initial trigger and the paywall-return loop.
  bool isTrialOrPremiumExpired(User user) {
    final now = DateTime.now();

    // Trial expired: raw status is trial AND trialPeriod has ended.
    // We check raw status (not effectiveStatus) so users who chose free tier
    // don't re-trigger the modal on subsequent app launches.
    final isTrialExpired =
        user.subscriptionStatus == SubscriptionStatus.trial &&
        (user.trialPeriod?.isExpired(now) ?? false);

    // Premium expired: RevenueCat subscription lapsed
    final isPremiumExpired =
        user.subscriptionStatus == SubscriptionStatus.expired;

    return isTrialExpired || isPremiumExpired;
  }

  Future<void> goToPaywall() {
    final completer = Completer<void>();
    var paywallWasEverPresent = false;

    void listener() {
      // When paywall is no longer in the stack, complete the future.
      // Use uri.path instead of pathWithParams to be resilient to query params.
      final stack = _routerService.navigationStack.value;
      final hasPaywall = stack.any((r) => r.uri.path == '/paywall');

      // Track if paywall was ever added to the stack
      if (hasPaywall) {
        paywallWasEverPresent = true;
      }

      // Only complete if paywall was present and is now gone (user dismissed it)
      // or if it was never added (navigation was a no-op/redirect)
      if (!hasPaywall && !completer.isCompleted) {
        // If paywall was never present, defer check to event queue to allow
        // async navigation to complete. Use Future() (event queue) not
        // Future.microtask() since navigation may update on the event queue.
        if (!paywallWasEverPresent) {
          Future(() {
            final currentStack = _routerService.navigationStack.value;
            final stillNoPaywall = !currentStack.any(
              (r) => r.uri.path == '/paywall',
            );
            if (stillNoPaywall && !completer.isCompleted) {
              _routerService.navigationStack.removeListener(listener);
              completer.complete();
            }
          });
        } else {
          _routerService.navigationStack.removeListener(listener);
          completer.complete();
        }
      }
    }

    _routerService.navigationStack.addListener(listener);
    _routerService.goTo(Path(name: '/paywall'));

    // Handle no-op/redirect-without-stack-change cases
    listener();

    return completer.future;
  }

  void dispose() {
    if (_connectivityListener != null) {
      _connectivityService.status.removeListener(_connectivityListener!);
    }
    state.dispose();
  }

  Future<void> _loadHome({required bool showLoading}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    final current = state.value;
    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;

    state.value = _applyBanner(
      current.copyWith(
        status: showLoading ? HomeStatus.loading : current.status,
        isRefreshing: !showLoading,
        isOffline: isOffline,
        errorMessage: null,
      ),
    );

    final userId = _resolveUserId();
    if (userId == null) {
      _setError('Unable to load user.');
      return;
    }

    final userResult = await _userRepository.getById(userId);
    if (userResult.isLeft()) {
      _setError(_failureMessage(userResult));
      return;
    }

    final user = userResult.getOrElse((_) => throw StateError('Unreachable'));
    final cards = await _loadCards(user);
    if (cards == null) {
      return;
    }

    final status = user.activeProtocolIds.isEmpty
        ? HomeStatus.empty
        : HomeStatus.populated;

    final latest = state.value;
    var next = latest.copyWith(
      status: status,
      user: user,
      cards: cards,
      isRefreshing: false,
      errorMessage: null,
    );

    next = await _maybeTriggerExpiredModal(next, user);
    state.value = _applyBanner(next);
    _isLoading = false;
  }

  Future<List<HomeProtocolCardModel>?> _loadCards(User user) async {
    final protocolIds = user.activeProtocolIds;
    if (protocolIds.isEmpty) {
      return <HomeProtocolCardModel>[];
    }

    final now = DateTime.now();
    final userId = user.id;
    final isOnline = _connectivityService.status.value == NetworkStatus.online;

    // If online, fetch from remote and upsert to local cache (best-effort)
    // Remote sync failure is non-fatal: we fall back to cached + pending sessions
    if (isOnline) {
      final sessionsResult = await _sessionRepository.list(
        from: now.startOfDay,
        to: now.endOfDay,
      );

      await sessionsResult.fold(
        (failure) async {
          // Non-fatal: continue with cached + pending sessions
          _logger.fine('Remote session fetch failed: ${failure.code}');
        },
        (remoteSessions) async {
          try {
            await _sessionLocalDataSource.upsertSyncedSessions(
              userId,
              remoteSessions,
            );
          } catch (e) {
            // Cache write failure is also non-fatal
            _logger.fine('Session cache upsert failed: $e');
          }
        },
      );
    }

    // Read combined sessions (synced + pending) from local data source
    final sessions = await _sessionLocalDataSource.listSessions(
      userId,
      from: now.startOfDay,
      to: now.endOfDay,
    );

    final loggedToday = _mapLoggedToday(sessions);

    final cards = <HomeProtocolCardModel>[];
    for (final protocolId in protocolIds) {
      final protocolResult = await _protocolRepository.getById(protocolId);
      if (protocolResult.isLeft()) {
        final failure = protocolResult.getLeft().getOrElse(
          () => const DomainFailure(
            code: 'Protocol.UnexpectedError',
            message: 'Unable to load protocol',
          ),
        );
        if (failure.code == 'Protocol.NotFound' ||
            failure.code == 'Protocol.InvalidReference') {
          cards.add(_buildUnavailableCard(protocolId));
          continue;
        }
        _setError(failure.message);
        return null;
      }

      final protocol = protocolResult.getOrElse(
        (_) => throw StateError('Unreachable'),
      );
      cards.add(
        _buildCard(
          protocol,
          loggedToday[protocolId] ?? false,
        ),
      );
    }

    return cards;
  }

  HomeProtocolCardModel _buildCard(Protocol protocol, bool loggedToday) {
    return HomeProtocolCardModel(
      protocolId: protocol.id,
      title: protocol.name.value,
      categoryLabel: protocol.category.displayName.toUpperCase(),
      quickReference: protocol.target.displayText,
      loggedToday: loggedToday,
      isUnavailable: false,
    );
  }

  HomeProtocolCardModel _buildUnavailableCard(String protocolId) {
    return HomeProtocolCardModel(
      protocolId: protocolId,
      title: 'Protocol unavailable',
      categoryLabel: 'UNAVAILABLE',
      quickReference: 'This protocol is no longer in the library.',
      loggedToday: false,
      isUnavailable: true,
    );
  }

  Map<String, bool> _mapLoggedToday(List<Session> sessions) {
    final loggedToday = <String, bool>{};
    for (final session in sessions) {
      loggedToday[session.protocolId] = true;
    }
    return loggedToday;
  }

  String? _resolveUserId() {
    final authState = _authService.authState.value;
    if (authState is AuthenticatedOnline) {
      return authState.user.id;
    }
    if (authState is AuthenticatedOffline) {
      return authState.user.id;
    }
    return null;
  }

  Future<HomeViewState> _maybeTriggerExpiredModal(
    HomeViewState state,
    User user,
  ) async {
    if (_hasShownExpiredModal) {
      return state.copyWith(showTrialExpiredModal: false);
    }

    final now = DateTime.now();
    final isTrialExpired =
        user.subscriptionStatus == SubscriptionStatus.trial &&
        (user.trialPeriod?.isExpired(now) ?? false);
    final isPremiumExpired =
        user.subscriptionStatus == SubscriptionStatus.expired;

    if (!isTrialExpired && !isPremiumExpired) {
      return state.copyWith(showTrialExpiredModal: false);
    }

    // Check if already resolved (persisted across app restarts)
    if (isTrialExpired && user.trialPeriod != null) {
      final alreadyResolved =
          await _trialExpirationDecisionStore?.isResolved(
            userId: user.id,
            trialStartDate: user.trialPeriod!.startDate,
          ) ??
          false;
      if (alreadyResolved) {
        return state.copyWith(showTrialExpiredModal: false);
      }
    }

    _hasShownExpiredModal = true;
    return state.copyWith(showTrialExpiredModal: true);
  }

  void _handleConnectivityChange() {
    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;
    state.value = _applyBanner(state.value.copyWith(isOffline: isOffline));
  }

  HomeViewState _applyBanner(HomeViewState next) {
    return next.copyWith(banner: _buildBanner(next));
  }

  HomeBannerModel? _buildBanner(HomeViewState next) {
    if (next.isOffline) {
      return const HomeBannerModel(
        type: HomeBannerType.offline,
        message: 'Offline mode',
        isTappable: false,
        isDismissible: false,
      );
    }

    if (next.bannerDismissed || next.user == null) {
      return null;
    }

    final user = next.user!;
    switch (user.subscriptionStatus) {
      case SubscriptionStatus.trial:
        final trial = user.trialPeriod;
        if (trial == null) {
          return null;
        }
        if (trial.isExpired(DateTime.now())) {
          // Trial has expired: show expired banner (tappable to paywall)
          // to provide a recovery path for users who haven't yet decided.
          return const HomeBannerModel(
            type: HomeBannerType.expired,
            message: 'Trial has ended',
            isTappable: true,
          );
        }
        return HomeBannerModel(
          type: HomeBannerType.trial,
          message: trial.displayText(DateTime.now()),
          isTappable: true,
        );
      case SubscriptionStatus.free:
        final limit =
            user.subscriptionStatus.protocolLimit ?? user.activeProtocolCount;
        return HomeBannerModel(
          type: HomeBannerType.free,
          message: '${user.activeProtocolCount}/$limit active',
          isTappable: false,
        );
      case SubscriptionStatus.expired:
        return const HomeBannerModel(
          type: HomeBannerType.expired,
          message: 'Subscription has lapsed',
          isTappable: true,
        );
      case SubscriptionStatus.grace:
        return const HomeBannerModel(
          type: HomeBannerType.grace,
          message: 'Payment issue',
          isTappable: true,
        );
      case SubscriptionStatus.premiumMonthly:
      case SubscriptionStatus.premiumAnnual:
        return null;
    }
  }

  String _failureMessage<T>(Either<DomainFailure, T> result) {
    final failure = result.getLeft().getOrElse(
      () => const DomainFailure(
        code: 'Home.UnexpectedError',
        message: 'Unable to load home data',
      ),
    );
    return failure.message;
  }

  void _setError(String message) {
    state.value = _applyBanner(
      state.value.copyWith(
        status: HomeStatus.error,
        errorMessage: message,
        isRefreshing: false,
      ),
    );
    _isLoading = false;
  }
}
