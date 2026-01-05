import 'package:shared_preferences/shared_preferences.dart';

class NavigationIntentStore {
  NavigationIntentStore(this._prefs);

  final SharedPreferences _prefs;

  static const _intendedRouteKey = 'intended_route';
  static const _authEmailKey = 'auth_email';
  static const _forceOnboardingKey = 'force_onboarding';
  static const Set<String> _blockedIntendedRoutes = {
    '/auth',
    '/auth/callback',
    '/auth/check-email',
    '/onboarding',
    '/offline',
    '/404',
  };

  Future<void> saveIntendedRoute(String route) async {
    await _prefs.setString(_intendedRouteKey, route);
  }

  String? getIntendedRoute() => _prefs.getString(_intendedRouteKey);

  bool isEligibleIntendedRoute(String path) {
    final normalizedPath = Uri.parse(path).path;
    return !_blockedIntendedRoutes.contains(normalizedPath);
  }

  Future<void> saveIntendedRouteIfEligible(
    String route, {
    bool overwrite = true,
  }) async {
    if (!isEligibleIntendedRoute(route)) {
      return;
    }
    if (!overwrite && hasIntendedRoute()) {
      return;
    }
    await _prefs.setString(_intendedRouteKey, route);
  }

  bool hasIntendedRoute() {
    final route = getIntendedRoute();
    return route != null && route.isNotEmpty;
  }

  Future<String?> consumeIntendedRoute() async {
    final route = getIntendedRoute();
    if (route == null || route.isEmpty) {
      return null;
    }
    await clearIntendedRoute();
    return route;
  }

  Future<void> clearIntendedRoute() async {
    await _prefs.remove(_intendedRouteKey);
  }

  Future<void> saveAuthEmail(String email) async {
    await _prefs.setString(_authEmailKey, email);
  }

  String? getAuthEmail() => _prefs.getString(_authEmailKey);

  Future<void> clearAuthEmail() async {
    await _prefs.remove(_authEmailKey);
  }

  Future<void> setForceOnboarding() async {
    await _prefs.setBool(_forceOnboardingKey, true);
  }

  bool shouldForceOnboarding() {
    return _prefs.getBool(_forceOnboardingKey) ?? false;
  }

  Future<void> clearForceOnboarding() async {
    await _prefs.remove(_forceOnboardingKey);
  }
}
