import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_state.dart';

class HomeViewModel {
  HomeViewModel({
    required NotifyService notifyService,
    required RouterService routerService,
    required AuthService authService,
    required UserRepository userRepository,
    required ProtocolRepository protocolRepository,
    required SessionRepository sessionRepository,
    required ConnectivityService connectivityService,
  })  : _notifyService = notifyService,
        _routerService = routerService,
        _authService = authService,
        _userRepository = userRepository,
        _protocolRepository = protocolRepository,
        _sessionRepository = sessionRepository,
        _connectivityService = connectivityService;

  final NotifyService _notifyService;
  final RouterService _routerService;
  final AuthService _authService;
  final UserRepository _userRepository;
  final ProtocolRepository _protocolRepository;
  final SessionRepository _sessionRepository;
  final ConnectivityService _connectivityService;

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

  void onLogSession(String protocolId) {
    final user = state.value.user;
    if (user == null) {
      return;
    }

    final result = user.canLogSession(
      protocolId,
      currentTime: DateTime.now(),
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
    }
  }

  void onSelectBottomTab(HomeBottomTab tab) {
    if (tab == HomeBottomTab.stack) {
      return;
    }

    if (tab == HomeBottomTab.library) {
      _routerService.replaceAll([Path(name: '/library')]);
      return;
    }

    _notifyService.setToastEvent(
      ToastEventInfo(message: 'Coming soon'),
    );
  }

  void handleUseFreeTier() {
    final user = state.value.user;
    if (user == null) {
      return;
    }

    if (user.activeProtocolCount > 2) {
      state.value = state.value.copyWith(showDeactivationModal: true);
    }
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

  void goToPaywall() {
    _routerService.goTo(Path(name: '/paywall'));
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

    next = _maybeTriggerExpiredModal(next, user);
    state.value = _applyBanner(next);
    _isLoading = false;
  }

  Future<List<HomeProtocolCardModel>?> _loadCards(User user) async {
    final protocolIds = user.activeProtocolIds;
    if (protocolIds.isEmpty) {
      return <HomeProtocolCardModel>[];
    }

    final now = DateTime.now();
    final sessionsResult = await _sessionRepository.list(
      from: _startOfDay(now),
      to: _endOfDay(now),
    );

    if (sessionsResult.isLeft()) {
      _setError(_failureMessage(sessionsResult));
      return null;
    }

    final sessions =
        sessionsResult.getOrElse((_) => throw StateError('Unreachable'));
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

      final protocol =
          protocolResult.getOrElse((_) => throw StateError('Unreachable'));
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

  DateTime _startOfDay(DateTime now) {
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _endOfDay(DateTime now) {
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
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

  HomeViewState _maybeTriggerExpiredModal(HomeViewState state, User user) {
    if (_hasShownExpiredModal) {
      return state.copyWith(showTrialExpiredModal: false);
    }

    if (user.subscriptionStatus == SubscriptionStatus.expired) {
      _hasShownExpiredModal = true;
      return state.copyWith(showTrialExpiredModal: true);
    }

    return state.copyWith(showTrialExpiredModal: false);
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
          final limit =
              SubscriptionStatus.free.protocolLimit ?? user.activeProtocolCount;
          return HomeBannerModel(
            type: HomeBannerType.free,
            message: '${user.activeProtocolCount}/$limit active',
            isTappable: false,
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
