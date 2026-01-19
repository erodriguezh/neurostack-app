import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/pending_session.dart';
import '../../domain/entities/session.dart';
import '../dtos/pending_session_dto.dart';
import '../dtos/session_dto.dart';

/// Local persistence for sessions, supporting offline-first architecture.
///
/// Manages two caches per user:
/// - **Pending sessions**: Locally created sessions awaiting remote sync
/// - **Synced sessions**: Sessions successfully persisted to remote (cached locally)
///
/// Pattern: Follows [CachedUserStore] and [CachedWeekProgressStore].
class SessionLocalDataSource {
  SessionLocalDataSource(this._prefs);

  final SharedPreferences _prefs;
  final Logger _logger = Logger('SessionLocalDataSource');

  static const _pendingKeyPrefix = 'pending_sessions_';
  static const _syncedKeyPrefix = 'synced_sessions_';

  // ---------------------------------------------------------------------------
  // Pending Sessions
  // ---------------------------------------------------------------------------

  /// Saves a pending session to the local queue.
  ///
  /// Appends to existing pending sessions for the user. If a session with
  /// the same [PendingSession.localId] already exists, it is replaced.
  Future<void> savePendingSession(PendingSession pending) async {
    final key = _pendingKey(pending.userId);
    final existing = await _loadPendingDtos(pending.userId);

    // Remove existing with same localId (for upsert behavior)
    existing.removeWhere((dto) => dto.localId == pending.localId);

    // Add new
    existing.add(PendingSessionDto.fromDomain(pending));

    await _prefs.setString(
      key,
      jsonEncode(existing.map((dto) => dto.toJson()).toList()),
    );
  }

  /// Returns all pending sessions for the given user.
  ///
  /// If the cache is corrupt, it is cleared and an empty list is returned.
  /// Self-heals: corrupt entries are removed from storage on read.
  Future<List<PendingSession>> getPendingSessions(String userId) async {
    final dtos = await _loadPendingDtos(userId);
    final results = <PendingSession>[];
    final validDtos = <PendingSessionDto>[];
    var hasCorruptEntries = false;

    for (final dto in dtos) {
      try {
        results.add(dto.toDomain());
        validDtos.add(dto);
      } catch (e) {
        _logger.warning('Skipping corrupt pending session: $e');
        hasCorruptEntries = true;
      }
    }

    // Self-heal: rewrite cache without corrupt entries
    if (hasCorruptEntries) {
      _logger.info('Self-healing pending sessions cache for user $userId');
      if (validDtos.isEmpty) {
        await clearPendingSessions(userId);
      } else {
        await _prefs.setString(
          _pendingKey(userId),
          jsonEncode(validDtos.map((dto) => dto.toJson()).toList()),
        );
      }
    }

    return results;
  }

  /// Removes a pending session from the local queue.
  ///
  /// Called after successful sync to remote.
  Future<void> removePendingSession(String userId, String localId) async {
    final key = _pendingKey(userId);
    final existing = await _loadPendingDtos(userId);

    existing.removeWhere((dto) => dto.localId == localId);

    if (existing.isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(
        key,
        jsonEncode(existing.map((dto) => dto.toJson()).toList()),
      );
    }
  }

  /// Clears all pending sessions for the given user.
  Future<void> clearPendingSessions(String userId) async {
    await _prefs.remove(_pendingKey(userId));
  }

  // ---------------------------------------------------------------------------
  // Synced Sessions
  // ---------------------------------------------------------------------------

  /// Updates the synced sessions cache with remote data.
  ///
  /// This is an upsert: new sessions are added, existing sessions (by ID)
  /// are updated. Typically called after a successful remote fetch.
  Future<void> upsertSyncedSessions(String userId, List<Session> sessions) async {
    final key = _syncedKey(userId);
    final existing = await _loadSyncedDtos(userId);
    final existingById = {for (final dto in existing) dto.id: dto};

    // Upsert new sessions
    for (final session in sessions) {
      existingById[session.id] = SessionDto.fromDomain(session, userId);
    }

    await _prefs.setString(
      key,
      jsonEncode(existingById.values.map((dto) => dto.toJson()).toList()),
    );
  }

  /// Returns all synced sessions for the given user.
  ///
  /// If the cache is corrupt, it is cleared and an empty list is returned.
  /// Self-heals: corrupt entries are removed from storage on read.
  Future<List<Session>> getSyncedSessions(String userId) async {
    final dtos = await _loadSyncedDtos(userId);
    final results = <Session>[];
    final validDtos = <SessionDto>[];
    var hasCorruptEntries = false;

    for (final dto in dtos) {
      final result = dto.toDomain();
      result.fold(
        (failure) {
          _logger.warning('Skipping corrupt synced session: ${failure.message}');
          hasCorruptEntries = true;
        },
        (session) {
          results.add(session);
          validDtos.add(dto);
        },
      );
    }

    // Self-heal: rewrite cache without corrupt entries
    if (hasCorruptEntries) {
      _logger.info('Self-healing synced sessions cache for user $userId');
      if (validDtos.isEmpty) {
        await clearSyncedSessions(userId);
      } else {
        await _prefs.setString(
          _syncedKey(userId),
          jsonEncode(validDtos.map((dto) => dto.toJson()).toList()),
        );
      }
    }

    return results;
  }

  /// Clears all synced sessions for the given user.
  Future<void> clearSyncedSessions(String userId) async {
    await _prefs.remove(_syncedKey(userId));
  }

  // ---------------------------------------------------------------------------
  // Combined Sessions
  // ---------------------------------------------------------------------------

  /// Prefix for pending session IDs to distinguish from server-assigned UUIDs.
  ///
  /// Used in [listSessions] to avoid potential ID collisions between pending
  /// sessions (localId) and synced sessions (server UUID).
  static const pendingIdPrefix = 'pending:';

  /// Returns combined synced + pending sessions, optionally filtered by date.
  ///
  /// Pending sessions are converted to [Session] objects with IDs prefixed
  /// by [pendingIdPrefix] to distinguish them from server-assigned UUIDs.
  ///
  /// - [from]: If provided, only includes sessions completed on or after this date
  /// - [to]: If provided, only includes sessions completed on or before this date
  ///
  /// Sessions are sorted by [Session.completedAt] descending (most recent first).
  Future<List<Session>> listSessions(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final synced = await getSyncedSessions(userId);
    final pending = await getPendingSessions(userId);

    // Convert pending to Session for unified display
    // Prefix IDs to avoid collision with server UUIDs
    final pendingAsSessions = pending.map((p) {
      return Session.reconstitute(
        id: '$pendingIdPrefix${p.localId}',
        protocolId: p.draft.protocolId,
        completedAt: p.draft.completedAt,
        duration: p.draft.duration,
        notes: p.draft.notes,
      );
    }).toList();

    // Combine and filter
    final all = [...synced, ...pendingAsSessions];

    final filtered = all.where((session) {
      if (from != null && session.completedAt.isBefore(from)) {
        return false;
      }
      if (to != null && session.completedAt.isAfter(to)) {
        return false;
      }
      return true;
    }).toList();

    // Sort by completedAt descending
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return filtered;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  String _pendingKey(String userId) => '$_pendingKeyPrefix$userId';
  String _syncedKey(String userId) => '$_syncedKeyPrefix$userId';

  Future<List<PendingSessionDto>> _loadPendingDtos(String userId) async {
    final raw = _prefs.getString(_pendingKey(userId));
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Pending sessions is not a JSON list');
      }
      final results = <PendingSessionDto>[];
      var hasCorruptEntries = false;
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          hasCorruptEntries = true;
          continue;
        }
        try {
          results.add(PendingSessionDto.fromJson(item));
        } catch (e) {
          _logger.warning('Skipping corrupt pending session entry: $e');
          hasCorruptEntries = true;
        }
      }
      // Self-heal: rewrite cache without corrupt entries
      if (hasCorruptEntries) {
        _logger.info('Self-healing pending DTOs cache for user $userId');
        if (results.isEmpty) {
          await clearPendingSessions(userId);
        } else {
          await _prefs.setString(
            _pendingKey(userId),
            jsonEncode(results.map((dto) => dto.toJson()).toList()),
          );
        }
      }
      return results;
    } catch (e) {
      _logger.warning('Corrupt pending sessions cache, clearing: $e');
      await clearPendingSessions(userId);
      return [];
    }
  }

  Future<List<SessionDto>> _loadSyncedDtos(String userId) async {
    final raw = _prefs.getString(_syncedKey(userId));
    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Synced sessions is not a JSON list');
      }
      final results = <SessionDto>[];
      var hasCorruptEntries = false;
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          hasCorruptEntries = true;
          continue;
        }
        try {
          results.add(SessionDto.fromJson(item));
        } catch (e) {
          _logger.warning('Skipping corrupt synced session entry: $e');
          hasCorruptEntries = true;
        }
      }
      // Self-heal: rewrite cache without corrupt entries
      if (hasCorruptEntries) {
        _logger.info('Self-healing synced DTOs cache for user $userId');
        if (results.isEmpty) {
          await clearSyncedSessions(userId);
        } else {
          await _prefs.setString(
            _syncedKey(userId),
            jsonEncode(results.map((dto) => dto.toJson()).toList()),
          );
        }
      }
      return results;
    } catch (e) {
      _logger.warning('Corrupt synced sessions cache, clearing: $e');
      await clearSyncedSessions(userId);
      return [];
    }
  }
}
