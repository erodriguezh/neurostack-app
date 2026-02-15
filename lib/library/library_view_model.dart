import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:neurostack/core/abstractions/connectivity_listener_mixin.dart';
import 'package:neurostack/core/abstractions/entitlement_listener_mixin.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/utils/auth_helpers.dart' as auth;
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/failure_helpers.dart' as helpers;
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/protocol/data/cached_protocol_store.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart'
    as protocol;
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/failures/user_failures.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_bottom_tab_coordinator.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/library_stats.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';

class LibraryViewModel
    with EntitlementListenerMixin, ConnectivityListenerMixin {
  final Logger _logger = Logger('Library');

  LibraryViewModel({
    required NotifyService notifyService,
    required RouterService routerService,
    required AuthService authService,
    required UserRepository userRepository,
    required ProtocolRepository protocolRepository,
    required SessionRepository sessionRepository,
    required ConnectivityService connectivityService,
    required SubscriptionStatusResolver subscriptionStatusResolver,
    required RevenueCatService revenueCatService,
    CachedUserStore? cachedUserStore,
    CachedProtocolStore? cachedProtocolStore,
    HomeBottomTabCoordinator? tabCoordinator,
  })  : _notifyService = notifyService,
        _routerService = routerService,
        _authService = authService,
        _userRepository = userRepository,
        _protocolRepository = protocolRepository,
        _sessionRepository = sessionRepository,
        _connectivityService = connectivityService,
        _resolver = subscriptionStatusResolver,
        _revenueCatService = revenueCatService,
        _cachedUserStore = cachedUserStore,
        _cachedProtocolStore = cachedProtocolStore,
        _tabCoordinator = tabCoordinator ??
            HomeBottomTabCoordinator(
              routerService: routerService,
            );

  final NotifyService _notifyService;
  final RouterService _routerService;
  final AuthService _authService;
  final UserRepository _userRepository;
  final ProtocolRepository _protocolRepository;
  final SessionRepository _sessionRepository;
  final ConnectivityService _connectivityService;
  final SubscriptionStatusResolver _resolver;
  final RevenueCatService _revenueCatService;
  final CachedUserStore? _cachedUserStore;
  final CachedProtocolStore? _cachedProtocolStore;
  final HomeBottomTabCoordinator _tabCoordinator;

  final ValueNotifier<LibraryViewState> state = ValueNotifier(
    const LibraryViewState(),
  );

  bool _isLoading = false;
  bool _isDisposed = false;
  User? _cachedUser;
  List<Protocol> _cachedProtocols = const [];
  String? _cachedProtocolsUserId;

  // --- Mixin wiring ---

  @override
  RevenueCatService get entitlementListenerService => _revenueCatService;

  @override
  ConnectivityService get connectivityListenerService => _connectivityService;

  @override
  void onEntitlementChanged() {
    _logger.fine('Entitlement changed, refreshing library');
    refresh();
  }

  @override
  void onConnectivityChanged() {
    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;
    final current = state.value;

    if (current.isOffline == isOffline) {
      return;
    }

    if (isOffline) {
      if (_cachedUser != null &&
          _cachedProtocols.isNotEmpty &&
          _cachedProtocolsUserId == _cachedUser!.id) {
        final snapshot = _revenueCatService.entitlementSnapshot.value;
        final cards = _buildCards(
          _cachedUser!,
          _cachedProtocols,
          snapshot: snapshot,
          isOffline: true,
        );
        final sections = _buildSections(cards);
        state.value = current.copyWith(
          isOffline: true,
          cards: cards,
          sections: sections,
        );
        return;
      }

      state.value = current.copyWith(isOffline: true);
      return;
    }

    state.value = current.copyWith(isOffline: false);
    _loadLibrary(
      showLoading: current.cards.isEmpty,
      preferCacheWhenOffline: false,
    );
  }

  // --- Public API ---

  Future<void> init() async {
    initConnectivityListener();
    initEntitlementListener();

    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;
    state.value = state.value.copyWith(isOffline: isOffline);

    await _loadLibrary(showLoading: true);
  }

  Future<void> refresh() async {
    await _loadLibrary(showLoading: false);
  }

  void onSelectBottomTab(HomeBottomTab tab) {
    _tabCoordinator.onSelect(
      tab,
      currentTab: state.value.activeTab,
    );
  }

  void goToPaywall() {
    _routerService.goTo(Path(name: '/paywall'));
  }

  void onLogSession(String protocolId) {
    final user = state.value.user;
    if (user == null) {
      return;
    }

    final result = user.canLogSession(protocolId);

    if (result.isLeft()) {
      final failure = result.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to log session',
            ),
          );
      _notifyService.setToastEvent(ToastEventError(message: failure.message));
      return;
    }

    _notifyService.setToastEvent(
      ToastEventInfo(message: 'Log session flow coming soon'),
    );
  }

  Future<void> addProtocol(String protocolId) async {
    if (state.value.isOffline) {
      _notifyOffline();
      return;
    }

    final user = _cachedUser ?? state.value.user;
    if (user == null) {
      return;
    }

    final result = user.activateProtocol(protocolId);

    if (result.isLeft()) {
      final failure = result.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to activate protocol',
            ),
          );

      if (failure.code == UserFailures.protocolLimitReached.code) {
        goToPaywall();
        return;
      }

      _notifyService.setToastEvent(ToastEventWarning(message: failure.message));
      return;
    }

    final updatedUser = result.getOrElse((_) => user);
    _cachedUser = updatedUser;

    _updateCards(
      updatedUser,
      _cachedProtocols,
      highlightProtocolId: protocolId,
    );

    final saveResult = await _saveUserWithRetry(updatedUser);
    if (saveResult.isLeft()) {
      final failure = saveResult.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to save protocol changes',
            ),
          );
      _notifyService.setToastEvent(ToastEventError(message: failure.message));
      await _loadLibrary(showLoading: false);
      return;
    }

    await _cachedUserStore?.saveUser(updatedUser);
    _clearBadgeAnimation(protocolId);
  }

  Future<void> removeProtocol(String protocolId) async {
    if (state.value.isOffline) {
      _notifyOffline();
      return;
    }

    final user = _cachedUser ?? state.value.user;
    if (user == null) {
      return;
    }

    final result = user.deactivateProtocol(protocolId);
    if (result.isLeft()) {
      final failure = result.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to remove protocol',
            ),
          );
      _notifyService.setToastEvent(ToastEventWarning(message: failure.message));
      return;
    }

    final updatedUser = result.getOrElse((_) => user);
    _cachedUser = updatedUser;
    _updateCards(updatedUser, _cachedProtocols);

    final saveResult = await _saveUserWithRetry(updatedUser);
    if (saveResult.isLeft()) {
      final failure = saveResult.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to save protocol changes',
            ),
          );
      _notifyService.setToastEvent(ToastEventError(message: failure.message));
      await _loadLibrary(showLoading: false);
      return;
    }

    await _cachedUserStore?.saveUser(updatedUser);
  }

  Future<LibraryProtocolStats> loadStats(String protocolId) async {
    final result = await _sessionRepository.list(protocolId: protocolId);
    if (result.isLeft()) {
      final failure = result.getLeft().getOrElse(
            () => const DomainFailure(
              code: 'Library.UnexpectedError',
              message: 'Unable to load session stats',
            ),
          );
      _notifyService.setToastEvent(ToastEventError(message: failure.message));
      return const LibraryProtocolStats(
        totalSessions: 0,
        currentStreakDays: 0,
      );
    }

    final sessions = result.getOrElse((_) => const <Session>[]);
    if (sessions.isEmpty) {
      return const LibraryProtocolStats(
        totalSessions: 0,
        currentStreakDays: 0,
      );
    }

    return buildLibraryProtocolStats(sessions);
  }

  void dispose() {
    _isDisposed = true;
    disposeConnectivityListener();
    disposeEntitlementListener();
    state.dispose();
  }

  // --- Private helpers ---

  Future<void> _loadLibrary({
    required bool showLoading,
    bool preferCacheWhenOffline = true,
  }) async {
    if (_isLoading || _isDisposed) {
      return;
    }

    _isLoading = true;
    final current = state.value;
    final isOffline =
        _connectivityService.status.value == NetworkStatus.offline;

    state.value = current.copyWith(
      status: showLoading ? LibraryStatus.loading : current.status,
      isRefreshing: !showLoading,
      isOffline: isOffline,
      errorMessage: null,
    );

    if (isOffline && preferCacheWhenOffline) {
      final cachedUser = await auth.resolveCachedUser(
        authService: _authService,
        cachedUser: _cachedUser,
        cachedUserStore: _cachedUserStore,
      );
      if (cachedUser != null) {
        final shouldUseMemoryCache = _cachedProtocols.isNotEmpty &&
            _cachedProtocolsUserId == cachedUser.id;
        final cachedProtocols = shouldUseMemoryCache
            ? _cachedProtocols
            : await _cachedProtocolStore?.loadProtocols(cachedUser.id) ??
                const [];
        _cachedUser = cachedUser;
        _cachedProtocols = cachedProtocols;
        _cachedProtocolsUserId = cachedUser.id;
        _updateCards(cachedUser, cachedProtocols);
        _isLoading = false;
        return;
      }
    }

    final userId = auth.resolveUserId(_authService);
    if (userId == null) {
      _setError('Unable to load user.', preserveContent: !showLoading);
      return;
    }

    final userResult = await _userRepository.getById(userId);
    if (userResult.isLeft()) {
      _setError(
        helpers.failureMessage(userResult, 'Unable to load library data'),
        preserveContent: !showLoading,
      );
      return;
    }

    final user = userResult.getOrElse((_) => throw StateError('Unreachable'));
    final protocolsResult = await _protocolRepository.list(activeOnly: true);
    if (protocolsResult.isLeft()) {
      _setError(
        helpers.failureMessage(protocolsResult, 'Unable to load library data'),
        preserveContent: !showLoading,
      );
      return;
    }

    final protocols =
        protocolsResult.getOrElse((_) => throw StateError('Unreachable'));
    _cachedUser = user;
    _cachedProtocols = protocols;
    _cachedProtocolsUserId = user.id;
    await _cachedUserStore?.saveUser(user);
    await _cachedProtocolStore?.saveProtocols(user.id, protocols);

    _updateCards(user, protocols);
    _isLoading = false;
  }

  void _updateCards(
    User user,
    List<Protocol> protocols, {
    String? highlightProtocolId,
  }) {
    final isOffline = state.value.isOffline;
    final snapshot = _revenueCatService.entitlementSnapshot.value;
    final cards = _buildCards(
      user,
      protocols,
      snapshot: snapshot,
      isOffline: isOffline,
      highlightProtocolId: highlightProtocolId,
    );

    final status = cards.isEmpty ? LibraryStatus.empty : LibraryStatus.loaded;
    final sections = _buildSections(cards);
    final protocolsById = {
      for (final protocol in protocols) protocol.id: protocol,
    };

    state.value = state.value.copyWith(
      status: status,
      user: user,
      cards: cards,
      sections: sections,
      protocolsById: protocolsById,
      isRefreshing: false,
      errorMessage: null,
    );
  }

  /// Builds library protocol cards from the given data.
  ///
  /// Pure function: receives the entitlement [snapshot] as a parameter
  /// instead of reading it from the service, making it easier to test.
  List<LibraryProtocolCardModel> _buildCards(
    User user,
    List<Protocol> protocols, {
    required EntitlementSnapshot? snapshot,
    required bool isOffline,
    String? highlightProtocolId,
  }) {
    final effectiveStatus = _resolver.resolveEffectiveStatus(
      user: user,
      snapshot: snapshot,
    );
    final sorted = List<Protocol>.from(protocols)
      ..sort((a, b) {
        final categoryCompare =
            a.category.index.compareTo(b.category.index);
        if (categoryCompare != 0) {
          return categoryCompare;
        }

        final statusCompare = _statusRank(
              _deriveCardStatus(user, a.id, effectiveStatus),
            ).compareTo(
              _statusRank(
                _deriveCardStatus(user, b.id, effectiveStatus),
              ),
            );
        if (statusCompare != 0) {
          return statusCompare;
        }

        return a.name.value.compareTo(b.name.value);
      });

    return sorted.map((protocol) {
      final status = _deriveCardStatus(user, protocol.id, effectiveStatus);
      final disableBadge =
          isOffline && status == LibraryCardStatus.available;

      return LibraryProtocolCardModel(
        protocolId: protocol.id,
        name: protocol.name.value,
        category: protocol.category,
        evidenceLevel: protocol.evidenceLevel,
        status: status,
        isOfflineDisabled: disableBadge,
        animateBadge: protocol.id == highlightProtocolId,
      );
    }).toList();
  }

  List<LibrarySectionModel> _buildSections(
    List<LibraryProtocolCardModel> cards,
  ) {
    if (cards.isEmpty) {
      return const [];
    }

    final sections = <LibrarySectionModel>[];
    protocol.Category? current;
    var bucket = <LibraryProtocolCardModel>[];

    for (final card in cards) {
      if (current != card.category) {
        if (current != null) {
          sections.add(
            LibrarySectionModel(
              category: current,
              cards: List<LibraryProtocolCardModel>.unmodifiable(bucket),
            ),
          );
        }
        current = card.category;
        bucket = <LibraryProtocolCardModel>[];
      }
      bucket.add(card);
    }

    if (current != null) {
      sections.add(
        LibrarySectionModel(
          category: current,
          cards: List<LibraryProtocolCardModel>.unmodifiable(bucket),
        ),
      );
    }

    return sections;
  }

  LibraryCardStatus _deriveCardStatus(
    User user,
    String protocolId,
    SubscriptionStatus effectiveStatus,
  ) {
    if (user.activeProtocolIds.contains(protocolId)) {
      return LibraryCardStatus.inStack;
    }

    final limit = effectiveStatus.protocolLimit;
    if (limit != null && user.activeProtocolCount >= limit) {
      return LibraryCardStatus.locked;
    }

    return LibraryCardStatus.available;
  }

  int _statusRank(LibraryCardStatus status) {
    return switch (status) {
      LibraryCardStatus.inStack => 0,
      LibraryCardStatus.available => 1,
      LibraryCardStatus.locked => 2,
    };
  }

  Future<Either<DomainFailure, Unit>> _saveUserWithRetry(User user) async {
    final result = await _userRepository.save(user);
    if (result.isRight()) {
      return result;
    }
    return _userRepository.save(user);
  }

  void _clearBadgeAnimation(String protocolId) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isDisposed) {
        return;
      }

      final current = state.value;
      final user = current.user;
      if (user == null) {
        return;
      }

      _updateCards(user, _cachedProtocols);
    });
  }


  void _setError(String message, {required bool preserveContent}) {
    final current = state.value;
    if (preserveContent && current.cards.isNotEmpty) {
      _notifyService.setToastEvent(ToastEventError(message: message));
      state.value = current.copyWith(
        isRefreshing: false,
        errorMessage: message,
      );
      _isLoading = false;
      return;
    }

    state.value = current.copyWith(
      status: LibraryStatus.error,
      errorMessage: message,
      isRefreshing: false,
    );
    _isLoading = false;
  }

  void _notifyOffline() {
    _notifyService.setToastEvent(
      ToastEventInfo(message: 'Offline mode'),
    );
  }
}
