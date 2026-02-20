import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeekProgressCache {
  const WeekProgressCache({
    required this.weekRange,
    required this.protocolNamesById,
    required this.completedDaysByProtocolId,
  });

  final DateTimeRange weekRange;
  final Map<String, String> protocolNamesById;
  final Map<String, Set<DateTime>> completedDaysByProtocolId;

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekRange.start.toIso8601String(),
      'weekEnd': weekRange.end.toIso8601String(),
      'protocols': protocolNamesById.entries
          .map(
            (entry) => {
              'id': entry.key,
              'name': entry.value,
            },
          )
          .toList(),
      'completedByProtocol': completedDaysByProtocolId.map(
        (key, value) => MapEntry(
          key,
          value.map(_dateKey).toList(),
        ),
      ),
    };
  }

  static WeekProgressCache? fromJson(Map<String, dynamic> json) {
    final weekStartRaw = json['weekStart'];
    final weekEndRaw = json['weekEnd'];
    final protocolsRaw = json['protocols'];
    final completedRaw = json['completedByProtocol'];

    if (weekStartRaw is! String || weekEndRaw is! String) {
      return null;
    }

    if (protocolsRaw is! List) {
      return null;
    }

    final protocolNamesById = <String, String>{};
    for (final entry in protocolsRaw) {
      if (entry is! Map<String, dynamic>) {
        return null;
      }
      final id = entry['id'];
      final name = entry['name'];
      if (id is! String || name is! String) {
        return null;
      }
      protocolNamesById[id] = name;
    }

    if (completedRaw is! Map<String, dynamic>) {
      return null;
    }

    final completedDaysByProtocolId = <String, Set<DateTime>>{};
    for (final entry in completedRaw.entries) {
      final protocolId = entry.key;
      final rawDays = entry.value;
      if (rawDays is! List) {
        return null;
      }
      final days = <DateTime>{};
      for (final rawDay in rawDays) {
        if (rawDay is! String) {
          return null;
        }
        days.add(DateTime.parse(rawDay));
      }
      completedDaysByProtocolId[protocolId] = days;
    }

    return WeekProgressCache(
      weekRange: DateTimeRange(
        start: DateTime.parse(weekStartRaw),
        end: DateTime.parse(weekEndRaw),
      ),
      protocolNamesById: protocolNamesById,
      completedDaysByProtocolId: completedDaysByProtocolId,
    );
  }

  static String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class CachedWeekProgressStore {
  CachedWeekProgressStore(this._prefs);

  final SharedPreferences _prefs;
  final Logger _logger = Logger('WeekProgressCache');

  static const _cacheKeyPrefix = 'cached_week_progress_';

  Future<void> saveWeek(
    String userId,
    DateTime weekStart,
    WeekProgressCache cache,
  ) async {
    await _prefs.setString(
      _cacheKey(userId, weekStart),
      jsonEncode(cache.toJson()),
    );
  }

  Future<WeekProgressCache?> loadWeek(
    String userId,
    DateTime weekStart,
  ) async {
    final raw = _prefs.getString(_cacheKey(userId, weekStart));
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cached week progress is not a JSON map');
      }
      final cache = WeekProgressCache.fromJson(decoded);
      if (cache == null) {
        throw const FormatException('Cached week progress failed to parse');
      }
      return cache;
    } catch (e) {
      _logger.warning('Cached week progress invalid, clearing cache: $e');
      await clearWeek(userId, weekStart);
      return null;
    }
  }

  Future<void> clearWeek(String userId, DateTime weekStart) async {
    await _prefs.remove(_cacheKey(userId, weekStart));
  }

  String _cacheKey(String userId, DateTime weekStart) {
    return '$_cacheKeyPrefix${userId}_${WeekProgressCache._dateKey(weekStart)}';
  }
}
