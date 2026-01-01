import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../user/data/dtos/user_dto.dart';
import '../../user/domain/entities/user.dart';

class CachedUserStore {
  CachedUserStore(this._prefs);

  final SharedPreferences _prefs;
  final Logger _logger = Logger('UserCache');

  static const _cacheKey = 'cached_user';

  Future<void> saveUser(User user) async {
    final dto = UserDto.fromDomain(user);
    await _prefs.setString(_cacheKey, jsonEncode(dto.toJson()));
  }

  Future<User?> loadUser() async {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cached user data is not a JSON object');
      }
      final dto = UserDto.fromJson(decoded);
      final result = dto.toDomain();
      if (result.isLeft()) {
        _logger.warning(
          'Cached user data failed to parse, clearing cache.',
        );
        await clearUser();
        return null;
      }
      return result.getOrElse((_) => throw StateError('Unreachable'));
    } catch (e) {
      _logger.warning('Cached user data invalid, clearing cache: $e');
      await clearUser();
      return null;
    }
  }

  Future<void> clearUser() async {
    await _prefs.remove(_cacheKey);
  }
}
