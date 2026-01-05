import 'package:flutter/foundation.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';

class MockAuthStates {
  static AuthState unauthenticated() => const Unauthenticated();

  static AuthState authenticated(User user) => AuthenticatedOnline(user);

  static AuthState authenticationInProgress() => const Authenticating();
}

class TestAuthStateNotifier extends ValueNotifier<AuthState> {
  TestAuthStateNotifier([AuthState initial = const Unauthenticated()])
      : super(initial);

  void setAuthenticated(User user) => value = AuthenticatedOnline(user);
  void setUnauthenticated() => value = const Unauthenticated();
  void setLoading() => value = const Authenticating();
}
