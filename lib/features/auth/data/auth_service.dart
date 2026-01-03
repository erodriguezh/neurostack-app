import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/failures/domain_failure.dart';
import '../../../core/utils/app_environment.dart';
import '../../../core/utils/app_lifecycle_service.dart';
import '../../../core/utils/connectivity/connectivity_service.dart';
import '../../../core/utils/data_source/data_source_abstraction.dart';
import '../../../core/utils/navigation/navigation_intent_store.dart';
import '../../../core/utils/navigation/route_data.dart';
import '../../../core/utils/navigation/router_service.dart';
import '../../user/domain/entities/user.dart';
import '../domain/auth_state.dart';
import 'cached_user_store.dart';
import 'user_bootstrap_service.dart';

class AuthService {
  AuthService({
    required DataSourceAbstraction dataSource,
    required UserBootstrapService userBootstrapService,
    required NavigationIntentStore navigationIntentStore,
    required CachedUserStore cachedUserStore,
    required RouterService routerService,
    required ConnectivityService connectivityService,
    required AppLifecycleService appLifecycleService,
  }) : _dataSource = dataSource,
       _userBootstrapService = userBootstrapService,
       _navigationIntentStore = navigationIntentStore,
       _cachedUserStore = cachedUserStore,
       _routerService = routerService,
       _connectivityService = connectivityService,
       _appLifecycleService = appLifecycleService;

  final DataSourceAbstraction _dataSource;
  final UserBootstrapService _userBootstrapService;
  final NavigationIntentStore _navigationIntentStore;
  final CachedUserStore _cachedUserStore;
  final RouterService _routerService;
  final ConnectivityService _connectivityService;
  final AppLifecycleService _appLifecycleService;
  final Logger _logger = Logger('Auth');

  final ValueNotifier<AuthState> authState = ValueNotifier<AuthState>(
    const AuthUnknown(),
  );

  StreamSubscription<supabase.AuthState>? _authSubscription;
  VoidCallback? _connectivityListener;
  User? _currentUser;

  bool get isAuthenticated =>
      authState.value is AuthenticatedOnline ||
      authState.value is AuthenticatedOffline;

  Future<void> init() async {
    authState.value = const AuthUnknown();

    await _connectivityService.init();
    _connectivityListener ??= _handleConnectivityChange;
    _connectivityService.status.removeListener(_connectivityListener!);
    _connectivityService.status.addListener(_connectivityListener!);

    _authSubscription?.cancel();
    _authSubscription = _dataSource.auth.onAuthStateChange.listen(
      (data) async {
        await _handleAuthChange(data.event, data.session);
      },
    );

    await _bootstrapFromCurrentSession();
  }

  /// Signs the user out and restarts the app.
  ///
  /// When [forceOnboarding] is true (default), the user will see the
  /// onboarding flow again after re-authenticating.
  Future<void> logout({bool forceOnboarding = true}) async {
    await _dataSource.auth.signOut(scope: supabase.SignOutScope.local);
    await _cachedUserStore.clearUser();
    await _navigationIntentStore.clearIntendedRoute();
    await _navigationIntentStore.clearAuthEmail();
    if (forceOnboarding) {
      await _navigationIntentStore.setForceOnboarding();
    }
    _currentUser = null;
    authState.value = const Unauthenticated();
    await _appLifecycleService.restartApp();
  }

  Future<void> invalidateUserCache() async {
    _userBootstrapService.invalidatePresenceCache();
    await _cachedUserStore.clearUser();
  }

  void dispose() {
    _authSubscription?.cancel();
    if (_connectivityListener != null) {
      _connectivityService.status.removeListener(_connectivityListener!);
    }
    authState.dispose();
  }

  Future<void> _bootstrapFromCurrentSession() async {
    final session = _dataSource.auth.currentSession;
    final isOnline = _connectivityService.status.value == NetworkStatus.online;

    if (session == null) {
      await _handleNoSession(isOnline: isOnline);
      return;
    }

    await _rehydrateFromSession(
      session,
      isOnline: isOnline,
      shouldNavigate: true,
    );
  }

  Future<void> _handleAuthChange(
    supabase.AuthChangeEvent event,
    supabase.Session? session,
  ) async {
    switch (event) {
      case supabase.AuthChangeEvent.signedIn:
        if (session != null) {
          await _rehydrateFromSession(
            session,
            isOnline: _connectivityService.status.value == NetworkStatus.online,
            shouldNavigate: true,
          );
        }
        break;
      case supabase.AuthChangeEvent.tokenRefreshed:
      case supabase.AuthChangeEvent.userUpdated:
        if (session != null) {
          await _rehydrateFromSession(
            session,
            isOnline: _connectivityService.status.value == NetworkStatus.online,
            shouldNavigate: false,
          );
        }
        break;
      case supabase.AuthChangeEvent.signedOut:
        _currentUser = null;
        await _cachedUserStore.clearUser();
        authState.value = const Unauthenticated();
        _routerService.replaceAll([Path(name: '/auth')]);
        break;
      case supabase.AuthChangeEvent.initialSession:
      case supabase.AuthChangeEvent.passwordRecovery:
      case supabase.AuthChangeEvent.mfaChallengeVerified:
        break;
      default:
        break;
    }
  }

  Future<void> _handleNoSession({required bool isOnline}) async {
    if (!isOnline) {
      final cachedUser = await _cachedUserStore.loadUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        authState.value = AuthenticatedOffline(cachedUser);
        return;
      }
      authState.value = const OfflineNoUser();
      return;
    }

    authState.value = const Unauthenticated();
  }

  Future<void> _rehydrateFromSession(
    supabase.Session session, {
    required bool isOnline,
    required bool shouldNavigate,
  }) async {
    if (!isOnline) {
      final cachedUser = await _cachedUserStore.loadUser();
      if (cachedUser != null) {
        _currentUser = cachedUser;
        authState.value = AuthenticatedOffline(cachedUser);
        return;
      }
      authState.value = const OfflineNoUser();
      return;
    }

    authState.value = const Authenticating();

    final authCreatedAt = _parseAuthCreatedAt(session.user.createdAt);
    final result = await _userBootstrapService.rehydrateFromRemote(
      userId: session.user.id,
      authCreatedAt: authCreatedAt,
    );

    if (result.isLeft()) {
      authState.value = const Unauthenticated();
      final failure = result.getLeft().getOrElse(
        () => const DomainFailure(
          code: 'User.UnexpectedError',
          message: 'Unknown error',
        ),
      );
      _logger.warning(
        'Auth rehydrate failed (env=${AppEnvironment.tag}, userId=${session.user.id}, code=${failure.code}, message=${failure.message})',
      );
      return;
    }

    final data = result.getOrElse((_) => throw StateError('Unreachable'));
    _currentUser = data.user;
    authState.value = AuthenticatedOnline(data.user);
    await _cachedUserStore.saveUser(data.user);

    _logger.info(
      'Auth success (env=${AppEnvironment.tag}, userId=${data.user.id})',
    );

    if (!data.didRecoverUpsert &&
        _isRecentlyCreated(authCreatedAt, const Duration(minutes: 5))) {
      _logger.info(
        'User record created (trigger, env=${AppEnvironment.tag}, userId=${data.user.id})',
      );
    }

    if (data.didRecoverUpsert) {
      _logger.info(
        'User record created (recovery upsert, env=${AppEnvironment.tag}, userId=${data.user.id})',
      );
    }

    if (shouldNavigate) {
      await _handlePostAuthNavigation();
    }
  }

  Future<void> _handlePostAuthNavigation() async {
    // Check force onboarding flag (set after logout) or onboarding guard
    final forceOnboarding = _navigationIntentStore.shouldForceOnboarding();
    if (forceOnboarding) {
      await _navigationIntentStore.clearForceOnboarding();
      _routerService.replaceAll([Path(name: '/onboarding')]);
      return;
    }

    if (_routerService.shouldShowOnboarding()) {
      _routerService.replaceAll([Path(name: '/onboarding')]);
      return;
    }

    final intendedRoute = _navigationIntentStore.getIntendedRoute();
    if (intendedRoute != null && intendedRoute.isNotEmpty) {
      _routerService.replaceAll([Path(name: intendedRoute)]);
    } else {
      _routerService.replaceAll([Path(name: '/')]);
    }
    await _navigationIntentStore.clearIntendedRoute();
    await _navigationIntentStore.clearAuthEmail();
  }

  void _handleConnectivityChange() {
    final status = _connectivityService.status.value;
    if (status == NetworkStatus.offline) {
      if (_currentUser != null) {
        authState.value = AuthenticatedOffline(_currentUser!);
      } else {
        authState.value = const OfflineNoUser();
      }
      return;
    }

    if (_currentUser != null) {
      final session = _dataSource.auth.currentSession;
      if (session != null) {
        unawaited(
          _rehydrateFromSession(
            session,
            isOnline: true,
            shouldNavigate: false,
          ),
        );
        return;
      }
      _currentUser = null;
    }

    final session = _dataSource.auth.currentSession;
    if (session != null) {
      unawaited(
        _rehydrateFromSession(
          session,
          isOnline: true,
          shouldNavigate: false,
        ),
      );
      return;
    }

    authState.value = const Unauthenticated();
    _routerService.replaceAll([Path(name: '/auth')]);
  }

  DateTime? _parseAuthCreatedAt(String? raw) {
    if (raw == null) {
      return null;
    }
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  bool _isRecentlyCreated(DateTime? createdAt, Duration threshold) {
    if (createdAt == null) {
      return false;
    }
    final now = DateTime.now();
    final delta = now.difference(createdAt);
    return delta.inSeconds >= 0 && delta <= threshold;
  }
}
