import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';

/// Resolves the current authenticated user's ID from [AuthService.authState].
///
/// Returns the user ID for either [AuthenticatedOnline] or
/// [AuthenticatedOffline] states. Returns `null` for all other auth states.
String? resolveUserId(AuthService authService) {
  final authState = authService.authState.value;
  if (authState is AuthenticatedOnline) {
    return authState.user.id;
  }
  if (authState is AuthenticatedOffline) {
    return authState.user.id;
  }
  return null;
}

/// Resolves a cached [User] for offline scenarios.
///
/// Checks, in order:
/// 1. The in-memory [cachedUser] if it matches the current auth user ID
/// 2. The user embedded in [AuthenticatedOffline] or [AuthenticatedOnline]
/// 3. The [CachedUserStore] persistent cache
///
/// Returns `null` if no valid cached user is available.
Future<User?> resolveCachedUser({
  required AuthService authService,
  required User? cachedUser,
  CachedUserStore? cachedUserStore,
}) async {
  final currentUserId = resolveUserId(authService);
  if (cachedUser != null &&
      (currentUserId == null || cachedUser.id == currentUserId)) {
    return cachedUser;
  }

  final authState = authService.authState.value;
  if (authState is AuthenticatedOffline) {
    return authState.user;
  }
  if (authState is AuthenticatedOnline) {
    return authState.user;
  }

  final stored = await cachedUserStore?.loadUser();
  if (stored == null) {
    return null;
  }
  if (currentUserId != null && stored.id != currentUserId) {
    return null;
  }
  return stored;
}
