import 'package:shared_preferences/shared_preferences.dart';

class NavigationIntentStore {
  NavigationIntentStore(this._prefs);

  final SharedPreferences _prefs;

  static const _intendedRouteKey = 'intended_route';
  static const _authEmailKey = 'auth_email';

  Future<void> saveIntendedRoute(String route) async {
    await _prefs.setString(_intendedRouteKey, route);
  }

  String? getIntendedRoute() => _prefs.getString(_intendedRouteKey);

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
}
