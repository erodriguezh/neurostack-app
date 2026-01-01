import '../../user/domain/entities/user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticating extends AuthState {
  const Authenticating();
}

class AuthenticatedOnline extends AuthState {
  const AuthenticatedOnline(this.user);

  final User user;
}

class AuthenticatedOffline extends AuthState {
  const AuthenticatedOffline(this.user);

  final User user;
}

class OfflineNoUser extends AuthState {
  const OfflineNoUser();
}
