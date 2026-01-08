import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dtos/protocol_dto.dart';
import '../domain/entities/protocol.dart';

class CachedProtocolStore {
  CachedProtocolStore(this._prefs);

  final SharedPreferences _prefs;
  final Logger _logger = Logger('ProtocolCache');

  static const _cacheKeyPrefix = 'cached_protocols_';

  Future<void> saveProtocols(String userId, List<Protocol> protocols) async {
    final payload = protocols
        .map((protocol) => ProtocolDto.fromDomain(protocol).toJson())
        .toList();
    await _prefs.setString(_cacheKey(userId), jsonEncode(payload));
  }

  Future<List<Protocol>> loadProtocols(String userId) async {
    final raw = _prefs.getString(_cacheKey(userId));
    if (raw == null) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Cached protocols is not a JSON array');
      }

      final protocols = <Protocol>[];
      for (final entry in decoded) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Cached protocol item is not a JSON map');
        }
        final dto = ProtocolDto.fromJson(entry);
        final result = dto.toDomain();
        if (result.isLeft()) {
          throw const FormatException('Cached protocol failed to parse');
        }
        protocols.add(result.getOrElse((_) => throw StateError('Unreachable')));
      }

      return protocols;
    } catch (e) {
      _logger.warning('Cached protocol data invalid, clearing cache: $e');
      await clearProtocols(userId);
      return const [];
    }
  }

  Future<void> clearProtocols(String userId) async {
    await _prefs.remove(_cacheKey(userId));
  }

  String _cacheKey(String userId) => '$_cacheKeyPrefix$userId';
}
