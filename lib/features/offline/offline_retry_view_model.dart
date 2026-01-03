import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';

/// ViewModel for the offline retry screen.
///
/// Allows users to retry auth initialization when offline without a cached user.
class OfflineRetryViewModel {
  OfflineRetryViewModel({
    required AuthService authService,
    required RouterService routerService,
    required NavigationIntentStore navigationIntentStore,
  }) : _authService = authService,
       _routerService = routerService,
       _navigationIntentStore = navigationIntentStore;

  final AuthService _authService;
  final RouterService _routerService;
  final NavigationIntentStore _navigationIntentStore;
  final ValueNotifier<bool> isRetrying = ValueNotifier(false);

  Future<void> retry() async {
    if (isRetrying.value) return;
    isRetrying.value = true;

    try {
      await _authService.init();

      final state = _authService.authState.value;
      switch (state) {
        case AuthenticatedOnline():
          // AuthService._handlePostAuthNavigation() handles this
          // Do NOT route - auth service already triggered navigation
          break;
        case AuthenticatedOffline():
          // Clear stale intended routes when manually routing to home
          await _navigationIntentStore.clearIntendedRoute();
          _routerService.replaceAll([Path(name: '/')]);
        case Unauthenticated():
          // Keep intended route - will be replayed after auth completes
          _routerService.replaceAll([Path(name: '/auth')]);
        case OfflineNoUser():
          // Still offline - stay on screen
          break;
        case AuthUnknown():
        case Authenticating():
          // Auth state not settled - stay on screen
          break;
      }
    } catch (e) {
      // Auth init failed - stay on screen for retry
      // No logging here per codebase pattern (failures returned via Either)
    } finally {
      isRetrying.value = false;
    }
  }

  void dispose() => isRetrying.dispose();
}
